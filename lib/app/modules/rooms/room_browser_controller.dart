import 'package:get/get.dart';

import '../../core/utils/ui_feedback.dart';
import '../../data/models/math_api_models.dart';
import '../../data/providers/math_api_provider.dart';
import '../../domain/models/math_models.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class RoomBrowserController extends GetxController {
  RoomBrowserController(this._api, this._session);

  final MathApiProvider _api;
  final SessionService _session;

  final RxList<MathRoomSummary> rooms = <MathRoomSummary>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString joiningRoomId = ''.obs;

  final Rxn<GradeLevel> gradeFilter = Rxn<GradeLevel>();
  final Rxn<MathTopic> topicFilter = Rxn<MathTopic>();
  final RxBool onlyAvailable = true.obs;

  @override
  void onInit() {
    super.onInit();
    gradeFilter.value = _session.profile.value?.grade;
    refresh();
  }

  @override
  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    try {
      final results = await _api.listRooms(
        grade: gradeFilter.value,
        topic: topicFilter.value,
        onlyAvailable: onlyAvailable.value,
        limit: 40,
      );
      rooms.assignAll(results);
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setGrade(GradeLevel? grade) async {
    gradeFilter.value = grade;
    await refresh();
  }

  Future<void> setTopic(MathTopic? topic) async {
    topicFilter.value = topic;
    await refresh();
  }

  Future<void> setOnlyAvailable(bool value) async {
    onlyAvailable.value = value;
    await refresh();
  }

  Future<void> join(MathRoomSummary room) async {
    if (joiningRoomId.value.isNotEmpty) return;
    joiningRoomId.value = room.id;
    try {
      final joined = await _api.joinRoom(room.code);
      Get.toNamed(
        AppRoutes.lobby,
        parameters: {'roomId': joined.roomId},
      )?.then((_) => refresh());
    } catch (exception) {
      UiFeedback.error(UiFeedback.friendly(exception));
      await refresh();
    } finally {
      joiningRoomId.value = '';
    }
  }

  void openCreate() => Get.toNamed(AppRoutes.createRoom);
  void openJoin() => Get.toNamed(AppRoutes.joinRoom);
}
