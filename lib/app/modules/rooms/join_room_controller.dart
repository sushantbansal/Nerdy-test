import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/ui_feedback.dart';
import '../../data/providers/math_api_provider.dart';
import '../../routes/app_routes.dart';

class JoinRoomController extends GetxController {
  JoinRoomController(this._api);

  final MathApiProvider _api;

  final codeController = TextEditingController();
  final RxBool isJoining = false.obs;
  final RxString error = ''.obs;

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }

  void onCodeChanged(String value) {
    if (error.value.isNotEmpty) error.value = '';
  }

  Future<void> join() async {
    if (isJoining.value) return;
    final code = codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      error.value = 'Room codes are exactly 6 letters or numbers.';
      return;
    }
    error.value = '';
    isJoining.value = true;
    try {
      final joined = await _api.joinRoom(code);
      Get.offNamed(AppRoutes.lobby, parameters: {'roomId': joined.roomId});
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
    } finally {
      isJoining.value = false;
    }
  }

  void browseRooms() => Get.toNamed(AppRoutes.browseRooms);
}
