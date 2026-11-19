import 'package:get/get.dart';

import '../../core/utils/ui_feedback.dart';
import '../../data/models/math_api_models.dart';
import '../../data/providers/math_api_provider.dart';
import '../../services/session_service.dart';

class AchievementsController extends GetxController {
  AchievementsController(this._api, this._session);

  final MathApiProvider _api;
  final SessionService _session;

  final RxList<MathAchievement> achievements = <MathAchievement>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  List<MathAchievement> get unlocked =>
      achievements.where((achievement) => achievement.isUnlocked).toList();

  List<MathAchievement> get locked =>
      achievements.where((achievement) => !achievement.isUnlocked).toList();

  int get totalXp =>
      unlocked.fold<int>(0, (sum, achievement) => sum + achievement.xp);

  double get completion =>
      achievements.isEmpty ? 0 : unlocked.length / achievements.length;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    try {
      final next = await _api.achievementCatalogue();
      achievements.assignAll(next);
      await _session.refreshProfile();
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
    } finally {
      isLoading.value = false;
    }
  }
}
