import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class SplashController extends GetxController with GetTickerProviderStateMixin {
  SplashController(this._session);

  final SessionService _session;

  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> fade = CurvedAnimation(
    parent: animation,
    curve: const Interval(0, 0.7, curve: Curves.easeOut),
  );

  late final Animation<double> pop = Tween<double>(
    begin: 0.86,
    end: 1,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));

  final RxString status = RxString('Warming up the arena…');

  @override
  void onInit() {
    super.onInit();
    animation.forward();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    final signedIn = Supabase.instance.client.auth.currentUser != null;

    if (signedIn) {
      status.value = 'Welcome back!';
      await _session.refreshProfile();
    } else {
      status.value = 'Ready when you are!';
    }

    final elapsed = DateTime.now().difference(started);
    const minimum = Duration(milliseconds: 850);
    if (elapsed < minimum) {
      await Future<void>.delayed(minimum - elapsed);
    }

    if (Get.currentRoute != AppRoutes.splash && Get.currentRoute != '/') {
      return;
    }

    if (signedIn && _session.profile.value != null) {
      Get.offAllNamed(AppRoutes.home);
    } else if (signedIn) {
      // Session exists but the profile could not be loaded (offline). Let the
      // home screen show a retry instead of forcing a sign-out.
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.welcome);
    }
  }

  @override
  void onClose() {
    animation.dispose();
    super.onClose();
  }
}
