import 'package:get/get.dart';

import '../../core/utils/ui_feedback.dart';
import '../../data/models/math_api_models.dart';
import '../../data/providers/math_api_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class ProfileController extends GetxController {
  ProfileController(this._api, this._session);

  final MathApiProvider _api;
  final SessionService _session;

  final Rx<MathProfile?> profile = Rx<MathProfile?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  String? playerId;

  bool get isMe =>
      playerId == null ||
      playerId == _session.userId ||
      profile.value?.isMe == true;

  @override
  void onInit() {
    super.onInit();
    playerId = Get.parameters['playerId'];
    if (playerId == null || playerId!.isEmpty) {
      playerId = null;
    }
    final cached = _session.profile.value;
    if (playerId == null && cached != null) {
      profile.value = cached;
    }
    refresh();
  }

  @override
  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    try {
      final next = await _api.profile(playerId);
      profile.value = next;
      if (next.isMe) {
        _session.profile.value = next;
      }
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
    } finally {
      isLoading.value = false;
    }
  }

  void editProfile() => Get.toNamed(AppRoutes.editProfile);
  void openSettings() => Get.toNamed(AppRoutes.settings);
  void openAchievements() => Get.toNamed(AppRoutes.achievements);
  void openProgress() => Get.toNamed(AppRoutes.progress);
}
