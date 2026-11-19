import 'package:get/get.dart';

import '../../data/providers/math_api_provider.dart';
import '../../services/session_service.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<MathApiProvider>(),
        Get.find<SessionService>(),
      ),
    );
  }
}
