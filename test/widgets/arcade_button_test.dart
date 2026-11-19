import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/core/widgets/arcade_button.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('renders its label and fires onPressed', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(ArcadeButton(label: 'Start the clash', onPressed: () => pressed++)),
    );

    expect(find.text('Start the clash'), findsOneWidget);
    await tester.tap(find.byType(ArcadeButton));
    await tester.pumpAndSettle();

    expect(pressed, 1);
  });

  testWidgets('is inert while loading', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        ArcadeButton(
          label: 'Saving',
          loading: true,
          onPressed: () => pressed++,
        ),
      ),
    );

    await tester.tap(find.byType(ArcadeButton));
    await tester.pump(const Duration(milliseconds: 200));

    expect(pressed, 0);
  });

  testWidgets('is inert when disabled', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        ArcadeButton(
          label: 'Waiting for players',
          enabled: false,
          onPressed: () => pressed++,
        ),
      ),
    );

    await tester.tap(find.byType(ArcadeButton));
    await tester.pumpAndSettle();

    expect(pressed, 0);
  });

  testWidgets('expands to fill the available width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: ArcadeButton(
              label: 'Create room',
              expand: true,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(ArcadeButton));
    expect(size.width, closeTo(400, 0.1));
  });
}
