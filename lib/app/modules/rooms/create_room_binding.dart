import 'package:get/get.dart';

import '../../data/providers/math_api_provider.dart';
import '../../services/session_service.dart';
import 'create_room_controller.dart';

class CreateRoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateRoomController>(
      () => CreateRoomController(
        Get.find<MathApiProvider>(),
        Get.find<SessionService>(),
      ),
    );
  }
}
