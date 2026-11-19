import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

enum _ToastKind { success, error, info }

class UiFeedback {
  UiFeedback._();

  static void success(String message) => _show(message, _ToastKind.success);

  static void error(String message) => _show(message, _ToastKind.error);

  static void info(String message) => _show(message, _ToastKind.info);

  static void _show(String message, _ToastKind kind) {
    final (background, foreground, icon, title) = switch (kind) {
      _ToastKind.success => (
        AppColors.mint,
        const Color(0xFF063B2A),
        Icons.check_circle_rounded,
        'Nice!',
      ),
      _ToastKind.error => (
        AppColors.errorSoft,
        AppColors.errorDark,
        Icons.error_rounded,
        'Oops',
      ),
      _ToastKind.info => (
        AppColors.surface,
        AppColors.ink,
        Icons.info_rounded,
        'Heads up',
      ),
    };

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: background,
      colorText: foreground,
      margin: const EdgeInsets.all(16),
      borderRadius: 20,
      duration: const Duration(seconds: 3),
      icon: Icon(icon, color: foreground),
      shouldIconPulse: false,
      borderColor: kind == _ToastKind.error
          ? AppColors.error.withValues(alpha: 0.4)
          : null,
      borderWidth: kind == _ToastKind.error ? 2 : 0,
      snackStyle: SnackStyle.FLOATING,
      titleText: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: foreground,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: foreground,
        ),
      ),
    );
  }

  /// Turns transport/API exceptions into a short, child-friendly message.
  static String friendly(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text.isEmpty ? 'Something went wrong. Please try again.' : text;
  }
}
