import 'package:flutter/material.dart';

/// Candy Arcade palette.
///
/// The palette is intentionally small and high-contrast: deep ink for text,
/// bright candy accents for actions and a soft blue canvas.
///
/// Light values are kept exactly as they were. When [isDark] is enabled every
/// semantic colour resolves to a friendly night-time shade instead, so the
/// whole app can switch without touching individual widgets.
class AppColors {
  AppColors._();

  static bool _isDark = false;

  static bool get isDark => _isDark;

  static void setDarkMode(bool value) {
    _isDark = value;
  }

  // Brand / ink -------------------------------------------------------------
  static Color get ink =>
      _isDark ? const Color(0xFFF7F9FF) : const Color(0xFF151C22);
  static Color get inkSoft =>
      _isDark ? const Color(0xFFB9C5E2) : const Color(0xFF5B6672);
  static Color get outline =>
      _isDark ? const Color(0xFF46537A) : const Color(0xFFBEC7D4);
  static Color get canvas =>
      _isDark ? const Color(0xFF11182E) : const Color(0xFFF6FAFF);
  static Color get surface =>
      _isDark ? const Color(0xFF1E2740) : const Color(0xFFFFFFFF);
  static Color get surfaceSoft =>
      _isDark ? const Color(0xFF2A3452) : const Color(0xFFEDF4FC);

  // Blue --------------------------------------------------------------------
  static Color get primary =>
      _isDark ? const Color(0xFF54C8FF) : const Color(0xFF00629D);
  static Color get primaryLight =>
      _isDark ? const Color(0xFF8ADDFF) : const Color(0xFF00A2FF);
  static Color get primaryDark =>
      _isDark ? const Color(0xFF8AD8FF) : const Color(0xFF004A78);
  static Color get primaryContainer =>
      _isDark ? const Color(0xFF2E7FA8) : const Color(0xFF00A2FF);
  static Color get primarySoft =>
      _isDark ? const Color(0xFF1B3552) : const Color(0xFFE3F2FF);
  static Color get primaryFixed =>
      _isDark ? const Color(0xFF172C44) : const Color(0xFFD6ECFF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Foreground used on bright candy accents. Dark mode pairs bright accents
  /// with deep text so they stay readable for young eyes.
  static Color get onAccent =>
      _isDark ? const Color(0xFF0C1B2B) : const Color(0xFFFFFFFF);

  /// Selected pill / segmented-control colours.
  static Color get selectionSurface => _isDark ? primary : ink;
  static Color get onSelection =>
      _isDark ? const Color(0xFF0C1B2B) : const Color(0xFFFFFFFF);
  static Color get onPrimaryContainer =>
      _isDark ? const Color(0xFFD8F2FF) : const Color(0xFF003659);

  // Yellow ------------------------------------------------------------------
  static Color get yellow =>
      _isDark ? const Color(0xFFFFD84D) : const Color(0xFFFFCA00);
  static Color get yellowDark =>
      _isDark ? const Color(0xFFFFE89B) : const Color(0xFF8A6A00);
  static Color get yellowSoft =>
      _isDark ? const Color(0xFF3B3320) : const Color(0xFFFFF6DC);
  static Color get secondary =>
      _isDark ? const Color(0xFFFFD84D) : const Color(0xFF755B00);
  static Color get secondaryLight =>
      _isDark ? const Color(0xFFFFE27A) : const Color(0xFFF3C000);
  static Color get secondaryContainer =>
      _isDark ? const Color(0xFF4A3D14) : const Color(0xFFFDC800);
  static Color get onSecondary =>
      _isDark ? const Color(0xFF2B2200) : const Color(0xFFFFFFFF);
  static Color get onSecondaryContainer =>
      _isDark ? const Color(0xFFFFE89B) : const Color(0xFF6D5500);
  static Color get secondaryFixed =>
      _isDark ? const Color(0xFF4A3D14) : const Color(0xFFFFE08F);
  static Color get secondaryFixedDim =>
      _isDark ? const Color(0xFFFFD84D) : const Color(0xFFF3C000);

  // Mint / green ------------------------------------------------------------
  static Color get mint =>
      _isDark ? const Color(0xFF63E9C1) : const Color(0xFF4DDFB0);
  static Color get mintDark =>
      _isDark ? const Color(0xFF8CF5D4) : const Color(0xFF00795B);
  static Color get mintSoft =>
      _isDark ? const Color(0xFF153D34) : const Color(0xFFE2FBF1);
  static Color get tertiary =>
      _isDark ? const Color(0xFF63E9C1) : const Color(0xFF006C46);
  static Color get tertiaryContainer =>
      _isDark ? const Color(0xFF1C5548) : const Color(0xFF00B276);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static Color get onTertiaryContainer =>
      _isDark ? const Color(0xFFBCFFE8) : const Color(0xFF003C25);
  static Color get tertiaryFixed =>
      _isDark ? const Color(0xFF8CF5D4) : const Color(0xFF4DFFB2);

  // Pink / red --------------------------------------------------------------
  static Color get pink =>
      _isDark ? const Color(0xFFFF86B3) : const Color(0xFFFF4D8D);
  static Color get pinkDark =>
      _isDark ? const Color(0xFFFFB4CE) : const Color(0xFFC81E62);
  static Color get pinkSoft =>
      _isDark ? const Color(0xFF412436) : const Color(0xFFFFE8F1);
  static Color get error =>
      _isDark ? const Color(0xFFFF7373) : const Color(0xFFBA1A1A);
  static Color get errorDark =>
      _isDark ? const Color(0xFFFFB6B6) : const Color(0xFF93000A);
  static Color get errorSoft =>
      _isDark ? const Color(0xFF3F252C) : const Color(0xFFFFDAD6);
  static Color get errorContainer =>
      _isDark ? const Color(0xFF3F252C) : const Color(0xFFFFDAD6);

  // Purple ------------------------------------------------------------------
  static Color get purple =>
      _isDark ? const Color(0xFFBE93FF) : const Color(0xFF8C45FF);
  static Color get purpleDark =>
      _isDark ? const Color(0xFFD9BCFF) : const Color(0xFF5B21B6);
  static Color get purpleSoft =>
      _isDark ? const Color(0xFF30254D) : const Color(0xFFF2E9FF);

  // Support aliases ---------------------------------------------------------
  static Color get accent =>
      _isDark ? const Color(0xFF55E9C5) : const Color(0xFF00B894);
  static Color get accentLight =>
      _isDark ? const Color(0xFF8CF5D4) : const Color(0xFF55EFC4);
  static Color get correct =>
      _isDark ? const Color(0xFF63E9C1) : const Color(0xFF00B276);
  static Color get wrong =>
      _isDark ? const Color(0xFFFF7373) : const Color(0xFFBA1A1A);
  static Color get warning =>
      _isDark ? const Color(0xFFFFD84D) : const Color(0xFFF3C000);
  static Color get info =>
      _isDark ? const Color(0xFF8AD8FF) : const Color(0xFF00629D);
  static Color get systemMessage =>
      _isDark ? const Color(0xFFB9C5E2) : const Color(0xFF636E72);
  static Color get correctGuessMsg =>
      _isDark ? const Color(0xFF63E9C1) : const Color(0xFF00B894);
  static Color get closeGuessMsg =>
      _isDark ? const Color(0xFFFFD84D) : const Color(0xFFFDCB6E);

  static Color get bgLight =>
      _isDark ? const Color(0xFF11182E) : const Color(0xFFF6FAFF);
  static const Color bgDark = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF16213E);
  static Color get surfaceContainerLow =>
      _isDark ? const Color(0xFF1B2339) : const Color(0xFFEDF4FC);
  static Color get surfaceContainer =>
      _isDark ? const Color(0xFF232C48) : const Color(0xFFE8EFF7);
  static Color get surfaceContainerHigh =>
      _isDark ? const Color(0xFF2A3452) : const Color(0xFFE2E9F1);
  static Color get surfaceContainerHighest =>
      _isDark ? const Color(0xFF323D5E) : const Color(0xFFDCE3EB);
  static Color get surfaceContainerLowest =>
      _isDark ? const Color(0xFF151C31) : const Color(0xFFFFFFFF);
  static Color get canvasBg =>
      _isDark ? const Color(0xFF1E2740) : const Color(0xFFFFFFFF);
  static Color get canvasBorder =>
      _isDark ? const Color(0xFF46537A) : const Color(0xFFDCE3EB);

  // Gradients ---------------------------------------------------------------
  static List<Color> get skyGradient => _isDark
      ? const [Color(0xFF121A33), Color(0xFF172342), Color(0xFF10172C)]
      : const [Color(0xFFF2F9FF), Color(0xFFE4F1FF), Color(0xFFF9FCFF)];

  static List<Color> get heroGradient => _isDark
      ? const [Color(0xFF1F6E9E), Color(0xFF144E78)]
      : const [Color(0xFF00A2FF), Color(0xFF0062C4)];

  static List<Color> get podiumGradient => _isDark
      ? const [Color(0xFF9A7A12), Color(0xFF7A5E08)]
      : const [Color(0xFFFFE785), Color(0xFFFFC400)];

  /// Emoji avatar background colours. The server stores a hex string so the
  /// palette can evolve without a schema change.
  static const Map<String, Color> _avatarPalette = {
    '#00A2FF': Color(0xFF00A2FF),
    '#FF3D8B': Color(0xFFFF3D8B),
    '#00B276': Color(0xFF00B276),
    '#8C45FF': Color(0xFF8C45FF),
    '#FFCA00': Color(0xFFFFCA00),
    '#FF7A00': Color(0xFFFF7A00),
    '#00C2C7': Color(0xFF00C2C7),
    '#F05A5A': Color(0xFFF05A5A),
    '#5B7CFA': Color(0xFF5B7CFA),
    '#B05CFF': Color(0xFFB05CFF),
    '#2BB673': Color(0xFF2BB673),
    '#FF9F1C': Color(0xFFFF9F1C),
  };

  static Color forAvatar(String hex) {
    final normalized = hex.trim().toUpperCase();
    return _avatarPalette[normalized] ?? primaryLight;
  }
}
