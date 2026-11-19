import 'package:get/get.dart';

import '../data/providers/auth_provider.dart';
import '../data/providers/math_api_provider.dart';
import '../services/narration_service.dart';
import '../services/session_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthProvider(), permanent: true);
    Get.put(MathApiProvider(), permanent: true);
    Get.put(
      SessionService(Get.find<AuthProvider>(), Get.find<MathApiProvider>()),
      permanent: true,
    );
    Get.put(
      NarrationService(Get.find<SessionService>()),
      permanent: true,
    );
  }
}
