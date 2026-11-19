import 'package:get/get.dart';

import '../../data/providers/math_api_provider.dart';
import '../../services/session_service.dart';
import 'room_browser_controller.dart';

class RoomBrowserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoomBrowserController>(
      () => RoomBrowserController(
        Get.find<MathApiProvider>(),
        Get.find<SessionService>(),
      ),
    );
  }
}
