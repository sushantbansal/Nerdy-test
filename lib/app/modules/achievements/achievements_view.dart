import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/achievement_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/math_api_models.dart';
import 'achievements_controller.dart';

class AchievementsView extends GetView<AchievementsController> {
  const AchievementsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Badge shelf',
      subtitle: 'Every badge is earned by playing fair and learning.',
      background: CandyBackgroundStyle.purple,
      child: Obx(() {
        if (controller.isLoading.value && controller.achievements.isEmpty) {
          return const LoadingView(message: 'Dusting off the trophy shelf…');
        }
        if (controller.error.value.isNotEmpty &&
            controller.achievements.isEmpty) {
          return ErrorState(
            message: controller.error.value,
            onRetry: controller.refresh,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Summary(
              unlocked: controller.unlocked.length,
              total: controller.achievements.length,
              xp: controller.totalXp,
              completion: controller.completion,
            ),
            const SizedBox(height: 20),
            SectionHeader(
              eyebrow: 'Trophy shelf',
              title: 'Unlocked (${controller.unlocked.length})',
              emoji: '🎖️',
            ),
            if (controller.unlocked.isEmpty)
              const EmptyState(
                emoji: '🌱',
                title: 'Your shelf is waiting',
                message:
                    'Finish a match or practise a little to unlock your first badge.',
                compact: true,
              )
            else
              _BadgeGrid(badges: controller.unlocked, unlocked: true),
            const SizedBox(height: 20),
            SectionHeader(
              eyebrow: 'Next up',
              title: 'Still to earn (${controller.locked.length})',
              emoji: '🔒',
            ),
            _BadgeGrid(badges: controller.locked, unlocked: false),
            const SizedBox(height: 16),
            Text(
              'Badges award a little XP, which is cosmetic only. '
              'They never affect match scoring.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      }),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.unlocked,
    required this.total,
    required this.xp,
    required this.completion,
  });

  final int unlocked;
  final int total;
  final int xp;
  final double completion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8C45FF), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDark.withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 40, height: 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$unlocked of $total badges',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$xp bonus XP from achievements',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(completion * 100).round()}% of the shelf collected',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges, required this.unlocked});

  final List<MathAchievement> badges;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 3 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final badge in badges)
              SizedBox(
                width: width,
                child: _BadgeTile(badge: badge, unlocked: unlocked),
              ),
          ],
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.unlocked});

  final MathAchievement badge;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.surface : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: unlocked ? AppColors.purple : AppColors.outline,
          width: 2,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: AppColors.purpleDark.withValues(alpha: 0.12),
                  offset: const Offset(0, 5),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: unlocked ? AppColors.purpleSoft : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: unlocked ? 1 : 0.4,
                  child: Text(
                    achievementEmoji(badge.icon),
                    style: const TextStyle(fontSize: 24, height: 1),
                  ),
                ),
              ),
              const Spacer(),
              if (unlocked)
                Icon(Icons.verified_rounded, size: 20, color: AppColors.purple)
              else
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.inkSoft,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            badge.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: unlocked ? AppColors.ink : AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            badge.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '+${badge.xp} XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: unlocked ? AppColors.purpleDark : AppColors.inkSoft,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (unlocked && badge.unlockedAt != null)
                Text(
                  Formatters.relativeDate(badge.unlockedAt!),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
