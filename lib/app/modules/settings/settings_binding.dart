import 'package:get/get.dart';

import '../../services/session_service.dart';
import '../../services/theme_service.dart';
import 'settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        Get.find<SessionService>(),
        Get.isRegistered<ThemeService>() ? Get.find<ThemeService>() : null,
      ),
    );
  }
}
