import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/selectors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/math_api_models.dart';
import '../../routes/app_routes.dart';
import '../../domain/models/math_models.dart';
import 'leaderboard_controller.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Leaderboards',
      subtitle: 'Climb the candy ranks.',
      background: CandyBackgroundStyle.warm,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => SegmentedChoice<String>(
              options: const ['week', 'all'],
              value: controller.window.value,
              labelBuilder: (value) =>
                  value == 'week' ? 'This week' : 'All time',
              onChanged: controller.setWindow,
            ),
          ),
          const SizedBox(height: 12),
          _Filters(),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isLoading.value && controller.entries.isEmpty) {
              return const LoadingView(message: 'Ranking the mathletes…');
            }
            if (controller.error.value.isNotEmpty &&
                controller.entries.isEmpty) {
              return ErrorState(
                message: controller.error.value,
                onRetry: controller.refresh,
              );
            }
            if (controller.entries.isEmpty) {
              return EmptyState(
                emoji: '🏁',
                title: 'No ranked players yet',
                message: controller.window.value == 'week'
                    ? 'Finish at least 2 matches this week to appear here.'
                    : 'Finish at least 3 matches to join the all-time board.',
                actionLabel: 'Refresh',
                onAction: controller.refresh,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.podium.isNotEmpty) _Podium(),
                const SizedBox(height: 18),
                if (controller.rest.isNotEmpty) ...[
                  SectionHeader(
                    eyebrow: controller.windowLabel,
                    title: 'Top mathletes',
                    emoji: '🏆',
                  ),
                  CandyCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        for (var i = 0; i < controller.rest.length; i++) ...[
                          if (i > 0) const Divider(height: 16),
                          _BoardRow(entry: controller.rest[i]),
                        ],
                      ],
                    ),
                  ),
                ],
                if (controller.mine != null) ...[
                  const SizedBox(height: 16),
                  _YourRank(entry: controller.mine!),
                ],
                const SizedBox(height: 16),
                Text(
                  controller.window.value == 'week'
                      ? 'Weekly boards reset every Monday. Practice points are not counted.'
                      : 'All-time boards need 3 completed matches. Practice points are not counted.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                ),
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
    final controller = Get.find<LeaderboardController>();
    return CandyCard(
      padding: const EdgeInsets.all(14),
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
                _Chip(
                  label: 'All',
                  selected: controller.grade.value == null,
                  onTap: () => controller.setGrade(null),
                ),
                for (final grade in GradeLevel.values)
                  _Chip(
                    label: grade.shortLabel,
                    selected: controller.grade.value == grade,
                    onTap: () => controller.setGrade(grade),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Topic', style: theme.textTheme.titleSmall),
                const SizedBox(width: 2),
                _Chip(
                  label: 'Any',
                  selected: controller.topic.value == null,
                  onTap: () => controller.setTopic(null),
                ),
                for (final topic in MathTopic.values)
                  TopicPill(
                    topic: topic,
                    compact: true,
                    showSymbol: false,
                    selected: controller.topic.value == topic,
                    onTap: () => controller.setTopic(
                      controller.topic.value == topic ? null : topic,
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

class _Chip extends StatelessWidget {
  const _Chip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _Podium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LeaderboardController>();
    return Obx(() {
      final podium = controller.podium;
      if (podium.isEmpty) return const SizedBox.shrink();
      final first = podium.firstWhere(
        (entry) => entry.rank == 1,
        orElse: () => podium.first,
      );
      MathLeaderboardEntry? second;
      MathLeaderboardEntry? third;
      for (final entry in podium) {
        if (entry.rank == 2) second = entry;
        if (entry.rank == 3) third = entry;
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.podiumGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellowDark.withValues(alpha: 0.28),
              offset: const Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (second != null)
              Expanded(child: _PodiumPlace(entry: second, height: 92)),
            Expanded(
              child: _PodiumPlace(entry: first, height: 126, first: true),
            ),
            if (third != null)
              Expanded(child: _PodiumPlace(entry: third, height: 72)),
          ],
        ),
      );
    });
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.entry,
    required this.height,
    this.first = false,
  });

  final MathLeaderboardEntry entry;
  final double height;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (first) const Text('👑', style: TextStyle(fontSize: 24, height: 1)),
        PlayerAvatar(
          avatarIndex: entry.avatarIndex,
          avatarColor: entry.avatarColor,
          size: first ? 66 : 48,
          displayName: entry.displayName,
          showRing: true,
          ringColor: AppColors.surface,
        ),
        const SizedBox(height: 4),
        Text(
          entry.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '${entry.points} pts',
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 5),
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: first
                ? AppColors.surface
                : AppColors.surface.withValues(alpha: 0.72),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: AppColors.yellowDark, width: 2),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(switch (entry.rank) {
            1 => '🥇',
            2 => '🥈',
            3 => '🥉',
            _ => '${entry.rank}',
          }, style: const TextStyle(fontSize: 22, height: 1)),
        ),
      ],
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.entry});

  final MathLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.toNamed(
        AppRoutes.publicProfile,
        parameters: {'playerId': entry.playerId},
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(width: 6),
          PlayerAvatar(
            avatarIndex: entry.avatarIndex,
            avatarColor: entry.avatarColor,
            size: 36,
            displayName: entry.displayName,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (entry.isMe) ...[
                      const SizedBox(width: 5),
                      Text(
                        'YOU',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${entry.games} matches · ${Formatters.percent(entry.accuracy)} accuracy',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.yellowDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${entry.speedBonuses}⚡',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YourRank extends StatelessWidget {
  const _YourRank({required this.entry});

  final MathLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      color: AppColors.primarySoft,
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#${entry.rank}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'That is you!',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${entry.points} points · ${entry.wins} wins',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const Text('🌟', style: TextStyle(fontSize: 26, height: 1)),
        ],
      ),
    );
  }
}
