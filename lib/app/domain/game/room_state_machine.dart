import '../models/math_models.dart';

/// Explicit room/match lifecycle. The server remains the only authority that
/// performs transitions; this class documents and tests the rules.
class RoomStateMachine {
  RoomStateMachine._();

  static const Map<RoomPhase, Set<RoomPhase>> allowedTransitions = {
    RoomPhase.waiting: {
      RoomPhase.countdown,
      RoomPhase.abandoned,
      RoomPhase.completed,
    },
    RoomPhase.countdown: {
      RoomPhase.questionActive,
      RoomPhase.waiting,
      RoomPhase.abandoned,
    },
    RoomPhase.questionActive: {
      RoomPhase.questionReveal,
      RoomPhase.abandoned,
    },
    RoomPhase.questionReveal: {
      RoomPhase.nextQuestion,
      RoomPhase.finalResults,
      RoomPhase.abandoned,
    },
    RoomPhase.nextQuestion: {
      RoomPhase.questionActive,
      RoomPhase.abandoned,
    },
    RoomPhase.finalResults: {
      RoomPhase.waiting,
      RoomPhase.completed,
    },
    RoomPhase.completed: {RoomPhase.waiting},
    RoomPhase.abandoned: {},
  };

  static bool canTransition(RoomPhase from, RoomPhase to) {
    if (from == to) return true;
    return allowedTransitions[from]?.contains(to) ?? false;
  }

  static void assertTransition(RoomPhase from, RoomPhase to) {
    if (!canTransition(from, to)) {
      throw StateError('Invalid room transition: ${from.dbValue} -> ${to.dbValue}');
    }
  }

  /// A room accepts new players only while waiting. Reconnecting participants
  /// of the current match are handled separately by the server.
  static bool acceptsNewPlayers(RoomPhase phase) => phase == RoomPhase.waiting;

  static bool canStart(RoomPhase phase, int activePlayers) {
    return phase == RoomPhase.waiting && activePlayers >= 2;
  }

  static RoomPhase phaseForMatch(RoomPhase roomPhase) {
    return switch (roomPhase) {
      RoomPhase.waiting => RoomPhase.waiting,
      RoomPhase.countdown => RoomPhase.countdown,
      RoomPhase.questionActive => RoomPhase.questionActive,
      RoomPhase.questionReveal => RoomPhase.questionReveal,
      RoomPhase.nextQuestion => RoomPhase.nextQuestion,
      RoomPhase.finalResults => RoomPhase.finalResults,
      RoomPhase.completed => RoomPhase.finalResults,
      RoomPhase.abandoned => RoomPhase.abandoned,
    };
  }
}
