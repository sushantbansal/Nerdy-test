import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch_rush/app/core/theme/app_theme.dart';
import 'package:sketch_rush/app/services/theme_service.dart';

void main() {
  setUp(() async {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    final themeService = await ThemeService.load();
    Get.put(themeService, permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('GetMaterialApp switches theme immediately', (tester) async {
    final themeService = Get.find<ThemeService>();
    await tester.pumpWidget(
      Obx(
        () => GetMaterialApp(
          theme: AppTheme.build(dark: themeService.isDark.value),
          darkTheme: AppTheme.build(dark: themeService.isDark.value),
          themeMode: ThemeMode.light,
          home: Builder(
            builder: (context) => Text(
              Theme.of(context).brightness == Brightness.dark
                  ? 'dark theme'
                  : 'light theme',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('light theme'), findsOneWidget);

    await themeService.setDark(true);
    await tester.pumpAndSettle();

    expect(find.text('dark theme'), findsOneWidget);
  });
}
