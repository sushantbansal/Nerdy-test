import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/core/widgets/answer_option_card.dart';

void main() {
  testWidgets('renders the answer letter, text and semantics label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnswerOptionCard(answer: '12', index: 1)),
      ),
    );

    expect(find.text('B'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Answer B: 12')), findsOneWidget);
  });

  testWidgets('tapping an enabled answer calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerOptionCard(answer: '7', index: 0, onTap: () => taps++),
        ),
      ),
    );

    await tester.tap(find.byType(AnswerOptionCard));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('disabled answers ignore taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerOptionCard(
            answer: '7',
            index: 0,
            disabled: true,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AnswerOptionCard));
    await tester.pumpAndSettle();

    expect(taps, 0);
  });

  testWidgets('correct state displays a check mark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnswerOptionCard(
            answer: '9',
            index: 3,
            state: AnswerOptionState.correct,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('D'), findsNothing);
  });

  testWidgets('incorrect state displays a close mark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnswerOptionCard(
            answer: '9',
            index: 2,
            state: AnswerOptionState.incorrect,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('can be activated from the keyboard', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerOptionCard(answer: '7', index: 0, onTap: () => taps++),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
