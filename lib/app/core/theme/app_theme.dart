import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => build(dark: false);

  static ThemeData get darkTheme => build(dark: true);

  static ThemeData build({required bool dark}) {
    AppColors.setDarkMode(dark);
    final brightness = dark ? Brightness.dark : Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: dark
          ? ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.onAccent,
              primaryContainer: AppColors.primarySoft,
              onPrimaryContainer: AppColors.ink,
              secondary: AppColors.yellow,
              onSecondary: AppColors.onSecondary,
              secondaryContainer: AppColors.yellowSoft,
              onSecondaryContainer: AppColors.ink,
              tertiary: AppColors.mint,
              onTertiary: AppColors.onSecondary,
              tertiaryContainer: AppColors.mintSoft,
              onTertiaryContainer: AppColors.ink,
              error: AppColors.error,
              onError: Colors.white,
              errorContainer: AppColors.errorSoft,
              onErrorContainer: AppColors.errorDark,
              surface: AppColors.surface,
              onSurface: AppColors.ink,
              onSurfaceVariant: AppColors.inkSoft,
              outline: AppColors.outline,
            )
          : const ColorScheme.light(
              primary: Color(0xFF00629D),
              onPrimary: Colors.white,
              primaryContainer: Color(0xFFE3F2FF),
              onPrimaryContainer: Color(0xFF151C22),
              secondary: Color(0xFFFFCA00),
              onSecondary: Color(0xFF151C22),
              secondaryContainer: Color(0xFFFFF6DC),
              onSecondaryContainer: Color(0xFF151C22),
              tertiary: Color(0xFF4DDFB0),
              onTertiary: Color(0xFF151C22),
              tertiaryContainer: Color(0xFFE2FBF1),
              onTertiaryContainer: Color(0xFF151C22),
              error: Color(0xFFBA1A1A),
              onError: Colors.white,
              errorContainer: Color(0xFFFFDAD6),
              onErrorContainer: Color(0xFF93000A),
              surface: Color(0xFFFFFFFF),
              onSurface: Color(0xFF151C22),
              onSurfaceVariant: Color(0xFF5B6672),
              outline: Color(0xFFBEC7D4),
            ),
      scaffoldBackgroundColor: AppColors.canvas,
    );

    final body = GoogleFonts.nunitoSansTextTheme(base.textTheme);
    final textTheme = body.copyWith(
      displayLarge: GoogleFonts.rubik(
        fontSize: 52,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
        height: 1.05,
      ),
      displayMedium: GoogleFonts.rubik(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
        height: 1.08,
      ),
      displaySmall: GoogleFonts.rubik(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1.12,
      ),
      headlineLarge: GoogleFonts.rubik(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1.15,
      ),
      headlineMedium: GoogleFonts.rubik(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1.2,
      ),
      headlineSmall: GoogleFonts.rubik(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        height: 1.25,
      ),
      titleLarge: GoogleFonts.rubik(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleMedium: GoogleFonts.rubik(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleSmall: GoogleFonts.rubik(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: GoogleFonts.nunitoSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.inkSoft,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.rubik(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.rubik(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      labelSmall: GoogleFonts.rubik(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.inkSoft,
        letterSpacing: 0.6,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: textTheme.headlineSmall,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: AppColors.outline, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
        border: _inputBorder(AppColors.outline),
        enabledBorder: _inputBorder(AppColors.outline),
        focusedBorder: _inputBorder(AppColors.primary, width: 3),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: dark ? AppColors.onAccent : Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: AppColors.outline, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? AppColors.surfaceContainerHighest
            : AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: dark ? AppColors.ink : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.all(16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outline,
        thickness: 1.5,
        space: 24,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceSoft,
        selectedColor: AppColors.primarySoft,
        side: BorderSide(color: AppColors.outline, width: 1.5),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySoft,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
