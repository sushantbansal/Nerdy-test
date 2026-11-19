import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_constants.dart';
import '../../core/utils/ui_feedback.dart';
import '../../data/models/math_api_models.dart';
import '../../data/providers/math_api_provider.dart';
import '../../data/providers/supabase_provider.dart';
import '../../domain/models/math_models.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class LobbyController extends GetxController {
  LobbyController(this._api, this._session);

  final MathApiProvider _api;
  final SessionService _session;

  final Rx<MathRoomState?> roomState = Rx<MathRoomState?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isBusy = false.obs;
  final RxString error = ''.obs;

  String roomId = '';
  bool _navigating = false;
  bool _polling = false;
  Timer? _pollTimer;
  Timer? _heartbeatTimer;
  RealtimeChannel? _channel;

  MathRoom? get room => roomState.value?.room;
  List<MathRoomPlayer> get players => roomState.value?.players ?? const [];
  bool get isHost => room?.isHost ?? false;
  bool get canStart => room?.canStart ?? false;
  bool get isReady => room?.myReady ?? false;
  MathRoomPlayer? get me {
    final id = _session.userId;
    if (id == null) return null;
    for (final player in players) {
      if (player.playerId == id) return player;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    roomId = Get.parameters['roomId'] ?? '';
    if (roomId.isEmpty) {
      error.value = 'That room link is missing a room.';
      return;
    }
    final arguments = Get.arguments;
    if (arguments is Map && arguments['justCreated'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UiFeedback.success('Room created! Share the code with a friend.');
      });
    }
    _load(showSpinner: true);
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 1200),
      (_) => _load(silent: true),
    );
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _api.heartbeat(roomId).catchError((_) {}),
    );
    _subscribe();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    final channel = _channel;
    if (channel != null) {
      SupabaseProvider.removeChannel(channel);
    }
    super.onClose();
  }

  void _subscribe() {
    try {
      _channel = SupabaseProvider.client
          .channel(SupabaseConstants.roomChannel(roomId))
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'math_room_players',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (_) => _load(silent: true),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'math_rooms',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: roomId,
            ),
            callback: (_) => _load(silent: true),
          )
          .subscribe();
    } catch (_) {
      // Polling is the primary transport; realtime is only an accelerant.
    }
  }

  Future<void> _load({bool showSpinner = false, bool silent = false}) async {
    if (roomId.isEmpty || _navigating || _polling) return;
    _polling = true;
    if (showSpinner) isLoading.value = true;
    try {
      await _api.advanceMatch(roomId);
      final next = await _api.roomState(roomId);
      roomState.value = next;
      error.value = '';
      _handlePhase(next);
    } catch (exception) {
      if (!silent) {
        error.value = UiFeedback.friendly(exception);
      }
    } finally {
      _polling = false;
      isLoading.value = false;
    }
  }

  void _handlePhase(MathRoomState state) {
    if (_navigating) return;
    final phase = state.room.status;
    if (phase.isActiveMatch || phase == RoomPhase.finalResults) {
      _navigating = true;
      _pollTimer?.cancel();
      _heartbeatTimer?.cancel();
      Get.offNamed(AppRoutes.match, parameters: {'roomId': roomId});
    } else if (phase == RoomPhase.completed || phase == RoomPhase.abandoned) {
      error.value = 'This room has closed. Start a fresh clash!';
      _pollTimer?.cancel();
    }
  }

  @override
  Future<void> refresh() => _load(showSpinner: true);

  Future<void> toggleReady() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      await _api.setReady(roomId, !isReady);
      await _load(silent: true);
    } catch (exception) {
      UiFeedback.error(UiFeedback.friendly(exception));
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> startMatch() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      await _api.startMatch(roomId);
      await _load(silent: true);
    } catch (exception) {
      UiFeedback.error(UiFeedback.friendly(exception));
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> copyCode() async {
    final code = room?.code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    UiFeedback.success('Room code $code copied!');
  }

  Future<void> leave() async {
    _navigating = true;
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    try {
      await _api.leaveRoom(roomId);
    } catch (_) {
      // Leaving still returns the player home if the network drops.
    }
    Get.offAllNamed(AppRoutes.home);
  }

  void goHome() => Get.offAllNamed(AppRoutes.home);
}
