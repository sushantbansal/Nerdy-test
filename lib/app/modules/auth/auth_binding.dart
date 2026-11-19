import 'package:get/get.dart';

import '../../services/session_service.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(Get.find<SessionService>()),
    );
  }
}
