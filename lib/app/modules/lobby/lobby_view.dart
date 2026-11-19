import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/math_api_models.dart';
import '../../domain/models/math_models.dart';
import 'lobby_controller.dart';

class LobbyView extends GetView<LobbyController> {
  const LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final room = controller.room;
      return AppScaffold(
        title: room?.name ?? 'Room lobby',
        subtitle: room == null
            ? 'Getting the room ready…'
            : '${room.grade.label} · ${Formatters.topics(room.topics)}',
        background: CandyBackgroundStyle.mint,
        showBack: false,
        actions: [
          IconButton(
            onPressed: controller.copyCode,
            tooltip: 'Copy room code',
            icon: const Icon(Icons.ios_share_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.outline, width: 2),
            ),
          ),
        ],
        bottomBar: room == null ? null : _BottomBar(),
        child: _content(context, room),
      );
    });
  }

  Widget _content(BuildContext context, MathRoom? room) {
    if (room == null) {
      if (controller.isLoading.value) {
        return const LoadingView(message: 'Opening the lobby…');
      }
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: ErrorState(
          message: controller.error.value.isEmpty
              ? 'This room could not be opened.'
              : controller.error.value,
          onRetry: controller.refresh,
          retryLabel: 'Try again',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CodeCard(room: room),
        const SizedBox(height: 14),
        _SetupCard(room: room),
        const SizedBox(height: 20),
        SectionHeader(
          eyebrow: 'Lobby',
          title: 'Players (${controller.players.length}/${room.maxPlayers})',
          emoji: '👋',
          subtitle: controller.isHost
              ? 'You are the host. Start when everyone is in.'
              : 'Tap ready so the host knows you are set.',
        ),
        CandyCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (var i = 0; i < room.maxPlayers; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                if (i < controller.players.length)
                  _PlayerRow(
                    player: controller.players[i],
                    isMe:
                        controller.players[i].playerId ==
                        controller.me?.playerId,
                  )
                else
                  const _EmptySlot(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (room.grade == GradeLevel.kindergarten)
          _KindergartenHowItWorks(players: controller.players)
        else
          _HowItWorks(room: room),
        if (controller.error.value.isNotEmpty) ...[
          const SizedBox(height: 14),
          InlineBanner(
            message: controller.error.value,
            icon: Icons.error_outline_rounded,
            color: AppColors.errorDark,
            background: AppColors.errorSoft,
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => _confirmLeave(context),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Leave room'),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorDark),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this room?'),
        content: const Text(
          'You can rejoin later with the room code if the match has not started.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorDark),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (shouldLeave == true) {
      await controller.leave();
    }
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.room});

  final MathRoom room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            offset: const Offset(0, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROOM CODE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.roomCode(room.code),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 38,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  room.visibility == RoomVisibility.public
                      ? 'Public · findable in Browse'
                      : 'Private · code only',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          ArcadeButton(
            label: 'Copy',
            icon: Icons.copy_rounded,
            size: ArcadeButtonSize.small,
            variant: ArcadeButtonVariant.yellow,
            onPressed: Get.find<LobbyController>().copyCode,
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.room});

  final MathRoom room;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          GradePill(grade: room.grade, compact: true),
          for (final topic in room.topics)
            TopicPill(topic: topic, compact: true),
          DifficultyPill(difficulty: room.difficulty, compact: true),
          _InfoChip(
            icon: Icons.help_outline_rounded,
            label: '${room.questionCount} questions',
          ),
          _InfoChip(
            icon: Icons.timer_outlined,
            label: '${room.answerSeconds}s',
          ),
          _InfoChip(
            icon: Icons.groups_rounded,
            label: '${room.maxPlayers} max',
          ),
          if (room.speedBonusEnabled)
            const _InfoChip(icon: Icons.bolt_rounded, label: 'Speed bonus'),
          if (room.autoStart)
            const _InfoChip(
              icon: Icons.play_circle_outline,
              label: 'Auto-start',
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.inkSoft),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.isMe});

  final MathRoomPlayer player;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isMe
            ? Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.07),
                AppColors.surface,
              )
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.outline,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          PlayerAvatar(
            avatarIndex: player.avatarIndex,
            avatarColor: player.avatarColor,
            size: 38,
            displayName: player.displayName,
            isHost: player.isHost,
            isConnected: player.isConnected,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    player.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'YOU',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onAccent,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _ReadyBadge(
            ready: player.isReady,
            label: player.isHost
                ? 'Host'
                : player.isReady
                ? 'Ready'
                : 'Not ready',
          ),
        ],
      ),
    );
  }
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({required this.ready, required this.label});

  final bool ready;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ready ? AppColors.mintSoft : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ready ? AppColors.mintDark : AppColors.outline,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 12,
            color: ready ? AppColors.mintDark : AppColors.inkSoft,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ready ? AppColors.mintDark : AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? AppColors.surfaceSoft
            : const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.7),
          width: 2,
          style: BorderStyle.none,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline, width: 2),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_add_alt_1_rounded,
              size: 18,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Waiting for a player…',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.room});

  final MathRoom room;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      color: AppColors.yellowSoft,
      borderColor: AppColors.yellow,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 24, height: 1.2)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How scoring works',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Every correct answer earns 1 point.'
                  '${room.speedBonusEnabled ? ' The fastest correct answer earns +1 extra.' : ''} '
                  'Everyone sees the same questions at the same time, and the server keeps score.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KindergartenHowItWorks extends StatelessWidget {
  const _KindergartenHowItWorks({required this.players});

  final List<MathRoomPlayer> players;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CandyCard(
      color: AppColors.yellowSoft,
      borderColor: AppColors.yellow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: NarrationBar(
              text:
                  'Answer the questions. Collect stars. See how everyone did '
                  'at the end.',
              autoPlay: true,
              label: 'Hear it again',
              compact: true,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final step in const [
                (emoji: '✋', label: 'Tap'),
                (emoji: '⭐', label: 'Stars'),
                (emoji: '🏆', label: 'Results'),
              ]) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.emoji,
                      style: const TextStyle(fontSize: 30, height: 1),
                    ),
                    Text(step.label, style: theme.textTheme.labelSmall),
                  ],
                ),
                if (step.label != 'Results')
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.yellowDark,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '🐾 Animal friends',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              for (final player in players)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlayerAvatar(
                      avatarIndex: player.avatarIndex,
                      avatarColor: player.avatarColor,
                      size: 52,
                      displayName: player.displayName,
                      isHost: player.isHost,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: Text(
                        player.displayName.split(' ').first,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LobbyController>();
    return Obx(() {
      final room = controller.room;
      if (room == null) return const SizedBox.shrink();

      if (controller.isHost) {
        final ready = controller.canStart;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!ready)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Invite at least one friend to start.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ArcadeButton(
              label: ready ? 'Start the clash' : 'Waiting for players',
              icon: Icons.play_arrow_rounded,
              size: ArcadeButtonSize.large,
              expand: true,
              enabled: ready,
              loading: controller.isBusy.value,
              onPressed: controller.startMatch,
            ),
          ],
        );
      }

      return ArcadeButton(
        label: controller.isReady ? 'Ready!' : 'I’m ready',
        icon: controller.isReady
            ? Icons.check_circle_rounded
            : Icons.pan_tool_rounded,
        variant: controller.isReady
            ? ArcadeButtonVariant.mint
            : ArcadeButtonVariant.primary,
        size: ArcadeButtonSize.large,
        expand: true,
        loading: controller.isBusy.value,
        onPressed: controller.toggleReady,
      );
    });
  }
}
