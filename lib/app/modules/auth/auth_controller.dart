import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/ui_feedback.dart';
import '../../domain/models/math_models.dart';
import '../../routes/app_routes.dart';
import '../../services/narration_service.dart';
import '../../services/session_service.dart';

enum AuthMode { signIn, signUp, upgrade }

class AuthController extends GetxController {
  AuthController(this._session);

  final SessionService _session;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  final Rx<AuthMode> mode = AuthMode.signIn.obs;
  final RxBool submitting = RxBool(false);
  final RxBool obscurePassword = RxBool(true);
  final RxString error = RxString('');

  final Rx<GradeLevel> grade = GradeLevel.grade1.obs;
  final RxInt avatarIndex = 0.obs;
  final RxString avatarColor = AppConstants.avatarColors.first.obs;

  bool get isGuestUpgrade => _session.isSignedIn.value && _session.isGuest;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (_session.isSignedIn.value && _session.isGuest) {
      mode.value = AuthMode.upgrade;
    } else if (arguments is Map && arguments['mode'] == 'sign_up') {
      mode.value = AuthMode.signUp;
    } else if (arguments is Map && arguments['mode'] == 'upgrade') {
      mode.value = AuthMode.upgrade;
    }
    final profile = _session.profile.value;
    if (profile != null) {
      nameController.text = profile.displayName;
      grade.value = profile.grade;
      avatarIndex.value = profile.avatarIndex;
      avatarColor.value = profile.avatarColor;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.onClose();
  }

  void switchMode(AuthMode next) {
    if (mode.value == AuthMode.upgrade) return;
    error.value = '';
    mode.value = next;
  }

  void clearError() {
    if (error.value.isNotEmpty) error.value = '';
  }

  void selectAvatar(int index, String color) {
    avatarIndex.value = index;
    avatarColor.value = color;
  }

  String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Enter your email address.';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email)) return 'That email does not look right.';
    return null;
  }

  String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter a password.';
    if (password.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  Future<void> submit() async {
    if (submitting.value) return;
    error.value = '';

    final emailError = validateEmail(emailController.text);
    if (emailError != null) {
      error.value = emailError;
      return;
    }
    final passwordError = validatePassword(passwordController.text);
    if (passwordError != null) {
      error.value = passwordError;
      return;
    }

    final name = nameController.text.trim();
    if (mode.value == AuthMode.signUp &&
        (name.length < 2 || name.length > 20)) {
      error.value = 'Choose a display name between 2 and 20 characters.';
      return;
    }

    submitting.value = true;
    try {
      switch (mode.value) {
        case AuthMode.signIn:
          await _session.signInWithEmail(
            email: emailController.text,
            password: passwordController.text,
          );
          UiFeedback.success('Welcome back!');
        case AuthMode.signUp:
          final outcome = await _session.signUpWithEmail(
            email: emailController.text,
            password: passwordController.text,
            displayName: name,
            grade: grade.value,
            avatarIndex: avatarIndex.value,
            avatarColor: avatarColor.value,
          );
          if (!outcome.signedIn) {
            error.value =
                outcome.message ??
                'Check your email to confirm your account, then sign in.';
            mode.value = AuthMode.signIn;
            return;
          }
          UiFeedback.success('Account created. Your progress is saved!');
        case AuthMode.upgrade:
          await _session.upgradeGuestAccount(
            email: emailController.text,
            password: passwordController.text,
          );
          UiFeedback.success('Progress saved! You can sign in anywhere now.');
      }
      Get.offAllNamed(AppRoutes.home);
    } catch (exception) {
      final message = UiFeedback.friendly(exception);
      error.value = message;
      UiFeedback.error(message);
    } finally {
      submitting.value = false;
    }
  }

  Future<void> sendResetEmail() async {
    final emailError = validateEmail(emailController.text);
    if (emailError != null) {
      error.value = emailError;
      return;
    }
    try {
      await _session.resetPassword(emailController.text);
      UiFeedback.info('Password reset email sent. Check your inbox.');
    } catch (exception) {
      UiFeedback.error(UiFeedback.friendly(exception));
    }
  }

  void backToWelcome() {
    if (Get.currentRoute == AppRoutes.auth) {
      Get.offAllNamed(AppRoutes.welcome);
    }
  }

  /// Leaves the account screen. Guests who opened it from Settings go back to
  /// the game freed from the upgrade prompt; new players return to setup.
  void close() {
    if (mode.value == AuthMode.upgrade) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }
    backToWelcome();
  }

  void speakHelp() {
    if (!Get.isRegistered<NarrationService>()) return;
    unawaited(
      Get.find<NarrationService>().speak(
        'Tap the big play button to start. A grown-up can help with '
        'the sign-in boxes.',
      ),
    );
  }

  void showAccountHelp() {
    final context = Get.context;
    if (context == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why create an account?'),
        content: const SingleChildScrollView(
          child: Text(
            'Accounts are optional. A guest profile already saves progress '
            'on this device.\n\n'
            'Adding an email keeps your XP, badges and match history when you '
            'change devices. We never ask for a real name, photo or address, '
            'and there is no open chat.\n\n'
            'Please ask a parent or guardian before creating an account for '
            'a child.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
