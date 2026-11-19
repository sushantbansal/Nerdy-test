import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/utils/ui_feedback.dart';
import '../../routes/app_routes.dart';
import '../../services/narration_service.dart';
import '../../services/session_service.dart';
import '../../services/theme_service.dart';

class SettingsController extends GetxController {
  SettingsController(this._session, this._theme);

  final SessionService _session;
  final ThemeService? _theme;
  final RxBool _fallbackDark = false.obs;

  final RxBool soundEnabled = true.obs;
  final RxBool reducedMotion = false.obs;
  final RxBool leaderboardVisible = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isDeleting = false.obs;
  final RxBool isSigningOut = false.obs;
  final RxString error = ''.obs;

  bool get isGuest => _session.isGuest;
  RxBool get darkMode => _theme?.isDark ?? _fallbackDark;
  String get email => _session.profile.value?.displayName ?? '';
  String get displayName => _session.profile.value?.displayName ?? 'Player';

  @override
  void onInit() {
    super.onInit();
    syncFromProfile();
  }

  void syncFromProfile() {
    final profile = _session.profile.value;
    if (profile == null) return;
    soundEnabled.value = profile.soundEnabled ?? true;
    reducedMotion.value = profile.reducedMotion ?? false;
    leaderboardVisible.value = profile.leaderboardVisible ?? true;
  }

  Future<void> setSound(bool value) async {
    final previous = soundEnabled.value;
    soundEnabled.value = value;
    if (!value && Get.isRegistered<NarrationService>()) {
      unawaited(Get.find<NarrationService>().stop());
    }
    await _save(
      () => _session.updateSettings(soundEnabled: value),
      onFailure: () => soundEnabled.value = previous,
    );
  }

  Future<void> setDarkMode(bool value) async {
    if (_theme != null) {
      await _theme.setDark(value);
    } else {
      _fallbackDark.value = value;
    }
  }

  Future<void> setReducedMotion(bool value) async {
    final previous = reducedMotion.value;
    reducedMotion.value = value;
    await _save(
      () => _session.updateSettings(reducedMotion: value),
      onFailure: () => reducedMotion.value = previous,
    );
  }

  Future<void> setLeaderboardVisible(bool value) async {
    final previous = leaderboardVisible.value;
    leaderboardVisible.value = value;
    await _save(
      () => _session.updateSettings(leaderboardVisible: value),
      onFailure: () => leaderboardVisible.value = previous,
    );
  }

  Future<void> _save(
    Future<void> Function() action, {
    VoidCallback? onFailure,
  }) async {
    if (isSaving.value) return;
    isSaving.value = true;
    error.value = '';
    try {
      await action();
    } catch (exception) {
      onFailure?.call();
      error.value = UiFeedback.friendly(exception);
      UiFeedback.error(error.value);
    } finally {
      isSaving.value = false;
    }
  }

  void saveGuestProgress() {
    Get.toNamed(AppRoutes.auth, arguments: {'mode': 'upgrade'});
  }

  Future<void> signOut() async {
    if (isSigningOut.value) return;
    isSigningOut.value = true;
    try {
      await _session.signOut();
      Get.offAllNamed(AppRoutes.welcome);
    } catch (exception) {
      UiFeedback.error(UiFeedback.friendly(exception));
    } finally {
      isSigningOut.value = false;
    }
  }

  Future<void> deleteAccount() async {
    if (isDeleting.value) return;
    isDeleting.value = true;
    try {
      await _session.deleteAccount();
      UiFeedback.success('Your account and data were deleted.');
      Get.offAllNamed(AppRoutes.welcome);
    } catch (exception) {
      UiFeedback.error(UiFeedback.friendly(exception));
    } finally {
      isDeleting.value = false;
    }
  }
}
