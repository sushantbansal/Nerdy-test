import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../services/session_service.dart';
import 'app_routes.dart';

/// Keeps protected screens behind a signed-in Supabase session.
///
/// Guests are real anonymous Supabase users, so they pass this check too.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = Get.find<SessionService>();
    if (!session.isSignedIn.value) {
      return const RouteSettings(name: AppRoutes.welcome);
    }
    return null;
  }
}
