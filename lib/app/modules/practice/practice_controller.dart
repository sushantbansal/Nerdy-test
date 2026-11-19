import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/feedback.dart';
import '../../core/utils/ui_feedback.dart';
import '../../core/widgets/answer_option_card.dart';
import '../../data/models/math_api_models.dart';
import '../../data/providers/math_api_provider.dart';
import '../../domain/models/math_models.dart';
import '../../routes/app_routes.dart';
import '../../services/narration_service.dart';
import '../../services/session_service.dart';

/// Adaptive solo practice. Every question and check comes from the server so
/// the answer key never reaches the client before it needs to.
class PracticeController extends GetxController {
  PracticeController(this._api, this._session);

  final MathApiProvider _api;
  final SessionService _session;
  final Uuid _uuid = const Uuid();

  final Rx<MathTopic?> topic = Rx<MathTopic?>(null);
  final Rx<GradeLevel> grade = GradeLevel.grade1.obs;
  final Rxn<MathPracticeQuestion> question = Rxn<MathPracticeQuestion>();
  final Rxn<MathPracticeResult> result = Rxn<MathPracticeResult>();
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool hintVisible = false.obs;
  final RxBool showAnswerChoices = false.obs;
  final RxBool typingAnswer = false.obs;
  final TextEditingController typedAnswerController = TextEditingController();
  final RxString selectedAnswer = ''.obs;
  final RxString error = ''.obs;

  static final RegExp _numericAnswer = RegExp(r'^-?\d+(?:[./]\d+)?$');

  final RxInt correctCount = 0.obs;
  final RxInt answeredCount = 0.obs;
  final RxInt streak = 0.obs;
  final RxInt bestStreak = 0.obs;
  final RxInt xpEarned = 0.obs;

  String attemptId = '';
  DateTime _shownAt = DateTime.now();

  double get accuracy =>
      answeredCount.value == 0 ? 0 : correctCount.value / answeredCount.value;

  bool get hasAnswered => result.value != null;

  bool get isKindergarten => grade.value == GradeLevel.kindergarten;

  bool get isYoungLearner => grade.value.value <= 2;

  List<MathTopic> get availableTopics => grade.value.topics;

  bool get supportsTyping {
    if (grade.value.value < 2) return false;
    final options = question.value?.options ?? const <String>[];
    return options.isNotEmpty &&
        options.every((option) => _numericAnswer.hasMatch(option.trim()));
  }

  bool get reducedMotion => _session.reducedMotion;

  /// Spoken version of the current question. Kindergarten practice reads each
  /// question aloud once, then leaves a visible replay button on screen.
  String? get questionNarration {
    final current = question.value;
    if (current == null) return null;
    return '${NarrationText.question(text: current.text, options: current.options)} Tap or drag the answer when you are ready.';
  }

  /// Narration for the "look and count" step. It skips the multiple-choice
  /// options so a young child can study the picture before answering.
  String? get lookNarration {
    final current = question.value;
    if (current == null) return null;
    return '${NarrationText.question(text: current.text, options: const [])} When you are ready, tap the big button.';
  }

  String? get resultNarration {
    final data = result.value;
    if (data == null) return null;
    if (isKindergarten && !data.isCorrect) {
      final count = _countAloud(data.correctAnswer);
      if (count != null) {
        return 'Good try. Let’s count together. $count '
            'The answer is ${data.correctAnswer}.';
      }
    }
    return NarrationText.feedback(
      correct: data.isCorrect,
      correctAnswer: data.correctAnswer,
      explanation: data.explanation,
    );
  }

  String? _countAloud(String answer) {
    final value = int.tryParse(answer.trim());
    if (value == null || value < 1 || value > 10) return null;
    return List.generate(value, (index) => '${index + 1}').join(', ');
  }

  @override
  void onInit() {
    super.onInit();
    grade.value = _session.grade;
    final argument = Get.arguments;
    if (argument is Map) {
      final passedTopic = argument['topic'];
      final candidate = passedTopic is MathTopic
          ? passedTopic
          : passedTopic is String
          ? MathTopic.fromValue(passedTopic)
          : null;
      if (candidate != null && availableTopics.contains(candidate)) {
        topic.value = candidate;
      }
    }
    loadNext();
  }

  Future<void> setTopic(MathTopic? next) async {
    if (next != null && !availableTopics.contains(next)) return;
    if (topic.value == next) return;
    topic.value = next;
    resetStats();
    await loadNext();
  }

  Future<void> setGrade(GradeLevel next) async {
    if (grade.value == next) return;
    grade.value = next;
    if (topic.value != null && !availableTopics.contains(topic.value)) {
      topic.value = null;
    }
    resetStats();
    await loadNext();
  }

  void resetStats() {
    correctCount.value = 0;
    answeredCount.value = 0;
    streak.value = 0;
    bestStreak.value = 0;
    xpEarned.value = 0;
  }

  Future<void> loadNext() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    result.value = null;
    selectedAnswer.value = '';
    hintVisible.value = false;
    showAnswerChoices.value = false;
    typingAnswer.value = false;
    typedAnswerController.clear();
    attemptId = _uuid.v4();
    try {
      final next = await _api.nextPracticeQuestion(
        grade: grade.value,
        topic: topic.value,
      );
      question.value = next;
      _shownAt = DateTime.now();
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
    } finally {
      isLoading.value = false;
    }
  }

  void revealHint() {
    hintVisible.value = true;
  }

  /// Moves from the picture/counting step to the answer choices.
  void beginAnswering() {
    if (question.value == null || hasAnswered) return;
    showAnswerChoices.value = true;
  }

  void toggleTyping() {
    if (!supportsTyping || hasAnswered) return;
    typingAnswer.toggle();
  }

  Future<void> submitTyped() async {
    final value = typedAnswerController.text.trim();
    if (value.isEmpty || !supportsTyping || hasAnswered) return;
    await submit(value);
  }

  /// Opens the multiplayer area for this grade. Kindergarten players finish
  /// the friendly tutorial first, just like they do from the home screen.
  Future<void> openMultiplayer() async {
    if (_session.needsKindergartenTutorial) {
      await Get.toNamed(AppRoutes.tutorial);
      return;
    }
    await Get.toNamed(AppRoutes.browseRooms);
  }

  /// Keeps the next question on the same skill so a wrong answer is followed
  /// by a similar, gentler practice attempt.
  Future<void> trySimilar() async {
    final current = question.value;
    if (current != null) topic.value = current.topic;
    await loadNext();
  }

  Future<void> submit(String answer) async {
    final current = question.value;
    if (current == null || isSubmitting.value || hasAnswered) return;
    isSubmitting.value = true;
    selectedAnswer.value = answer;
    final elapsed = DateTime.now().difference(_shownAt).inMilliseconds;
    try {
      final next = await _api.submitPracticeAnswer(
        questionId: current.id,
        answer: answer,
        attemptId: attemptId,
        usedHint: hintVisible.value,
        elapsedMs: elapsed.clamp(0, 120000),
      );
      result.value = next;
      answeredCount.value += 1;
      xpEarned.value += next.xpEarned;
      if (next.isCorrect) {
        correctCount.value += 1;
        streak.value += 1;
        if (streak.value > bestStreak.value) bestStreak.value = streak.value;
        AppFeedback.correct(enabled: _session.soundEnabled);
      } else {
        streak.value = 0;
        AppFeedback.incorrect(enabled: _session.soundEnabled);
      }
      await _session.refreshProfile();
    } catch (exception) {
      selectedAnswer.value = '';
      UiFeedback.error(UiFeedback.friendly(exception));
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    typedAnswerController.dispose();
    super.onClose();
  }

  AnswerOptionState optionState(String option) {
    final data = result.value;
    if (data == null) {
      return option == selectedAnswer.value
          ? AnswerOptionState.selected
          : AnswerOptionState.idle;
    }
    if (option == data.correctAnswer) return AnswerOptionState.correct;
    if (option == selectedAnswer.value) return AnswerOptionState.incorrect;
    return AnswerOptionState.muted;
  }

  void backHome() => Get.back();
}
