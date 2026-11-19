import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sketch_rush/app/modules/tutorial/tutorial_controller.dart';
import 'package:sketch_rush/app/modules/tutorial/tutorial_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(TutorialController());
  });

  tearDown(Get.reset);

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'a child can complete the Kindergarten tutorial from beginning to end',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GetMaterialApp(home: TutorialView()));
      await tester.pumpAndSettle();

      expect(find.text('Tap. Count. Choose.'), findsOneWidget);
      await tapVisible(tester, find.text('Start'));

      expect(find.text('Tap each apple'), findsOneWidget);
      expect(find.text('🍎'), findsNWidgets(3));
      for (var index = 0; index < 3; index++) {
        await tapVisible(tester, find.text('🍎').at(index));
      }
      expect(find.text('Three apples! 🎉'), findsOneWidget);
      await tapVisible(tester, find.text('Next'));

      expect(find.text('Which card has 3 apples?'), findsOneWidget);
      await tapVisible(tester, find.text('3 apples'));

      expect(find.text('You counted 3!'), findsOneWidget);
      await tapVisible(tester, find.text('Next move'));

      expect(find.text('1 apple + 2 apples'), findsOneWidget);
      await tapVisible(tester, find.text('3'));

      expect(find.text('3 out of 3!'), findsOneWidget);
      expect(find.text('PRACTICE RESULTS'), findsOneWidget);
      await tapVisible(tester, find.text('Next'));

      expect(find.text('You are ready!'), findsOneWidget);
      expect(find.text('Play a match'), findsOneWidget);
      expect(find.text('Practise with pictures'), findsOneWidget);

      await tapVisible(tester, find.text('Do the tutorial again'));
      expect(find.text('Tap. Count. Choose.'), findsOneWidget);
    },
  );

  testWidgets('the tutorial can be skipped after completing it', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: TutorialView()));
    await tester.pumpAndSettle();

    final controller = Get.find<TutorialController>();
    controller
      ..start()
      ..tapApple(0)
      ..tapApple(1)
      ..tapApple(2)
      ..nextFromCount()
      ..chooseThree(true)
      ..nextFromCelebrate()
      ..answerAdd(3)
      ..nextFromResults();
    await tester.pumpAndSettle();

    expect(controller.step.value, TutorialStep.done);
    expect(find.text('You are ready!'), findsOneWidget);
    expect(find.text('Play a match'), findsOneWidget);
  });
}
