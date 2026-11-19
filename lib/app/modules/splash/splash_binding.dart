import 'package:get/get.dart';

import '../../services/session_service.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(SplashController(Get.find<SessionService>()));
  }
}
