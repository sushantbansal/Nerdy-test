import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/core/widgets/countdown_ring.dart';
import 'package:sketch_rush/app/core/widgets/math_visual.dart';
import 'package:sketch_rush/app/core/widgets/selectors.dart';
import 'package:sketch_rush/app/domain/models/math_models.dart';

void main() {
  group('GradePicker', () {
    testWidgets('reports the tapped grade', (tester) async {
      GradeLevel? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradePicker(
              value: GradeLevel.grade1,
              onChanged: (grade) => selected = grade,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButton<GradeLevel>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grade 4').last);
      await tester.pumpAndSettle();

      expect(selected, GradeLevel.grade4);
    });

    testWidgets('renders every K-5 option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradePicker(
              value: GradeLevel.kindergarten,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButton<GradeLevel>));
      await tester.pumpAndSettle();

      for (final grade in GradeLevel.values) {
        expect(find.text(grade.label), findsWidgets);
      }
    });
  });

  group('TopicPicker', () {
    testWidgets('adds and removes topics when tapped', (tester) async {
      var selected = <MathTopic>{MathTopic.addition, MathTopic.subtraction};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TopicPicker(
                selected: selected,
                onChanged: (next) => setState(() => selected = next),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Addition'));
      await tester.pumpAndSettle();
      expect(selected, {MathTopic.subtraction});

      await tester.tap(find.text('Division'));
      await tester.pumpAndSettle();
      expect(
        selected,
        containsAll([MathTopic.subtraction, MathTopic.division]),
      );
    });

    testWidgets('replaces the oldest choice once the cap is reached', (
      tester,
    ) async {
      var selected = <MathTopic>{
        MathTopic.addition,
        MathTopic.subtraction,
        MathTopic.multiplication,
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TopicPicker(
                selected: selected,
                maxSelection: 3,
                onChanged: (next) => setState(() => selected = next),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Division'));
      await tester.pumpAndSettle();

      expect(selected, hasLength(3));
      expect(selected, contains(MathTopic.division));
      expect(selected, isNot(contains(MathTopic.addition)));
    });
  });

  testWidgets('CountdownRing announces the remaining seconds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CountdownRing(
            remaining: Duration(seconds: 7),
            total: Duration(seconds: 18),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp('7 seconds remaining')),
      findsOneWidget,
    );
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('MathVisual renders fraction bars and unknown fallbacks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MathVisual(
                type: 'fraction_bar',
                data: {'numerator': 1, 'denominator': 4},
                height: 120,
              ),
              MathVisual(type: 'not_a_real_visual', data: {}, height: 80),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(MathVisual), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
