import 'package:get/get.dart';

import '../../services/session_service.dart';
import 'welcome_controller.dart';

class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WelcomeController>(
      () => WelcomeController(Get.find<SessionService>()),
    );
  }
}
