import 'dart:math' as math;

import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/ui_feedback.dart';
import '../../data/models/math_api_models.dart';
import '../../data/providers/math_api_provider.dart';
import '../../domain/models/math_models.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class HomeController extends GetxController {
  HomeController(this._api, this._session);

  final MathApiProvider _api;
  final SessionService _session;

  final RxBool isLoading = false.obs;
  final RxBool isQuickPlaying = false.obs;
  final RxString error = ''.obs;
  final Rxn<MathActiveRoom> activeRoom = Rxn<MathActiveRoom>();
  final RxInt weeklyRank = 0.obs;
  final RxList<MathLeaderboardEntry> weeklyTop = <MathLeaderboardEntry>[].obs;

  bool _pendingQuickPlay = false;

  MathProfile? get profile => _session.profile.value;

  bool get isKindergarten => _session.isKindergarten;

  bool get needsTutorial => _session.needsKindergartenTutorial;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is Map && arguments['startQuickPlay'] == true) {
      _pendingQuickPlay = true;
    }
    refresh();
  }

  @override
  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    try {
      await _session.refreshProfile();
      final results = await Future.wait([
        _api.myActiveRoom(),
        _api
            .leaderboard(window: 'weekly', limit: 5)
            .catchError((_) => <MathLeaderboardEntry>[]),
      ]);
      activeRoom.value = results[0] as MathActiveRoom?;
      final board = results[1] as List<MathLeaderboardEntry>;
      weeklyTop.assignAll(board);
      final grade = profile?.grade;
      final mine = board.where((entry) => entry.playerId == _session.userId);
      weeklyRank.value = mine.isEmpty ? 0 : mine.first.rank;
      // A grade filter is a nicer default than an empty board for the card.
      if (weeklyTop.isEmpty && grade != null) {
        final gradeBoard = await _api
            .leaderboard(grade: grade, window: 'weekly', limit: 5)
            .catchError((_) => <MathLeaderboardEntry>[]);
        weeklyTop.assignAll(gradeBoard);
      }
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
    } finally {
      isLoading.value = false;
    }
    if (_pendingQuickPlay) {
      _pendingQuickPlay = false;
      await quickPlay();
    }
  }

  Future<bool> ensureTutorial() async {
    if (!needsTutorial) return true;
    await Get.toNamed(AppRoutes.tutorial);
    return false;
  }

  void openTutorial() => Get.toNamed(AppRoutes.tutorial);

  Future<void> quickPlay() async {
    if (isQuickPlaying.value) return;
    if (!await ensureTutorial()) return;
    isQuickPlaying.value = true;
    try {
      final grade = profile?.grade ?? GradeLevel.grade1;
      final rooms = await _api.listRooms(
        grade: grade,
        onlyAvailable: true,
        limit: 10,
      );
      final open = rooms.where((room) => !room.isFull).toList();
      if (open.isNotEmpty) {
        final room = open.first;
        if (room.isJoined) {
          Get.toNamed(AppRoutes.lobby, parameters: {'roomId': room.id});
        } else {
          final joined = await _api.joinRoom(room.code);
          Get.toNamed(AppRoutes.lobby, parameters: {'roomId': joined.roomId});
        }
        return;
      }

      final random = math.Random();
      final adjective =
          AppConstants.roomNameAdjectives[random.nextInt(
            AppConstants.roomNameAdjectives.length,
          )];
      final noun = AppConstants
          .roomNameNouns[random.nextInt(AppConstants.roomNameNouns.length)];
      final kindergarten = grade == GradeLevel.kindergarten;
      final created = await _api.createRoom(
        name: '$adjective $noun',
        visibility: RoomVisibility.public,
        grade: grade,
        topics: const [MathTopic.mixed],
        difficulty: MathDifficulty.adaptive,
        questionCount: AppConstants.defaultQuestionCount,
        answerSeconds: kindergarten
            ? AppConstants.kindergartenAnswerSeconds
            : AppConstants.defaultAnswerSeconds,
        maxPlayers: AppConstants.defaultMaxPlayers,
        speedBonusEnabled: !kindergarten,
      );
      Get.toNamed(
        AppRoutes.lobby,
        parameters: {'roomId': created.roomId},
        arguments: {'justCreated': true, 'roomCode': created.roomCode},
      );
    } catch (exception) {
      UiFeedback.error(UiFeedback.friendly(exception));
    } finally {
      isQuickPlaying.value = false;
    }
  }

  Future<void> openRoom(MathActiveRoom room) async {
    final inProgress = room.status.isActiveMatch;
    await Get.toNamed(
      inProgress ? AppRoutes.match : AppRoutes.lobby,
      parameters: {'roomId': room.roomId},
    );
    await refresh();
  }

  Future<void> openRoute(
    String route, {
    Map<String, String>? parameters,
  }) async {
    await Get.toNamed(route, parameters: parameters);
    await refresh();
  }

  void openProfile() => openRoute(AppRoutes.profile);
  void openSettings() => openRoute(AppRoutes.settings);

  Future<void> openBrowse() async {
    if (!await ensureTutorial()) return;
    await openRoute(AppRoutes.browseRooms);
  }

  Future<void> openCreate() async {
    if (!await ensureTutorial()) return;
    await openRoute(AppRoutes.createRoom);
  }

  Future<void> openJoin() async {
    if (!await ensureTutorial()) return;
    await openRoute(AppRoutes.joinRoom);
  }

  void openPractice([MathTopic? topic]) async {
    await Get.toNamed(AppRoutes.practice, arguments: {'topic': ?topic});
    await refresh();
  }

  void openLeaderboards() => openRoute(AppRoutes.leaderboards);
  void openAchievements() => openRoute(AppRoutes.achievements);
  void openProgress() => openRoute(AppRoutes.progress);

  MathTopic get recommendedTopic =>
      profile?.recommendedTopic ?? MathTopic.mixed;

  double get recommendedAccuracy {
    final topic = recommendedTopic;
    final skills = profile?.skills ?? const [];
    final matching = skills.where((skill) => skill.topic == topic).toList();
    if (matching.isEmpty) return 0;
    final attempts = matching.fold<int>(0, (sum, s) => sum + s.attempts);
    final correct = matching.fold<int>(0, (sum, s) => sum + s.correct);
    return attempts == 0 ? 0 : correct / attempts;
  }
}
