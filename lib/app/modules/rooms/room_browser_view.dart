import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/math_api_models.dart';
import '../../domain/models/math_models.dart';
import 'room_browser_controller.dart';

class RoomBrowserView extends GetView<RoomBrowserController> {
  const RoomBrowserView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Public rooms',
      subtitle: 'Find a clash that fits your grade.',
      background: CandyBackgroundStyle.sky,
      actions: [
        IconButton(
          onPressed: controller.refresh,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.ink,
            side: BorderSide(color: AppColors.outline, width: 2),
          ),
        ),
      ],
      bottomBar: Row(
        children: [
          Expanded(
            child: ArcadeButton(
              label: 'Join code',
              icon: Icons.key_rounded,
              variant: ArcadeButtonVariant.outline,
              onPressed: controller.openJoin,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ArcadeButton(
              label: 'Create room',
              icon: Icons.add_rounded,
              onPressed: controller.openCreate,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Filters(),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isLoading.value && controller.rooms.isEmpty) {
              return const LoadingView(message: 'Finding open rooms…');
            }
            if (controller.error.value.isNotEmpty && controller.rooms.isEmpty) {
              return ErrorState(
                message: controller.error.value,
                onRetry: controller.refresh,
              );
            }
            if (controller.rooms.isEmpty) {
              return EmptyState(
                title: 'No rooms match yet',
                message:
                    'Try another grade or topic, or build your own arena and invite a friend.',
                actionLabel: 'Create a room',
                onAction: controller.openCreate,
                emoji: '🔍',
              );
            }
            return Column(
              children: [
                for (final room in controller.rooms) ...[
                  _RoomCard(room: room),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<RoomBrowserController>();
    return CandyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grade', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: controller.gradeFilter.value == null,
                  onTap: () => controller.setGrade(null),
                ),
                for (final grade in GradeLevel.values)
                  _FilterChip(
                    label: grade.shortLabel,
                    selected: controller.gradeFilter.value == grade,
                    onTap: () => controller.setGrade(grade),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Topic', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Any topic',
                  selected: controller.topicFilter.value == null,
                  onTap: () => controller.setTopic(null),
                ),
                for (final topic in MathTopic.values)
                  TopicPill(
                    topic: topic,
                    compact: true,
                    selected: controller.topicFilter.value == topic,
                    showSymbol: false,
                    onTap: () => controller.setTopic(
                      controller.topicFilter.value == topic ? null : topic,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => SwitchListTile.adaptive(
              value: controller.onlyAvailable.value,
              onChanged: controller.setOnlyAvailable,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Only rooms with space',
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                'Hide rooms that are already full',
                style: theme.textTheme.labelSmall,
              ),
              activeTrackColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectionSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.selectionSurface : AppColors.outline,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.onSelection : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});

  final MathRoomSummary room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<RoomBrowserController>();
    final full = room.isFull;
    final joining = controller.joiningRoomId.value == room.id;
    return CandyCard(
      padding: const EdgeInsets.all(16),
      onTap: full && !room.isJoined ? null : () => controller.join(room),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlayerAvatar(
                avatarIndex: room.hostAvatarIndex,
                avatarColor: room.hostAvatarColor,
                size: 44,
                displayName: room.hostName,
                isHost: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Hosted by ${room.hostName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.outline, width: 1.5),
                ),
                child: Text(
                  Formatters.roomCode(room.code),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.ink,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GradePill(grade: room.grade, compact: true),
              for (final topic in room.topics.take(3))
                TopicPill(topic: topic, compact: true),
              DifficultyPill(difficulty: room.difficulty, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Meta(
                icon: Icons.help_outline_rounded,
                label: '${room.questionCount} questions',
              ),
              const SizedBox(width: 12),
              _Meta(
                icon: Icons.timer_outlined,
                label: '${room.answerSeconds}s each',
              ),
              const Spacer(),
              if (room.isJoined)
                ArcadeButton(
                  label: 'Rejoin',
                  size: ArcadeButtonSize.small,
                  variant: ArcadeButtonVariant.outline,
                  onPressed: () => controller.join(room),
                )
              else
                ArcadeButton(
                  label: full ? 'Full' : 'Join',
                  size: ArcadeButtonSize.small,
                  variant: full
                      ? ArcadeButtonVariant.outline
                      : ArcadeButtonVariant.primary,
                  loading: joining,
                  onPressed: full ? null : () => controller.join(room),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < room.maxPlayers; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: i < room.playerCount
                          ? AppColors.mintDark
                          : AppColors.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                '${room.playerCount}/${room.maxPlayers} players',
                style: theme.textTheme.labelSmall,
              ),
              const Spacer(),
              Text(
                room.speedBonusEnabled ? '⚡ Speed bonus' : 'No speed bonus',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.inkSoft),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
