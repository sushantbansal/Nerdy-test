import 'package:get/get.dart';

import '../../data/providers/math_api_provider.dart';
import '../../services/session_service.dart';
import 'leaderboard_controller.dart';

class LeaderboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LeaderboardController>(
      () => LeaderboardController(
        Get.find<MathApiProvider>(),
        Get.find<SessionService>(),
      ),
    );
  }
}
