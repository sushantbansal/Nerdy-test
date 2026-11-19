import 'package:get/get.dart';

import '../../data/providers/math_api_provider.dart';
import 'join_room_controller.dart';

class JoinRoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JoinRoomController>(
      () => JoinRoomController(Get.find<MathApiProvider>()),
    );
  }
}
