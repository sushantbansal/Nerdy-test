import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sketch_rush/app/data/providers/auth_provider.dart';
import 'package:sketch_rush/app/data/providers/math_api_provider.dart';
import 'package:sketch_rush/app/modules/auth/auth_controller.dart';
import 'package:sketch_rush/app/modules/auth/auth_view.dart';
import 'package:sketch_rush/app/services/session_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(AuthController(SessionService(AuthProvider(), MathApiProvider())));
  });

  tearDown(Get.reset);

  testWidgets('login screen offers sign-in, sign-up and guest play', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GetMaterialApp(home: AuthView()));
    await tester.pumpAndSettle();

    expect(find.text('Play!'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Player setup'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Create my account'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Why create an account?'));
    await tester.tap(find.text('Why create an account?'));
    await tester.pumpAndSettle();

    expect(find.text('Why create an account?'), findsWidgets);
    expect(find.textContaining('Accounts are optional'), findsOneWidget);
  });
}
