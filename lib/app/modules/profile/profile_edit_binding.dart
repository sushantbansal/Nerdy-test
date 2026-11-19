import 'package:get/get.dart';

import '../../services/session_service.dart';
import 'profile_edit_controller.dart';

class ProfileEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileEditController>(
      () => ProfileEditController(Get.find<SessionService>()),
    );
  }
}
