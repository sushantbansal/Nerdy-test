import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/domain/game/room_state_machine.dart';
import 'package:sketch_rush/app/domain/models/math_models.dart';

void main() {
  group('RoomStateMachine', () {
    test('waiting rooms can start a countdown', () {
      expect(
        RoomStateMachine.canTransition(
          RoomPhase.waiting,
          RoomPhase.countdown,
        ),
        isTrue,
      );
      expect(
        RoomStateMachine.canStart(RoomPhase.waiting, 1),
        isFalse,
      );
      expect(
        RoomStateMachine.canStart(RoomPhase.waiting, 2),
        isTrue,
      );
    });

    test('questions alternate active and reveal', () {
      expect(
        RoomStateMachine.canTransition(
          RoomPhase.countdown,
          RoomPhase.questionActive,
        ),
        isTrue,
      );
      expect(
        RoomStateMachine.canTransition(
          RoomPhase.questionActive,
          RoomPhase.questionReveal,
        ),
        isTrue,
      );
      expect(
        RoomStateMachine.canTransition(
          RoomPhase.questionReveal,
          RoomPhase.nextQuestion,
        ),
        isTrue,
      );
      expect(
        RoomStateMachine.canTransition(
          RoomPhase.nextQuestion,
          RoomPhase.questionActive,
        ),
        isTrue,
      );
    });

    test('active questions cannot be skipped backwards', () {
      expect(
        RoomStateMachine.canTransition(
          RoomPhase.questionActive,
          RoomPhase.countdown,
        ),
        isFalse,
      );
      expect(
        RoomStateMachine.canTransition(
          RoomPhase.questionReveal,
          RoomPhase.questionActive,
        ),
        isFalse,
      );
      expect(
        () => RoomStateMachine.assertTransition(
          RoomPhase.questionActive,
          RoomPhase.waiting,
        ),
        throwsStateError,
      );
    });

    test('final results can restart or complete', () {
      expect(
        RoomStateMachine.canTransition(
          RoomPhase.finalResults,
          RoomPhase.waiting,
        ),
        isTrue,
      );
      expect(
        RoomStateMachine.canTransition(
          RoomPhase.finalResults,
          RoomPhase.completed,
        ),
        isTrue,
      );
      expect(RoomStateMachine.acceptsNewPlayers(RoomPhase.waiting), isTrue);
      expect(
        RoomStateMachine.acceptsNewPlayers(RoomPhase.questionActive),
        isFalse,
      );
    });

    test('completed room phase maps to final results UI', () {
      expect(
        RoomStateMachine.phaseForMatch(RoomPhase.completed),
        RoomPhase.finalResults,
      );
    });
  });
}
