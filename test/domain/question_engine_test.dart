import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/domain/models/math_models.dart';
import 'package:sketch_rush/app/domain/questions/question_engine.dart';

void main() {
  group('QuestionEngine', () {
    test('generates valid questions for every grade, topic and difficulty', () {
      var generated = 0;
      for (var grade = 0; grade <= 5; grade++) {
        for (final topic in MathTopic.values) {
          for (final difficulty in [
            MathDifficulty.easy,
            MathDifficulty.medium,
            MathDifficulty.hard,
          ]) {
            for (var seed = 0; seed < 20; seed++) {
              final question = QuestionEngine.generate(
                grade: grade,
                topic: topic,
                difficulty: difficulty,
                seed: seed * 37 + grade * 101 + topic.index * 7,
              );
              generated++;

              expect(question.grade, grade);
              expect(question.topic, topic);
              expect(question.difficulty, difficulty);
              expect(question.text.trim(), isNotEmpty);
              expect(question.explanation.trim(), isNotEmpty);
              expect(question.options, hasLength(4));
              expect(question.options.toSet(), hasLength(4));
              expect(question.options, contains(question.correctAnswer));
              expect(question.skill.trim(), isNotEmpty);
              expect(question.estimatedSeconds, greaterThan(0));
              expect(question.answerType, AnswerType.choice);
            }
          }
        }
      }
      expect(generated, 6 * 9 * 3 * 20);
    });

    test('rejects adaptive difficulty for concrete generation', () {
      expect(
        () => QuestionEngine.generate(
          grade: 2,
          topic: MathTopic.addition,
          difficulty: MathDifficulty.adaptive,
          seed: 1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects grades outside K-5', () {
      expect(
        () => QuestionEngine.generate(
          grade: 6,
          topic: MathTopic.addition,
          difficulty: MathDifficulty.easy,
          seed: 1,
        ),
        throwsArgumentError,
      );
    });

    test('batch generation is de-duplicated and covers all combinations', () {
      final batch = QuestionEngine.generateBatch(count: 2, seedOffset: 9000);
      expect(batch, hasLength(6 * 9 * 3 * 2));
      final keys = batch
          .map(
            (q) =>
                '${q.grade}|${q.topic.dbValue}|${q.difficulty.dbValue}|${q.text}|${q.correctAnswer}',
          )
          .toSet();
      expect(keys, hasLength(batch.length));
    });

    test('kindergarten questions stay friendly and visual where useful', () {
      var visualCount = 0;
      for (var seed = 0; seed < 30; seed++) {
        final question = QuestionEngine.generate(
          grade: 0,
          topic: MathTopic.addition,
          difficulty: MathDifficulty.easy,
          seed: seed,
        );
        if (question.visual != null) visualCount++;
      }
      expect(visualCount, greaterThan(0));
    });

    test('early fractions stay at halves and fourths', () {
      final simpleFractions = {'1/2', '1/4', '2/4', '3/4'};
      for (final grade in [0, 1]) {
        for (final difficulty in [
          MathDifficulty.easy,
          MathDifficulty.medium,
          MathDifficulty.hard,
        ]) {
          for (var seed = 0; seed < 40; seed++) {
            final question = QuestionEngine.generate(
              grade: grade,
              topic: MathTopic.fractions,
              difficulty: difficulty,
              seed: seed * 13 + grade * 101,
            );
            if (question.skill == 'identify_fractions' ||
                question.skill == 'compare_fractions') {
              expect(
                simpleFractions,
                contains(question.correctAnswer),
                reason: '${question.text} -> ${question.correctAnswer}',
              );
            }
            if (question.skill == 'fraction_of_set') {
              final match = RegExp(
                r'What is (\d+)/(\d+) of',
              ).firstMatch(question.text);
              expect(match, isNotNull, reason: question.text);
              final denominator = int.parse(match!.group(2)!);
              expect(denominator, anyOf(2, 4));
            }
          }
        }
      }
    });

    test('every Kindergarten question carries a visual aid', () {
      for (final topic in MathTopic.values) {
        for (final difficulty in [
          MathDifficulty.easy,
          MathDifficulty.medium,
          MathDifficulty.hard,
        ]) {
          for (var seed = 0; seed < 25; seed++) {
            final question = QuestionEngine.generate(
              grade: 0,
              topic: topic,
              difficulty: difficulty,
              seed: seed * 17 + topic.index,
            );
            expect(
              question.visual,
              isNotNull,
              reason:
                  'Kindergarten ${topic.dbValue} question needs a picture: '
                  '${question.text}',
            );
            expect(
              question.options,
              contains(question.correctAnswer),
              reason: question.text,
            );
          }
        }
      }
    });

    test('deterministic output for the same seed', () {
      final first = QuestionEngine.generate(
        grade: 3,
        topic: MathTopic.fractions,
        difficulty: MathDifficulty.medium,
        seed: 42,
      );
      final second = QuestionEngine.generate(
        grade: 3,
        topic: MathTopic.fractions,
        difficulty: MathDifficulty.medium,
        seed: 42,
      );
      expect(first.text, second.text);
      expect(first.options, second.options);
      expect(first.correctAnswer, second.correctAnswer);
    });
  });
}
