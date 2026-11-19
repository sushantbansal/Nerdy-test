import 'package:get/get.dart';

import '../../data/providers/math_api_provider.dart';
import '../../services/session_service.dart';
import 'lobby_controller.dart';

class LobbyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LobbyController>(
      () => LobbyController(
        Get.find<MathApiProvider>(),
        Get.find<SessionService>(),
      ),
    );
  }
}
