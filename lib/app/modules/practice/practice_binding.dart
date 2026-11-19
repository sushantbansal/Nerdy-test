import 'package:get/get.dart';

import '../../data/providers/math_api_provider.dart';
import '../../services/session_service.dart';
import 'practice_controller.dart';

class PracticeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PracticeController>(
      () => PracticeController(
        Get.find<MathApiProvider>(),
        Get.find<SessionService>(),
      ),
    );
  }
}
