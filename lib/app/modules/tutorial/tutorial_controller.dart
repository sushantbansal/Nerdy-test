import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../services/narration_service.dart';
import '../../services/session_service.dart';

enum TutorialStep { welcome, count, choose, celebrate, add, results, done }

/// A calm, one-action-at-a-time introduction for first-time Kindergarten
/// players. It is deliberately independent of the match engine: the child can
/// practise tapping, counting and choosing without a clock or a score.
class TutorialController extends GetxController {
  final Rx<TutorialStep> step = TutorialStep.welcome.obs;
  final RxList<bool> apples = <bool>[false, false, false].obs;
  final RxInt wrongAttempts = 0.obs;
  final RxBool isFinishing = false.obs;

  int get counted => apples.where((tapped) => tapped).length;
  bool get countComplete => counted == apples.length;

  int get stepNumber => TutorialStep.values.indexOf(step.value) + 1;
  int get stepCount => TutorialStep.values.length;

  String get script => switch (step.value) {
    TutorialStep.welcome =>
      'Let us learn to play MathClash. Tap the big button to start.',
    TutorialStep.count =>
      'Count the apples. Tap each apple one time. You can hear the numbers.',
    TutorialStep.choose =>
      'Which card shows three apples? Tap the card with three apples.',
    TutorialStep.celebrate =>
      'Yes! Three apples. You counted them all by yourself.',
    TutorialStep.add =>
      'One apple plus two apples. How many apples altogether? '
          'The choices are two, three, and four.',
    TutorialStep.results =>
      'Here are your results. You answered three out of three. Stars and a '
          'progress bar show how it went. In a match, you will also see the '
          'group podium.',
    TutorialStep.done =>
      'You are ready to play. Great job! You can play a match or practise '
          'with pictures.',
  };

  bool get reducedMotion =>
      Get.isRegistered<SessionService>() &&
      Get.find<SessionService>().reducedMotion;

  @override
  void onInit() {
    super.onInit();
    _announce();
  }

  void start() {
    _go(TutorialStep.count);
  }

  void tapApple(int index) {
    if (index < 0 || index >= apples.length || apples[index]) return;
    apples[index] = true;
    _speak(
      counted == 1
          ? 'One'
          : counted == 2
          ? 'Two'
          : 'Three',
    );
    if (countComplete) {
      _speak('Three apples. Great counting!');
    }
  }

  void nextFromCount() {
    if (!countComplete) return;
    _go(TutorialStep.choose);
  }

  void chooseThree(bool isThree) {
    if (isThree) {
      _go(TutorialStep.celebrate);
      return;
    }
    wrongAttempts.value += 1;
    _speak('Almost. Count the apples one more time. Tap the card with three.');
  }

  void nextFromCelebrate() {
    _go(TutorialStep.add);
  }

  void answerAdd(int answer) {
    if (answer == 3) {
      _go(TutorialStep.results);
      return;
    }
    wrongAttempts.value += 1;
    _speak('Good try. Count one apple, then two more. One, two, three.');
  }

  void nextFromResults() {
    _go(TutorialStep.done);
  }

  void replay() {
    apples.assignAll([false, false, false]);
    wrongAttempts.value = 0;
    step.value = TutorialStep.welcome;
    _announce();
  }

  Future<void> finish({bool playMatch = false, bool practice = false}) async {
    if (isFinishing.value) return;
    isFinishing.value = true;
    try {
      if (Get.isRegistered<SessionService>()) {
        await Get.find<SessionService>().completeTutorial();
      }
    } catch (_) {
      // A saved flag should never trap a child on the tutorial screen.
    } finally {
      isFinishing.value = false;
    }
    if (practice) {
      await Get.offAllNamed(AppRoutes.practice);
      return;
    }
    await Get.offAllNamed(
      AppRoutes.home,
      arguments: playMatch ? const {'startQuickPlay': true} : null,
    );
  }

  void _go(TutorialStep next) {
    step.value = next;
    _announce();
  }

  void _announce() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak(script));
  }

  void _speak(String text) {
    if (!Get.isRegistered<NarrationService>()) return;
    unawaited(Get.find<NarrationService>().speak(text));
  }
}
