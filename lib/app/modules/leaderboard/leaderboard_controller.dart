import 'package:get/get.dart';

import '../../core/utils/ui_feedback.dart';
import '../../data/models/math_api_models.dart';
import '../../data/providers/math_api_provider.dart';
import '../../domain/models/math_models.dart';
import '../../services/session_service.dart';

class LeaderboardController extends GetxController {
  LeaderboardController(this._api, this._session);

  final MathApiProvider _api;
  final SessionService _session;

  final RxList<MathLeaderboardEntry> entries = <MathLeaderboardEntry>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString window = 'week'.obs;
  final Rxn<GradeLevel> grade = Rxn<GradeLevel>();
  final Rxn<MathTopic> topic = Rxn<MathTopic>();

  @override
  void onInit() {
    super.onInit();
    grade.value = _session.profile.value?.grade;
    refresh();
  }

  String get apiWindow => window.value == 'week' ? 'weekly' : 'all_time';

  Future<void> setWindow(String next) async {
    if (window.value == next) return;
    window.value = next;
    await refresh();
  }

  Future<void> setGrade(GradeLevel? next) async {
    grade.value = next;
    await refresh();
  }

  Future<void> setTopic(MathTopic? next) async {
    topic.value = next;
    await refresh();
  }

  @override
  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    try {
      final next = await _api.leaderboard(
        grade: grade.value,
        topic: topic.value,
        window: apiWindow,
        limit: 50,
      );
      entries.assignAll(next);
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
    } finally {
      isLoading.value = false;
    }
  }

  List<MathLeaderboardEntry> get podium => entries.take(3).toList();
  List<MathLeaderboardEntry> get rest =>
      entries.length <= 3 ? const [] : entries.sublist(3);

  MathLeaderboardEntry? get mine {
    for (final entry in entries) {
      if (entry.isMe) return entry;
    }
    return null;
  }

  String get windowLabel => window.value == 'week' ? 'This week' : 'All time';
}
