import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/ui_feedback.dart';
import '../../domain/models/math_models.dart';
import '../../services/session_service.dart';

class ProfileEditController extends GetxController {
  ProfileEditController(this._session);

  final SessionService _session;

  final nameController = TextEditingController();
  final RxInt avatarIndex = 0.obs;
  final RxString avatarColor = '#00A2FF'.obs;
  final Rx<GradeLevel> grade = GradeLevel.grade1.obs;
  final RxBool isSaving = false.obs;
  final RxString error = ''.obs;

  bool get canSave =>
      nameController.text.trim().length >= 2 &&
      nameController.text.trim().length <= 20 &&
      !isSaving.value;

  @override
  void onInit() {
    super.onInit();
    final profile = _session.profile.value;
    if (profile != null) {
      nameController.text = profile.displayName;
      avatarIndex.value = profile.avatarIndex;
      avatarColor.value = profile.avatarColor;
      grade.value = profile.grade;
    }
    nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() => error.value = '';

  @override
  void onClose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    super.onClose();
  }

  void selectAvatar(int index, String color) {
    avatarIndex.value = index;
    avatarColor.value = color;
  }

  Future<void> save() async {
    if (isSaving.value) return;
    final name = nameController.text.trim();
    if (name.length < 2) {
      error.value = 'Names need at least 2 characters.';
      return;
    }
    if (name.length > 20) {
      error.value = 'Keep names to 20 characters or fewer.';
      return;
    }
    isSaving.value = true;
    error.value = '';
    try {
      await _session.updateProfile(
        displayName: name,
        avatarIndex: avatarIndex.value,
        avatarColor: avatarColor.value,
        grade: grade.value,
      );
      UiFeedback.success('Profile updated!');
      Get.back();
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
      UiFeedback.error(error.value);
    } finally {
      isSaving.value = false;
    }
  }
}
