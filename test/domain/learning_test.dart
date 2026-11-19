import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/domain/game/achievement_rules.dart';
import 'package:sketch_rush/app/domain/learning/mastery.dart';
import 'package:sketch_rush/app/domain/models/math_models.dart';

void main() {
  group('MasteryModel', () {
    test('one correct answer does not unlock mastery', () {
      final snapshot = MasteryModel.recordAnswer(
        attempts: 0,
        correct: 0,
        consecutiveCorrect: 0,
        isCorrect: true,
      );
      expect(snapshot.mastery, MasteryLevel.learning);
      expect(snapshot.progress, lessThan(0.5));
    });

    test('sustained accuracy progresses through levels', () {
      final practicing = MasteryModel.levelFor(
        attempts: 6,
        correct: 4,
        consecutiveCorrect: 2,
      );
      expect(practicing, MasteryLevel.practicing);

      final proficient = MasteryModel.levelFor(
        attempts: 10,
        correct: 8,
        consecutiveCorrect: 3,
      );
      expect(proficient, MasteryLevel.proficient);

      final mastered = MasteryModel.levelFor(
        attempts: 16,
        correct: 14,
        consecutiveCorrect: 5,
      );
      expect(mastered, MasteryLevel.mastered);
    });

    test('a wrong answer resets the consecutive streak', () {
      final snapshot = MasteryModel.recordAnswer(
        attempts: 9,
        correct: 8,
        consecutiveCorrect: 4,
        isCorrect: false,
      );
      expect(snapshot.consecutiveCorrect, 0);
      expect(snapshot.correct, 8);
      expect(snapshot.attempts, 10);
    });

    test('recommends the weakest started topic', () {
      final topic = MasteryModel.recommendTopic(
        progress: [
          (
            topic: MathTopic.addition,
            mastery: MasteryLevel.proficient,
            accuracy: 0.9,
          ),
          (
            topic: MathTopic.fractions,
            mastery: MasteryLevel.learning,
            accuracy: 0.4,
          ),
          (
            topic: MathTopic.geometry,
            mastery: MasteryLevel.practicing,
            accuracy: 0.6,
          ),
        ],
        fallback: MathTopic.mixed,
      );
      expect(topic, MathTopic.fractions);
    });

    test('falls back to a friendly topic with no history', () {
      expect(
        MasteryModel.recommendTopic(progress: const [], fallback: MathTopic.mixed),
        MathTopic.mixed,
      );
    });
  });

  group('AchievementRules', () {
    test('first match unlocks after one game', () {
      final unlocked = AchievementRules.evaluate(
        const AchievementStats(
          gamesPlayed: 1,
          perfectMatches: 0,
          speedBonuses: 0,
          practiceAnswers: 0,
          practiceTopics: 0,
          practiceDays: 0,
          masteredSkills: 0,
          bestWinStreak: 0,
          level: 1,
          bestMatchAccuracy: 0.2,
        ),
      );
      expect(unlocked, contains('first_match'));
      expect(unlocked, isNot(contains('perfect_match')));
    });

    test('multiple achievements can unlock together', () {
      final unlocked = AchievementRules.evaluate(
        const AchievementStats(
          gamesPlayed: 10,
          perfectMatches: 1,
          speedBonuses: 4,
          practiceAnswers: 12,
          practiceTopics: 3,
          practiceDays: 4,
          masteredSkills: 1,
          bestWinStreak: 5,
          level: 5,
          bestMatchAccuracy: 1,
        ),
      );
      expect(
        unlocked,
        containsAll([
          'first_match',
          'perfect_match',
          'accuracy_star',
          'speed_champion',
          'math_explorer',
          'consistent_learner',
          'skill_master',
          'five_streak',
          'practice_10',
          'level_5',
        ]),
      );
    });

    test('achievement definitions are unique and complete', () {
      final codes =
          AchievementRules.definitions.map((d) => d.code).toSet();
      expect(codes, hasLength(AchievementRules.definitions.length));
      expect(codes, hasLength(10));
      for (final definition in AchievementRules.definitions) {
        expect(definition.xp, greaterThan(0));
        expect(definition.title, isNotEmpty);
        expect(definition.description, isNotEmpty);
      }
    });
  });
}
