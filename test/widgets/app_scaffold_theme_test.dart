import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/core/theme/app_colors.dart';
import 'package:sketch_rush/app/core/widgets/app_scaffold.dart';

void main() {
  testWidgets(
    'AppScaffold rebuilds AppColors content when brightness changes',
    (tester) async {
      final brightness = ValueNotifier(Brightness.light);
      addTearDown(brightness.dispose);
      addTearDown(() => AppColors.setDarkMode(false));

      await tester.pumpWidget(
        ValueListenableBuilder<Brightness>(
          valueListenable: brightness,
          builder: (context, value, child) {
            AppColors.setDarkMode(value == Brightness.dark);
            return MaterialApp(
              theme: ThemeData(brightness: value),
              home: AppScaffold(
                child: Builder(
                  builder: (context) =>
                      Text(AppColors.isDark ? 'dark colours' : 'light colours'),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('light colours'), findsOneWidget);

      brightness.value = Brightness.dark;
      await tester.pumpAndSettle();

      expect(find.text('dark colours'), findsOneWidget);
    },
  );
}
