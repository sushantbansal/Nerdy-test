import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sketch_rush/app/core/widgets/answer_option_card.dart';
import 'package:sketch_rush/app/data/models/math_api_models.dart';
import 'package:sketch_rush/app/data/providers/auth_provider.dart';
import 'package:sketch_rush/app/data/providers/math_api_provider.dart';
import 'package:sketch_rush/app/domain/models/math_models.dart';
import 'package:sketch_rush/app/modules/practice/practice_controller.dart';
import 'package:sketch_rush/app/modules/practice/practice_view.dart';
import 'package:sketch_rush/app/services/session_service.dart';

class _FakeApi extends MathApiProvider {
  _FakeApi(this.question, this.result);

  final MathPracticeQuestion question;
  final MathPracticeResult result;
  MathTopic? requestedTopic;

  @override
  Future<MathPracticeQuestion> nextPracticeQuestion({
    required GradeLevel grade,
    MathTopic? topic,
  }) async {
    requestedTopic = topic;
    return question;
  }

  @override
  Future<MathPracticeResult> submitPracticeAnswer({
    required String questionId,
    required String answer,
    required String attemptId,
    bool usedHint = false,
    int elapsedMs = 0,
  }) async {
    return result;
  }
}

class _FakeSession extends SessionService {
  _FakeSession({this.testGrade = GradeLevel.kindergarten})
    : super(AuthProvider(), MathApiProvider());

  final GradeLevel testGrade;

  @override
  bool get isKindergarten => testGrade == GradeLevel.kindergarten;

  @override
  bool get reducedMotion => false;

  @override
  bool get soundEnabled => false;

  @override
  GradeLevel get grade => testGrade;

  @override
  Future<MathProfile?> refreshProfile() async => profile.value;
}

void main() {
  const question = MathPracticeQuestion(
    id: 'q1',
    grade: GradeLevel.kindergarten,
    topic: MathTopic.mixed,
    skill: 'counting',
    difficulty: MathDifficulty.easy,
    text: 'How many apples?',
    options: ['2', '3', '4'],
    answerType: AnswerType.choice,
    estimatedSeconds: 10,
    visual: {
      'type': 'objects',
      'data': {
        'emoji': '🍎',
        'groups': [3],
        'operator': '',
      },
    },
  );
  const grade3Question = MathPracticeQuestion(
    id: 'q3',
    grade: GradeLevel.grade3,
    topic: MathTopic.addition,
    skill: 'add_three_digit',
    difficulty: MathDifficulty.medium,
    text: '14 - 6 = ?',
    options: ['6', '7', '8', '9'],
    answerType: AnswerType.choice,
    estimatedSeconds: 15,
  );

  const result = MathPracticeResult(
    isCorrect: false,
    correctAnswer: '3',
    explanation: 'Count one, two, three.',
    xpEarned: 1,
    mastery: MasteryLevel.learning,
    skillAttempts: 1,
    skillCorrect: 0,
    practiceStreak: 1,
    practiceQuestions: 1,
    newAchievements: [],
  );

  test(
    'kindergarten practice waits for the look step before answers',
    () async {
      final api = _FakeApi(question, result);
      final controller = PracticeController(api, _FakeSession())
        ..grade.value = GradeLevel.kindergarten;
      controller.question.value = question;

      expect(controller.showAnswerChoices.value, isFalse);
      expect(controller.lookNarration, contains('big button'));
      controller.beginAnswering();
      expect(controller.showAnswerChoices.value, isTrue);
      expect(controller.questionNarration, contains('Tap or drag'));
    },
  );

  test('a wrong numeric answer invites counting together', () async {
    final api = _FakeApi(question, result);
    final controller = PracticeController(api, _FakeSession())
      ..grade.value = GradeLevel.kindergarten;
    controller.question.value = question;
    controller.beginAnswering();

    await controller.submit('4');

    expect(controller.result.value?.isCorrect, isFalse);
    expect(controller.resultNarration, contains('count together'));
    expect(controller.resultNarration, contains('1, 2, 3'));
  });

  test('older grades can type a numeric answer instead of choosing', () async {
    final api = _FakeApi(grade3Question, result);
    final controller = PracticeController(api, _FakeSession())
      ..grade.value = GradeLevel.grade3;
    controller.question.value = grade3Question;

    expect(controller.supportsTyping, isTrue);
    controller.toggleTyping();
    expect(controller.typingAnswer.value, isTrue);

    controller.typedAnswerController.text = '8';
    await controller.submitTyped();

    expect(controller.result.value, isNotNull);
  });

  test('kindergarten practice rejects older-grade topics', () async {
    final api = _FakeApi(question, result);
    final controller = PracticeController(api, _FakeSession())
      ..grade.value = GradeLevel.kindergarten;
    controller.question.value = question;

    await controller.setTopic(MathTopic.division);

    expect(controller.topic.value, isNull);
    expect(api.requestedTopic, isNull);
  });

  test('trying a similar question keeps the same topic', () async {
    final api = _FakeApi(question, result);
    final controller = PracticeController(api, _FakeSession())
      ..grade.value = GradeLevel.kindergarten;
    controller.question.value = question;
    controller.beginAnswering();

    await controller.trySimilar();

    expect(api.requestedTopic, MathTopic.mixed);
    expect(controller.showAnswerChoices.value, isFalse);
  });

  testWidgets('kindergarten practice shows a picture first, then big choices', (
    tester,
  ) async {
    Get.testMode = true;
    addTearDown(Get.reset);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApi(question, result);
    Get.put(PracticeController(api, _FakeSession()));
    await tester.pumpWidget(const GetMaterialApp(home: PracticeView()));
    await tester.pumpAndSettle();

    expect(find.text('How many apples?'), findsOneWidget);
    expect(find.text('I’m ready'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('I’m ready'));
    await tester.tap(find.text('I’m ready'));
    await tester.pumpAndSettle();

    expect(find.byType(AnswerOptionCard), findsNWidgets(3));
    expect(find.text('4'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('4'));
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    expect(find.textContaining('count together'), findsOneWidget);
    expect(find.text('Try a similar one'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grade 2 uses the picture-first learning flow and can type', (
    tester,
  ) async {
    Get.testMode = true;
    addTearDown(Get.reset);

    final api = _FakeApi(grade3Question, result);
    Get.put(
      PracticeController(api, _FakeSession(testGrade: GradeLevel.grade2)),
    );
    await tester.pumpWidget(const GetMaterialApp(home: PracticeView()));
    await tester.pumpAndSettle();

    expect(find.text('Let’s learn'), findsOneWidget);
    expect(find.text('I’m ready'), findsOneWidget);

    await tester.ensureVisible(find.text('I’m ready'));
    await tester.tap(find.text('I’m ready'));
    await tester.pumpAndSettle();

    expect(find.byType(AnswerOptionCard), findsNWidgets(4));
    expect(find.text('Type the answer instead'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
