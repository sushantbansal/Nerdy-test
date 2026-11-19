import '../models/math_models.dart';

/// Authoritative scoring rules mirrored by the database implementation.
///
/// Competitive scoring is intentionally tiny and deterministic:
/// * +1 for a correct answer
/// * +1 speed bonus for the single fastest correct answer
/// * 0 for incorrect, late, or missing answers
/// * A timestamp tie at the fastest position withholds the speed bonus.
class MathScoring {
  MathScoring._();

  static const int correctPoints = 1;
  static const int speedBonusPoints = 1;
  static const int maxPointsPerQuestion = correctPoints + speedBonusPoints;

  static QuestionScoreResult scoreQuestion(List<AnswerRecord> answers) {
    final points = <String, int>{
      for (final answer in answers) answer.playerId: 0,
    };

    final correctAnswers = answers.where((answer) => answer.isCorrect).toList()
      ..sort((a, b) {
        final byTime = a.submittedAt.compareTo(b.submittedAt);
        if (byTime != 0) return byTime;
        return a.playerId.compareTo(b.playerId);
      });

    for (final answer in correctAnswers) {
      points[answer.playerId] = correctPoints;
    }

    if (correctAnswers.isEmpty) {
      return QuestionScoreResult(
        pointsByPlayer: points,
        speedBonusPlayerId: null,
        fastestCorrectPlayerId: null,
        speedBonusWithheldForTie: false,
      );
    }

    final fastest = correctAnswers.first;
    final tiedAtFastest = correctAnswers
        .where((answer) => answer.submittedAt.isAtSameMomentAs(fastest.submittedAt))
        .toList();

    // Different players submitting in the same microsecond is treated as a
    // tie; withholding the bonus avoids rewarding clock resolution.
    if (tiedAtFastest.length > 1) {
      return QuestionScoreResult(
        pointsByPlayer: points,
        speedBonusPlayerId: null,
        fastestCorrectPlayerId: null,
        speedBonusWithheldForTie: true,
      );
    }

    points[fastest.playerId] = correctPoints + speedBonusPoints;

    return QuestionScoreResult(
      pointsByPlayer: points,
      speedBonusPlayerId: fastest.playerId,
      fastestCorrectPlayerId: fastest.playerId,
      speedBonusWithheldForTie: false,
    );
  }

  /// Ranks players using the documented tie-break policy:
  /// 1. highest total points
  /// 2. highest correct-answer count
  /// 3. lowest total response time across correct answers
  /// 4. otherwise a draw
  static List<PlayerRanking> rankPlayers(List<PlayerStanding> standings) {
    if (standings.isEmpty) return const [];

    final sorted = [...standings]..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) return byPoints;

        final byCorrect = b.correctCount.compareTo(a.correctCount);
        if (byCorrect != 0) return byCorrect;

        final byTime = a.correctResponseMs.compareTo(b.correctResponseMs);
        if (byTime != 0) return byTime;

        return a.playerId.compareTo(b.playerId);
      });

    final rankings = <PlayerRanking>[];
    var index = 0;

    while (index < sorted.length) {
      final current = sorted[index];
      var end = index + 1;
      while (end < sorted.length &&
          _sameKey(
            current,
            sorted[end],
          )) {
        end++;
      }

      final tiedCount = end - index;
      final rank = index + 1;

      for (var i = index; i < end; i++) {
        final standing = sorted[i];
        final outcome = rank == 1
            ? (tiedCount > 1 ? MatchOutcome.draw : MatchOutcome.win)
            : MatchOutcome.loss;

        rankings.add(
          PlayerRanking(
            playerId: standing.playerId,
            rank: rank,
            outcome: outcome,
            points: standing.points,
            correctCount: standing.correctCount,
            correctResponseMs: standing.correctResponseMs,
            isTied: tiedCount > 1,
          ),
        );
      }

      index = end;
    }

    return rankings;
  }

  static bool _sameKey(PlayerStanding a, PlayerStanding b) {
    return a.points == b.points &&
        a.correctCount == b.correctCount &&
        a.correctResponseMs == b.correctResponseMs;
  }

  static double accuracyPercent({
    required int correct,
    required int incorrect,
  }) {
    final answered = correct + incorrect;
    if (answered <= 0) return 0;
    return (correct / answered) * 100;
  }

  static int levelForXp(int xp) {
    if (xp < 0) return 1;
    return 1 + (xp ~/ 250);
  }

  static int xpToNextLevel(int xp) {
    final level = levelForXp(xp);
    return (level * 250) - xp;
  }
}
