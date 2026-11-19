import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';

import '../../core/utils/feedback.dart';
import '../../core/utils/ui_feedback.dart';
import '../../core/widgets/answer_option_card.dart';
import '../../data/models/math_api_models.dart';
import '../../data/providers/math_api_provider.dart';
import '../../domain/models/math_models.dart';
import '../../routes/app_routes.dart';
import '../../services/narration_service.dart';
import '../../services/session_service.dart';

/// Drives the match screen from authoritative server snapshots.
///
/// The client never decides correctness, scores or phase changes. It ticks the
/// server (`math_advance_match`) on a short interval, reads the sanitised room
/// snapshot and renders it. Countdowns interpolate between snapshots using the
/// server-provided clock offset.
class MatchController extends GetxController {
  MatchController(this._api, this._session);

  final MathApiProvider _api;
  final SessionService _session;

  static const Duration _pollInterval = Duration(milliseconds: 750);
  static const Duration _heartbeatInterval = Duration(seconds: 12);

  final Rx<MathRoomState?> state = Rx<MathRoomState?>(null);
  final RxInt remainingMs = 0.obs;
  final RxInt totalMs = 1.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isBusy = false.obs;
  final RxString error = ''.obs;
  final RxString selectedAnswer = ''.obs;

  String roomId = '';

  Timer? _pollTimer;
  Timer? _ticker;
  Timer? _heartbeatTimer;
  bool _polling = false;
  bool _navigating = false;
  DateTime _receivedAt = DateTime.now();
  DateTime _serverAt = DateTime.now();
  String? _lastQuestionId;
  String? _revealAnnouncedFor;
  String? _finalAnnouncedFor;
  final Set<String> _announcedAchievements = <String>{};

  MathRoomState? get snapshot => state.value;
  MathRoom? get room => snapshot?.room;
  MathMatchInfo? get match => snapshot?.match;
  MathQuestionView? get question => snapshot?.question;
  MathReveal? get reveal => snapshot?.reveal;
  MathFinalResults? get results => snapshot?.finalResults;
  List<MathRoomPlayer> get players => snapshot?.players ?? const [];
  List<MathStanding> get leaderboard => snapshot?.leaderboard ?? const [];
  RoomPhase get phase => room?.status ?? RoomPhase.waiting;
  int get questionNumber => match?.questionIndex ?? 0;
  int get questionCount => match?.questionCount ?? room?.questionCount ?? 5;
  bool get isHost => room?.isHost ?? false;

  bool get isKindergarten => _session.isKindergarten;

  bool get reducedMotion => _session.reducedMotion;

  MathProfile? get myProfile => _session.profile.value;

  /// Spoken question text for early readers. The same words stay on screen as
  /// captions, and the child can replay them at any time.
  String? get questionNarration {
    final current = question;
    if (current == null) return null;
    return '${NarrationText.question(text: current.text, options: current.options)} Tap the answer you think is right.';
  }

  String? get revealNarration {
    final data = reveal;
    if (data == null) return null;
    final mine = playerResult(_session.userId);
    final correct = mine?.isCorrect ?? false;
    if (isKindergarten && !correct) {
      final count = _countAloud(data.correctAnswer);
      if (count != null) {
        return 'Good try. Let’s count together. $count '
            'The answer is ${data.correctAnswer}.';
      }
    }
    return NarrationText.feedback(
      correct: correct,
      correctAnswer: data.correctAnswer,
      explanation: data.explanation,
    );
  }

  String? _countAloud(String answer) {
    final value = int.tryParse(answer.trim());
    if (value == null || value < 1 || value > 10) return null;
    return List.generate(value, (index) => '${index + 1}').join(', ');
  }

  String? get currentPlayerId => _session.userId;

  bool get hasAnswered =>
      snapshot?.myAnswer != null || selectedAnswer.value.isNotEmpty;

  String? get myAnswerValue =>
      snapshot?.myAnswer?.answer ??
      (selectedAnswer.value.isEmpty ? null : selectedAnswer.value);

  MathStanding? get myStanding {
    final id = _session.userId;
    final standings = results?.standings ?? const <MathStanding>[];
    for (final standing in standings) {
      if (standing.playerId == id) return standing;
    }
    return null;
  }

  bool get isWinner => myStanding?.rank == 1;

  MathRevealPlayerResult? playerResult(String? playerId) {
    final r = reveal;
    if (r == null || playerId == null) return null;
    for (final result in r.results) {
      if (result.playerId == playerId) return result;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    roomId = Get.parameters['roomId'] ?? '';
    if (roomId.isEmpty) {
      error.value = 'This match link is missing a room.';
      return;
    }
    isLoading.value = true;
    _poll();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    _ticker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateRemaining(),
    );
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _api.heartbeat(roomId).catchError((_) {}),
    );
  }

  @override
  void onClose() {
    _stopTimers();
    super.onClose();
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _ticker?.cancel();
    _heartbeatTimer?.cancel();
  }

  Future<void> _poll() async {
    if (_polling || _navigating || roomId.isEmpty) return;
    _polling = true;
    try {
      await _api.advanceMatch(roomId);
      final next = await _api.roomState(roomId);
      _apply(next);
      error.value = '';
    } catch (exception) {
      if (state.value == null) {
        error.value = UiFeedback.friendly(exception);
      }
    } finally {
      _polling = false;
      isLoading.value = false;
    }
  }

  void _apply(MathRoomState next) {
    final previous = state.value;
    final previousPhase = previous?.room.status;
    final previousQuestion = previous?.question?.id;

    _serverAt = next.serverNow;
    _receivedAt = DateTime.now();
    state.value = next;
    _updateRemaining();

    final nextQuestion = next.question?.id;
    if (nextQuestion != previousQuestion) {
      selectedAnswer.value = '';
      if (nextQuestion != null && nextQuestion != _lastQuestionId) {
        _lastQuestionId = nextQuestion;
      }
    }

    if (next.room.status == RoomPhase.questionReveal &&
        next.reveal != null &&
        _revealAnnouncedFor != next.question?.id) {
      _revealAnnouncedFor = next.question?.id;
      final mine = playerResult(_session.userId ?? '');
      if (mine != null) {
        if (mine.isCorrect) {
          AppFeedback.correct(enabled: _session.soundEnabled);
        } else {
          AppFeedback.incorrect(enabled: _session.soundEnabled);
        }
      }
    }

    if (next.room.status == RoomPhase.finalResults &&
        _finalAnnouncedFor != next.match?.id) {
      _finalAnnouncedFor = next.match?.id;
      if (next.finalResults != null) {
        AppFeedback.celebrate(enabled: _session.soundEnabled);
      }
    }

    if (previousPhase == RoomPhase.finalResults &&
        next.room.status == RoomPhase.waiting) {
      _goToLobby();
      return;
    }

    if (next.room.status == RoomPhase.waiting && next.match == null) {
      _goToLobby();
      return;
    }

    for (final code in next.myNewAchievements) {
      if (_announcedAchievements.add(code)) {
        UiFeedback.success('New badge unlocked: ${_achievementLabel(code)}!');
      }
    }
  }

  String _achievementLabel(String code) {
    return switch (code) {
      'first_match' => 'First Clash',
      'perfect_match' => 'Perfect Match',
      'accuracy_star' => 'Accuracy Star',
      'speed_champion' => 'Speed Champion',
      'math_explorer' => 'Math Explorer',
      'consistent_learner' => 'Consistent Learner',
      'skill_master' => 'Skill Master',
      'five_streak' => 'Five Win Streak',
      'practice_10' => 'Practice Pro',
      'level_5' => 'Level 5',
      _ => code.replaceAll('_', ' '),
    };
  }

  DateTime? get _deadline {
    final m = match;
    if (m == null) return null;
    return switch (phase) {
      RoomPhase.countdown => m.countdownEndsAt,
      RoomPhase.questionActive => m.questionEndsAt,
      RoomPhase.questionReveal => m.revealEndsAt,
      RoomPhase.nextQuestion => m.nextStartsAt,
      _ => null,
    };
  }

  Duration get _phaseTotal {
    return switch (phase) {
      RoomPhase.countdown => const Duration(seconds: 3),
      RoomPhase.questionActive => Duration(seconds: match?.answerSeconds ?? 18),
      RoomPhase.questionReveal => const Duration(seconds: 5),
      RoomPhase.nextQuestion => const Duration(milliseconds: 1500),
      _ => const Duration(seconds: 1),
    };
  }

  void _updateRemaining() {
    final deadline = _deadline;
    final total = _phaseTotal;
    if (deadline == null) {
      remainingMs.value = 0;
      totalMs.value = math.max(total.inMilliseconds, 1);
      return;
    }
    final serverNow = _serverAt.add(DateTime.now().difference(_receivedAt));
    final remaining = deadline.difference(serverNow).inMilliseconds;
    remainingMs.value = math.max(0, remaining);
    totalMs.value = math.max(total.inMilliseconds, 1);
  }

  Duration get remaining => Duration(milliseconds: remainingMs.value);
  Duration get phaseTotal => Duration(milliseconds: totalMs.value);

  String? get serverErrorHint {
    if (error.value.isEmpty) return null;
    return error.value;
  }

  Future<void> submitAnswer(String answer) async {
    if (isSubmitting.value || hasAnswered) return;
    final currentQuestion = question;
    if (currentQuestion == null || phase != RoomPhase.questionActive) return;

    isSubmitting.value = true;
    selectedAnswer.value = answer;
    try {
      final response = await _api.submitAnswer(
        roomId: roomId,
        questionId: currentQuestion.id,
        answer: answer,
      );
      if (!response.success) {
        selectedAnswer.value = '';
        switch (response.error) {
          case 'already_answered':
          case 'question_closed':
          case 'time_up':
            await _poll();
            break;
          case 'invalid_answer':
            UiFeedback.error('That answer was not one of the choices.');
            break;
          default:
            UiFeedback.error('That answer could not be sent. Try again.');
        }
        return;
      }
      AppFeedback.tap(enabled: _session.soundEnabled);
      await _poll();
    } catch (exception) {
      selectedAnswer.value = '';
      UiFeedback.error(UiFeedback.friendly(exception));
    } finally {
      isSubmitting.value = false;
    }
  }

  AnswerOptionState optionState(String option) {
    final mine = myAnswerValue;
    final revealData = reveal;
    if (phase == RoomPhase.questionReveal || phase == RoomPhase.finalResults) {
      if (revealData != null && option == revealData.correctAnswer) {
        return AnswerOptionState.correct;
      }
      if (mine != null && option == mine) {
        return AnswerOptionState.incorrect;
      }
      return AnswerOptionState.muted;
    }
    if (mine != null && option == mine) return AnswerOptionState.selected;
    return AnswerOptionState.idle;
  }

  bool get optionsLocked =>
      hasAnswered ||
      isSubmitting.value ||
      phase != RoomPhase.questionActive ||
      remainingMs.value <= 0;

  Future<void> playAgain() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      await _api.playAgain(roomId);
      _goToLobby();
    } catch (exception) {
      UiFeedback.error(UiFeedback.friendly(exception));
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> leaveRoom() async {
    _navigating = true;
    _stopTimers();
    try {
      await _api.leaveRoom(roomId);
    } catch (_) {
      // The player still returns home if the connection drops.
    }
    Get.offAllNamed(AppRoutes.home);
  }

  /// A calm next step after the match: leave the finished room and open
  /// practice, where the same skill can be tried without a clock.
  Future<void> practiseMore({MathTopic? topic}) async {
    _navigating = true;
    _stopTimers();
    try {
      await _api.leaveRoom(roomId);
    } catch (_) {
      // Practice should still open if the room has already closed.
    }
    await Get.offAllNamed(AppRoutes.practice, arguments: {'topic': ?topic});
  }

  void openProgress() {
    Get.toNamed(AppRoutes.progress);
  }

  void goHome() {
    _navigating = true;
    _stopTimers();
    Get.offAllNamed(AppRoutes.home);
  }

  void _goToLobby() {
    if (_navigating) return;
    _navigating = true;
    _stopTimers();
    Get.offNamed(AppRoutes.lobby, parameters: {'roomId': roomId});
  }
}
