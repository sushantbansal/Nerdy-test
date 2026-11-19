import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/ui_feedback.dart';
import '../../data/providers/math_api_provider.dart';
import '../../domain/models/math_models.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class CreateRoomController extends GetxController {
  CreateRoomController(this._api, this._session);

  final MathApiProvider _api;
  final SessionService _session;

  final nameController = TextEditingController();

  final Rx<RoomVisibility> visibility = RoomVisibility.public.obs;
  final Rx<GradeLevel> grade = GradeLevel.grade1.obs;
  final RxSet<MathTopic> topics = <MathTopic>{
    MathTopic.addition,
    MathTopic.subtraction,
  }.obs;
  final Rx<MathDifficulty> difficulty = MathDifficulty.medium.obs;
  final RxInt questionCount = AppConstants.defaultQuestionCount.obs;
  final RxInt answerSeconds = AppConstants.defaultAnswerSeconds.obs;
  final RxInt maxPlayers = AppConstants.defaultMaxPlayers.obs;
  final RxBool speedBonus = true.obs;
  final RxBool autoStart = false.obs;
  final RxBool isCreating = false.obs;
  final RxString error = ''.obs;

  Set<MathTopic> get selectedTopics => topics.toSet();

  bool get isKindergarten => grade.value == GradeLevel.kindergarten;

  List<MathTopic> get availableTopics => grade.value.topics;

  static const List<int> answerChoices = [10, 15, 20, 30, 45];
  static const List<int> kindergartenAnswerChoices = [30, 45];
  static const List<int> playerChoices = [2, 3, 4, 6, 8];

  List<int> get visibleAnswerChoices =>
      isKindergarten ? kindergartenAnswerChoices : answerChoices;

  @override
  void onInit() {
    super.onInit();
    final profile = _session.profile.value;
    if (profile != null) {
      _applyGradeDefaults(profile.grade);
    }
    nameController.text = _randomName();
  }

  void setGrade(GradeLevel next) {
    if (grade.value == next) return;
    _applyGradeDefaults(next);
  }

  /// Kindergarten rooms get generous thinking time and no speed pressure.
  /// The choices stay configurable (30 or 45 seconds) so a grown-up can make
  /// the room even calmer.
  void _applyGradeDefaults(GradeLevel next) {
    final wasKindergarten = isKindergarten;
    grade.value = next;

    if (next == GradeLevel.kindergarten) {
      topics.assignAll([MathTopic.mixed, MathTopic.addition]);
      answerSeconds.value = AppConstants.kindergartenAnswerSeconds;
      speedBonus.value = false;
      return;
    }

    final allowed = next.topics.toSet();
    final filtered = topics.where(allowed.contains).toSet();
    if (filtered.isEmpty) {
      filtered.addAll([MathTopic.addition, MathTopic.subtraction]);
    }
    topics.assignAll(filtered.take(3));
    if (wasKindergarten) {
      answerSeconds.value = AppConstants.defaultAnswerSeconds;
      speedBonus.value = true;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  String _randomName() {
    final random = math.Random();
    final adjective =
        AppConstants.roomNameAdjectives[random.nextInt(
          AppConstants.roomNameAdjectives.length,
        )];
    final noun = AppConstants
        .roomNameNouns[random.nextInt(AppConstants.roomNameNouns.length)];
    return '$adjective $noun';
  }

  void shuffleName() => nameController.text = _randomName();

  void setTopics(Set<MathTopic> next) {
    final filtered = next.where(availableTopics.contains).toSet();
    if (filtered.isEmpty || filtered.length > 3) return;
    topics.assignAll(filtered);
  }

  void setQuestions(int value) {
    questionCount.value = value.clamp(
      AppConstants.minQuestionCount,
      AppConstants.maxQuestionCount,
    );
  }

  void setAnswerSeconds(int value) {
    if (isKindergarten && value < AppConstants.kindergartenMinAnswerSeconds) {
      return;
    }
    answerSeconds.value = value;
  }

  void setMaxPlayers(int value) => maxPlayers.value = value;

  Future<void> createRoom() async {
    if (isCreating.value) return;
    if (topics.isEmpty) {
      error.value = 'Pick at least one topic.';
      return;
    }
    final name = nameController.text.trim();
    if (name.length < 3) {
      error.value = 'Give your room a name with at least 3 characters.';
      return;
    }
    error.value = '';
    isCreating.value = true;
    try {
      final created = await _api.createRoom(
        name: name,
        visibility: visibility.value,
        grade: grade.value,
        topics: topics.toList(growable: false),
        difficulty: difficulty.value,
        questionCount: questionCount.value,
        answerSeconds: answerSeconds.value,
        maxPlayers: maxPlayers.value,
        speedBonusEnabled: speedBonus.value,
        autoStart: autoStart.value,
      );
      await _session.refreshProfile();
      Get.offNamed(
        AppRoutes.lobby,
        parameters: {'roomId': created.roomId},
        arguments: {'justCreated': true, 'roomCode': created.roomCode},
      );
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
      UiFeedback.error(error.value);
    } finally {
      isCreating.value = false;
    }
  }
}
