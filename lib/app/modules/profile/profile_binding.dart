import 'package:get/get.dart';

import '../../data/providers/math_api_provider.dart';
import '../../services/session_service.dart';
import 'profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        Get.find<MathApiProvider>(),
        Get.find<SessionService>(),
      ),
    );
  }
}
