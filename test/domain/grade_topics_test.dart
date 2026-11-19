import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/domain/models/math_models.dart';

void main() {
  test('Kindergarten topics match the early-years objectives', () {
    final topics = GradeLevel.kindergarten.topics;
    expect(
      topics,
      containsAll([
        MathTopic.mixed,
        MathTopic.addition,
        MathTopic.subtraction,
        MathTopic.geometry,
      ]),
    );
    expect(topics, isNot(contains(MathTopic.multiplication)));
    expect(topics, isNot(contains(MathTopic.division)));
    expect(topics, isNot(contains(MathTopic.fractions)));
    expect(topics, isNot(contains(MathTopic.placeValue)));
  });

  test(
    'Grade 1 and 2 add place value, measurement and Grade 2 multiplication',
    () {
      expect(
        GradeLevel.grade1.topics,
        containsAll([
          MathTopic.placeValue,
          MathTopic.measurement,
          MathTopic.mixed,
        ]),
      );
      expect(
        GradeLevel.grade2.topics,
        containsAll([
          MathTopic.multiplication,
          MathTopic.placeValue,
          MathTopic.measurement,
        ]),
      );
      expect(GradeLevel.grade2.topics, isNot(contains(MathTopic.fractions)));
    },
  );

  test(
    'Grade 3 adds division and fractions, and Grades 4-5 cover everything',
    () {
      expect(
        GradeLevel.grade3.topics,
        containsAll([
          MathTopic.multiplication,
          MathTopic.division,
          MathTopic.fractions,
          MathTopic.geometry,
        ]),
      );
      expect(GradeLevel.grade3.topics, isNot(contains(MathTopic.placeValue)));
      expect(GradeLevel.grade4.topics.toSet(), MathTopic.values.toSet());
      expect(GradeLevel.grade5.topics.toSet(), MathTopic.values.toSet());
    },
  );
}
