import '../models/math_models.dart';

class MasterySnapshot {
  const MasterySnapshot({
    required this.attempts,
    required this.correct,
    required this.consecutiveCorrect,
    required this.mastery,
    required this.accuracy,
  });

  final int attempts;
  final int correct;
  final int consecutiveCorrect;
  final MasteryLevel mastery;
  final double accuracy;

  double get progress {
    return switch (mastery) {
      MasteryLevel.notStarted => 0,
      MasteryLevel.learning => 0.25,
      MasteryLevel.practicing => 0.5,
      MasteryLevel.proficient => 0.75,
      MasteryLevel.mastered => 1,
    };
  }
}

/// Evidence-based mastery. One correct answer never unlocks mastery: children
/// need repeated, consistent success across sessions.
class MasteryModel {
  MasteryModel._();

  static MasteryLevel levelFor({
    required int attempts,
    required int correct,
    required int consecutiveCorrect,
  }) {
    if (attempts <= 0) return MasteryLevel.notStarted;

    final accuracy = correct / attempts;

    if (attempts >= 15 && accuracy >= 0.85 && consecutiveCorrect >= 5) {
      return MasteryLevel.mastered;
    }
    if (attempts >= 10 && accuracy >= 0.75) {
      return MasteryLevel.proficient;
    }
    if (attempts >= 5 && accuracy >= 0.6) {
      return MasteryLevel.practicing;
    }
    return MasteryLevel.learning;
  }

  static MasterySnapshot recordAnswer({
    required int attempts,
    required int correct,
    required int consecutiveCorrect,
    required bool isCorrect,
  }) {
    final nextAttempts = attempts + 1;
    final nextCorrect = correct + (isCorrect ? 1 : 0);
    final nextConsecutive = isCorrect ? consecutiveCorrect + 1 : 0;
    return MasterySnapshot(
      attempts: nextAttempts,
      correct: nextCorrect,
      consecutiveCorrect: nextConsecutive,
      mastery: levelFor(
        attempts: nextAttempts,
        correct: nextCorrect,
        consecutiveCorrect: nextConsecutive,
      ),
      accuracy: nextCorrect / nextAttempts,
    );
  }

  /// Recommends the weakest started skill, otherwise a friendly next topic.
  static MathTopic recommendTopic({
    required List<({MathTopic topic, MasteryLevel mastery, double accuracy})>
        progress,
    required MathTopic fallback,
  }) {
    if (progress.isEmpty) return fallback;
    final sorted = [...progress]
      ..sort((a, b) {
        final byMastery = a.mastery.order.compareTo(b.mastery.order);
        if (byMastery != 0) return byMastery;
        return a.accuracy.compareTo(b.accuracy);
      });
    return sorted.first.topic;
  }
}
