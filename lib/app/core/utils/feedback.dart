import 'package:flutter/services.dart';

/// Small, dependency-free feedback layer. Sound can be muted from Settings and
/// respects the reduced-motion preference for larger celebrations.
class AppFeedback {
  AppFeedback._();

  static void tap({bool enabled = true}) {
    if (!enabled) return;
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  static void correct({bool enabled = true}) {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void incorrect({bool enabled = true}) {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  static void celebrate({bool enabled = true}) {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }
}
