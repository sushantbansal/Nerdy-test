import 'package:get/get.dart';

import '../../services/session_service.dart';
import 'progress_controller.dart';

class ProgressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProgressController>(
      () => ProgressController(Get.find<SessionService>()),
    );
  }
}
