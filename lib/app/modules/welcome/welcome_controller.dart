import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/ui_feedback.dart';
import '../../domain/models/math_models.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class WelcomeController extends GetxController {
  WelcomeController(this._session);

  final SessionService _session;

  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final Rx<GradeLevel> grade = GradeLevel.grade1.obs;
  final RxInt avatarIndex = 0.obs;
  final RxString avatarColor = AppConstants.avatarColors.first.obs;
  final RxBool isStarting = false.obs;
  final RxString error = ''.obs;

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  void selectAvatar(int index, String color) {
    avatarIndex.value = index;
    avatarColor.value = color;
  }

  Future<void> startAsGuest() async {
    final name = nameController.text.trim();
    if (name.length < 2) {
      error.value = 'Please enter a name with at least 2 letters.';
      return;
    }
    if (name.length > 20) {
      error.value = 'Please keep names to 20 characters or fewer.';
      return;
    }
    error.value = '';
    isStarting.value = true;
    try {
      await _session.signInAsGuest(
        displayName: name,
        grade: grade.value,
        avatarIndex: avatarIndex.value,
        avatarColor: avatarColor.value,
      );
      Get.offAllNamed(AppRoutes.home);
    } catch (exception) {
      final message = UiFeedback.friendly(exception);
      error.value = message;
      UiFeedback.error(message);
    } finally {
      isStarting.value = false;
    }
  }

  void goToSignIn() =>
      Get.toNamed(AppRoutes.auth, arguments: {'mode': 'sign_in'});

  void goToSignUp() =>
      Get.toNamed(AppRoutes.auth, arguments: {'mode': 'sign_up'});
}
