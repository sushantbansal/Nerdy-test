import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/domain/game/scoring.dart';
import 'package:sketch_rush/app/domain/models/math_models.dart';

void main() {
  group('MathScoring.scoreQuestion', () {
    final base = DateTime.utc(2026, 1, 1, 12);

    test('correct answer earns one point', () {
      final result = MathScoring.scoreQuestion([
        AnswerRecord(
          playerId: 'a',
          isCorrect: true,
          submittedAt: base,
          responseMs: 2000,
        ),
      ]);
      expect(result.pointsByPlayer['a'], 2);
      expect(result.speedBonusPlayerId, 'a');
    });

    test('incorrect answer earns zero and cannot win speed bonus', () {
      final result = MathScoring.scoreQuestion([
        AnswerRecord(
          playerId: 'a',
          isCorrect: false,
          submittedAt: base,
          responseMs: 1000,
        ),
        AnswerRecord(
          playerId: 'b',
          isCorrect: true,
          submittedAt: base.add(const Duration(seconds: 3)),
          responseMs: 3000,
        ),
      ]);
      expect(result.pointsByPlayer['a'], 0);
      expect(result.pointsByPlayer['b'], 2);
      expect(result.speedBonusPlayerId, 'b');
    });

    test('only the fastest correct answer earns the bonus', () {
      final result = MathScoring.scoreQuestion([
        AnswerRecord(
          playerId: 'slow',
          isCorrect: true,
          submittedAt: base.add(const Duration(seconds: 5)),
          responseMs: 5000,
        ),
        AnswerRecord(
          playerId: 'fast',
          isCorrect: true,
          submittedAt: base.add(const Duration(seconds: 1)),
          responseMs: 1000,
        ),
      ]);
      expect(result.pointsByPlayer['fast'], 2);
      expect(result.pointsByPlayer['slow'], 1);
      expect(result.speedBonusPlayerId, 'fast');
    });

    test('a tie at the fastest timestamp withholds the speed bonus', () {
      final result = MathScoring.scoreQuestion([
        AnswerRecord(
          playerId: 'a',
          isCorrect: true,
          submittedAt: base,
          responseMs: 1000,
        ),
        AnswerRecord(
          playerId: 'b',
          isCorrect: true,
          submittedAt: base,
          responseMs: 1000,
        ),
      ]);
      expect(result.pointsByPlayer['a'], 1);
      expect(result.pointsByPlayer['b'], 1);
      expect(result.speedBonusPlayerId, isNull);
      expect(result.speedBonusWithheldForTie, isTrue);
    });

    test('no correct answers means no bonus', () {
      final result = MathScoring.scoreQuestion([
        AnswerRecord(
          playerId: 'a',
          isCorrect: false,
          submittedAt: base,
          responseMs: 1000,
        ),
      ]);
      expect(result.speedBonusPlayerId, isNull);
      expect(result.pointsByPlayer['a'], 0);
    });
  });

  group('MathScoring.rankPlayers', () {
    test('ranks by points, then correct answers, then response time', () {
      final rankings = MathScoring.rankPlayers(const [
        PlayerStanding(
          playerId: 'a',
          points: 8,
          correctCount: 5,
          correctResponseMs: 10000,
        ),
        PlayerStanding(
          playerId: 'b',
          points: 8,
          correctCount: 4,
          correctResponseMs: 5000,
        ),
        PlayerStanding(
          playerId: 'c',
          points: 8,
          correctCount: 4,
          correctResponseMs: 4000,
        ),
      ]);
      expect(rankings.first.playerId, 'a');
      expect(rankings[1].playerId, 'c');
      expect(rankings[2].playerId, 'b');
      expect(rankings.first.outcome, MatchOutcome.win);
      expect(rankings.last.outcome, MatchOutcome.loss);
    });

    test('identical records produce a draw and shared rank', () {
      final rankings = MathScoring.rankPlayers(const [
        PlayerStanding(
          playerId: 'a',
          points: 7,
          correctCount: 4,
          correctResponseMs: 12000,
        ),
        PlayerStanding(
          playerId: 'b',
          points: 7,
          correctCount: 4,
          correctResponseMs: 12000,
        ),
      ]);
      expect(rankings.every((r) => r.rank == 1), isTrue);
      expect(rankings.every((r) => r.outcome == MatchOutcome.draw), isTrue);
    });

    test('lower-ranked players lose even when top players draw', () {
      final rankings = MathScoring.rankPlayers(const [
        PlayerStanding(
          playerId: 'a',
          points: 6,
          correctCount: 3,
          correctResponseMs: 9000,
        ),
        PlayerStanding(
          playerId: 'b',
          points: 6,
          correctCount: 3,
          correctResponseMs: 9000,
        ),
        PlayerStanding(
          playerId: 'c',
          points: 4,
          correctCount: 2,
          correctResponseMs: 7000,
        ),
      ]);
      expect(rankings[0].outcome, MatchOutcome.draw);
      expect(rankings[1].outcome, MatchOutcome.draw);
      expect(rankings[2].rank, 3);
      expect(rankings[2].outcome, MatchOutcome.loss);
    });

    test('empty standings return empty rankings', () {
      expect(MathScoring.rankPlayers(const []), isEmpty);
    });
  });

  group('derived statistics', () {
    test('accuracy ignores unanswered questions', () {
      expect(
        MathScoring.accuracyPercent(correct: 8, incorrect: 2),
        80,
      );
      expect(
        MathScoring.accuracyPercent(correct: 0, incorrect: 0),
        0,
      );
    });

    test('level increases every 250 XP', () {
      expect(MathScoring.levelForXp(0), 1);
      expect(MathScoring.levelForXp(249), 1);
      expect(MathScoring.levelForXp(250), 2);
      expect(MathScoring.levelForXp(1250), 6);
      expect(MathScoring.xpToNextLevel(240), 10);
    });
  });
}
