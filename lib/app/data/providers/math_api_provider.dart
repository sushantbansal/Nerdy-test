import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/math_models.dart';
import '../models/math_api_models.dart';
import 'supabase_provider.dart';

class MathApiException implements Exception {
  const MathApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Thin client for the authoritative database RPCs.
///
/// No game rule is evaluated here. The provider validates input shape, calls
/// the server and maps transport errors to child-friendly messages.
class MathApiProvider {
  static const Duration _timeout = Duration(seconds: 20);

  Future<Map<String, dynamic>> _rpc(
    String function, [
    Map<String, dynamic> params = const {},
  ]) async {
    try {
      final response = await SupabaseProvider.client
          .rpc(function, params: params)
          .timeout(_timeout);
      if (response is Map<String, dynamic>) return response;
      if (response is Map) return Map<String, dynamic>.from(response);
      throw const MathApiException('The game server sent an unexpected reply.');
    } on MathApiException {
      rethrow;
    } on PostgrestException catch (error) {
      throw MathApiException(_friendly(error.message), code: error.code);
    } on AuthException catch (error) {
      throw MathApiException(error.message);
    } on TimeoutException {
      throw const MathApiException(
        'The game server is taking too long. Check your connection and try again.',
      );
    } catch (_) {
      throw const MathApiException(
        "We couldn't reach the game server. Check your connection and try again.",
      );
    }
  }

  Future<List<Map<String, dynamic>>> _rpcList(
    String function, [
    Map<String, dynamic> params = const {},
  ]) async {
    try {
      final response = await SupabaseProvider.client
          .rpc(function, params: params)
          .timeout(_timeout);
      if (response is List) {
        return response
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
      return const <Map<String, dynamic>>[];
    } on PostgrestException catch (error) {
      throw MathApiException(_friendly(error.message), code: error.code);
    } on AuthException catch (error) {
      throw MathApiException(error.message);
    } on TimeoutException {
      throw const MathApiException(
        'The game server is taking too long. Check your connection and try again.',
      );
    } catch (_) {
      throw const MathApiException(
        "We couldn't reach the game server. Check your connection and try again.",
      );
    }
  }

  String _friendly(String message) {
    if (message.contains('duplicate key')) {
      return 'That already happened. Please refresh and try again.';
    }
    if (message.contains('JWT') || message.contains('permission denied')) {
      return 'Your session has expired. Please sign in again.';
    }
    return message;
  }

  // ---------------------------------------------------------------------------
  // Rooms
  // ---------------------------------------------------------------------------

  Future<({String roomId, String roomCode})> createRoom({
    required String name,
    required RoomVisibility visibility,
    required GradeLevel grade,
    required List<MathTopic> topics,
    required MathDifficulty difficulty,
    int questionCount = AppConstants.defaultQuestionCount,
    int answerSeconds = AppConstants.defaultAnswerSeconds,
    int maxPlayers = AppConstants.defaultMaxPlayers,
    bool speedBonusEnabled = true,
    bool autoStart = false,
  }) async {
    final response = await _rpc('math_create_room', {
      'p_name': name,
      'p_visibility': visibility.dbValue,
      'p_grade': grade.value,
      'p_topics': topics.map((topic) => topic.dbValue).toList(),
      'p_difficulty': difficulty.dbValue,
      'p_question_count': questionCount,
      'p_answer_seconds': answerSeconds,
      'p_max_players': maxPlayers,
      'p_speed_bonus_enabled': speedBonusEnabled,
      'p_auto_start': autoStart,
    });
    final roomId = '${response['room_id'] ?? ''}';
    final roomCode = '${response['room_code'] ?? ''}';
    if (roomId.isEmpty || roomCode.isEmpty) {
      throw const MathApiException('The room could not be created.');
    }
    return (roomId: roomId, roomCode: roomCode);
  }

  Future<({String roomId, bool alreadyJoined, bool reconnected})> joinRoom(
    String code,
  ) async {
    final response = await _rpc('math_join_room', {
      'p_room_code': code.trim().toUpperCase(),
    });
    final roomId = '${response['room_id'] ?? ''}';
    if (roomId.isEmpty) {
      throw const MathApiException('That room code did not match a room.');
    }
    return (
      roomId: roomId,
      alreadyJoined: response['already_joined'] == true,
      reconnected: response['reconnected'] == true,
    );
  }

  Future<void> leaveRoom(String roomId) async {
    await _rpc('math_leave_room', {'p_room_id': roomId});
  }

  Future<void> setReady(String roomId, bool ready) async {
    await _rpc('math_set_ready', {'p_room_id': roomId, 'p_ready': ready});
  }

  Future<void> startMatch(String roomId) async {
    await _rpc('math_start_match', {'p_room_id': roomId});
  }

  Future<void> playAgain(String roomId) async {
    await _rpc('math_play_again', {'p_room_id': roomId});
  }

  Future<void> closeRoom(String roomId) async {
    await _rpc('math_close_room', {'p_room_id': roomId});
  }

  Future<void> heartbeat(String roomId) async {
    await _rpc('math_heartbeat', {'p_room_id': roomId});
  }

  Future<List<MathRoomSummary>> listRooms({
    GradeLevel? grade,
    MathTopic? topic,
    MathDifficulty? difficulty,
    bool onlyAvailable = false,
    int limit = 30,
  }) async {
    final rows = await _rpcList('math_list_rooms', {
      'p_grade': grade?.value,
      'p_topic': topic?.dbValue,
      'p_difficulty': difficulty?.dbValue,
      'p_only_available': onlyAvailable,
      'p_limit': limit,
    });
    return rows
        .map(MathRoomSummary.fromJson)
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Match
  // ---------------------------------------------------------------------------

  Future<MathRoomState> roomState(String roomId) async {
    final response = await _rpc('math_room_state', {'p_room_id': roomId});
    try {
      return MathRoomState.fromJson(response);
    } on FormatException {
      throw const MathApiException('The room state could not be read.');
    }
  }

  Future<void> advanceMatch(String roomId) async {
    await _rpc('math_advance_match', {'p_room_id': roomId});
  }

  Future<({bool success, String? error})> submitAnswer({
    required String roomId,
    required String questionId,
    required String answer,
  }) async {
    final response = await _rpc('math_submit_answer', {
      'p_room_id': roomId,
      'p_match_question_id': questionId,
      'p_answer': answer,
    });
    return (
      success: response['success'] == true,
      error: response['error'] == null ? null : '${response['error']}',
    );
  }

  // ---------------------------------------------------------------------------
  // Profiles and achievements
  // ---------------------------------------------------------------------------

  Future<MathProfile> profile([String? playerId]) async {
    final response = await _rpc('math_profile', {
      'p_player_id': ?playerId,
    });
    return MathProfile.fromJson(response);
  }

  Future<void> updateProfile({
    required String displayName,
    int? avatarIndex,
    String? avatarColor,
    GradeLevel? grade,
  }) async {
    await _rpc('math_update_profile', {
      'p_display_name': displayName,
      'p_avatar_index': avatarIndex,
      'p_avatar_color': avatarColor,
      'p_grade': grade?.value,
    });
  }

  Future<void> updateSettings({
    bool? soundEnabled,
    bool? reducedMotion,
    bool? leaderboardVisible,
  }) async {
    await _rpc('math_update_settings', {
      'p_sound_enabled': soundEnabled,
      'p_reduced_motion': reducedMotion,
      'p_leaderboard_visible': leaderboardVisible,
    });
  }

  Future<List<MathAchievement>> achievementCatalogue() async {
    // Returns a JSON array, so parse it through the list helper.
    final rows = await _rpcList('math_achievement_catalogue');
    return rows.map(MathAchievement.fromJson).toList(growable: false);
  }

  Future<bool> tutorialCompleted() async {
    final response = await _rpc('math_tutorial_status');
    return response['completed'] == true;
  }

  Future<void> completeTutorial() async {
    await _rpc('math_complete_tutorial');
  }

  Future<MathActiveRoom?> myActiveRoom() async {
    try {
      final response = await SupabaseProvider.client
          .rpc('math_my_active_room')
          .timeout(_timeout);
      if (response is Map<String, dynamic>) {
        return MathActiveRoom.fromJson(response);
      }
      if (response is Map) {
        return MathActiveRoom.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Practice
  // ---------------------------------------------------------------------------

  Future<MathPracticeQuestion> nextPracticeQuestion({
    required GradeLevel grade,
    MathTopic? topic,
  }) async {
    final response = await _rpc('math_next_practice_question', {
      'p_grade': grade.value,
      'p_topic': topic?.dbValue,
    });
    return MathPracticeQuestion.fromJson(response);
  }

  Future<MathPracticeResult> submitPracticeAnswer({
    required String questionId,
    required String answer,
    required String attemptId,
    bool usedHint = false,
    int elapsedMs = 0,
  }) async {
    final response = await _rpc('math_submit_practice_answer', {
      'p_question_id': questionId,
      'p_answer': answer,
      'p_attempt_id': attemptId,
      'p_used_hint': usedHint,
      'p_elapsed_ms': elapsedMs,
    });
    if (response['success'] != true) {
      throw MathApiException(
        response['error'] == 'already_submitted'
            ? 'You already answered that one. Here comes another!'
            : 'That answer could not be checked.',
      );
    }
    return MathPracticeResult.fromJson(response);
  }

  // ---------------------------------------------------------------------------
  // Leaderboards and account
  // ---------------------------------------------------------------------------

  Future<List<MathLeaderboardEntry>> leaderboard({
    GradeLevel? grade,
    MathTopic? topic,
    String window = 'all_time',
    int limit = 25,
  }) async {
    final rows = await _rpcList('math_leaderboard', {
      'p_grade': grade?.value,
      'p_topic': topic?.dbValue,
      'p_window': window,
      'p_limit': limit,
    });
    return rows.map(MathLeaderboardEntry.fromJson).toList(growable: false);
  }

  Future<void> deleteAccount() async {
    await _rpc('math_delete_my_account');
  }
}
