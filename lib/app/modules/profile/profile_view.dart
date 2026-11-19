import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/achievement_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/math_api_models.dart';
import '../../domain/models/math_models.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.profile.value;
      if (profile == null) {
        if (controller.isLoading.value) {
          return const AppScaffold(
            title: 'Profile',
            scrollable: false,
            child: LoadingView(message: 'Loading the profile…'),
          );
        }
        return AppScaffold(
          title: 'Profile',
          background: CandyBackgroundStyle.hero,
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: ErrorState(
              message: controller.error.value.isEmpty
                  ? 'This profile could not be loaded.'
                  : controller.error.value,
              onRetry: controller.refresh,
            ),
          ),
        );
      }

      final me = profile.isMe;
      return AppScaffold(
        title: me ? 'Your profile' : '${profile.displayName}’s profile',
        subtitle: me ? 'Your maths journey so far.' : 'Public game stats only.',
        background: CandyBackgroundStyle.hero,
        actions: [
          if (me)
            IconButton(
              onPressed: controller.openSettings,
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_rounded),
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
            _ProfileHero(profile: profile),
            const SizedBox(height: 16),
            if (me)
              Row(
                children: [
                  Expanded(
                    child: ArcadeButton(
                      label: 'Edit profile',
                      icon: Icons.edit_rounded,
                      variant: ArcadeButtonVariant.outline,
                      onPressed: controller.editProfile,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ArcadeButton(
                      label: 'Practice',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Get.toNamed('/practice'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 22),
            const SectionHeader(
              eyebrow: 'Number crunching',
              title: 'Career stats',
              emoji: '📈',
            ),
            _StatsGrid(profile: profile),
            const SizedBox(height: 22),
            SectionHeader(
              eyebrow: 'Mastery',
              title: 'Topic progress',
              emoji: '🧠',
              trailing: me
                  ? TextButton(
                      onPressed: controller.openProgress,
                      child: const Text('Details'),
                    )
                  : null,
            ),
            _TopicProgress(profile: profile),
            const SizedBox(height: 22),
            SectionHeader(
              eyebrow: 'Trophy shelf',
              title: 'Recent badges',
              emoji: '🎖️',
              trailing: me
                  ? TextButton(
                      onPressed: controller.openAchievements,
                      child: const Text('All badges'),
                    )
                  : null,
            ),
            _AchievementPreview(profile: profile),
            const SizedBox(height: 22),
            const SectionHeader(
              eyebrow: 'History',
              title: 'Recent clashes',
              emoji: '🗂️',
            ),
            _RecentMatches(matches: profile.recentMatches),
            if (!me) ...[
              const SizedBox(height: 18),
              InlineBanner(
                message:
                    'This public profile only shows game stats. Private settings '
                    'and account details stay hidden.',
                icon: Icons.shield_outlined,
                color: AppColors.primaryDark,
                background: AppColors.primarySoft,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final MathProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.outline, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.07),
            offset: const Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerAvatar(
                avatarIndex: profile.avatarIndex,
                avatarColor: profile.avatarColor,
                size: 86,
                displayName: profile.displayName,
                showRing: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        GradePill(grade: profile.grade, compact: true),
                        MasteryPill(
                          mastery: profile.skills.isEmpty
                              ? MasteryLevel.notStarted
                              : profile.skills
                                    .map((s) => s.mastery)
                                    .reduce(
                                      (a, b) => a.order >= b.order ? a : b,
                                    ),
                          compact: true,
                        ),
                      ],
                    ),
                    if (profile.leaderboardRank != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '🏅 Rank #${profile.leaderboardRank} all-time',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.yellowDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          XpProgress(xp: profile.xp, level: profile.level),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                value: '${profile.gamesPlayed}',
                label: 'matches',
                emoji: '🎮',
              ),
              _MiniStat(
                value: '${profile.achievements.length}',
                label: 'badges',
                emoji: '🎖️',
              ),
              _MiniStat(
                value: '${profile.bestWinStreak}',
                label: 'best streak',
                emoji: '🔥',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.emoji,
  });

  final String value;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18, height: 1)),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.profile});

  final MathProfile profile;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Wins', '${profile.wins}', '🏆', AppColors.yellowDark),
      (
        'Win rate',
        Formatters.percent(profile.winRate),
        '📊',
        AppColors.primaryDark,
      ),
      (
        'Accuracy',
        Formatters.percent(profile.accuracy),
        '🎯',
        AppColors.mintDark,
      ),
      ('Total points', '${profile.totalPoints}', '⭐', AppColors.yellowDark),
      (
        'Best match',
        '${profile.bestMatchPoints} pts',
        '💥',
        AppColors.pinkDark,
      ),
      (
        'Avg points',
        Formatters.points(profile.averagePoints),
        '📈',
        AppColors.primaryDark,
      ),
      (
        'Avg answer',
        Formatters.averageResponse(profile.averageResponseMs),
        '⏱️',
        AppColors.purpleDark,
      ),
      (
        'Fastest',
        Formatters.responseTime(profile.fastestCorrectMs),
        '⚡',
        AppColors.mintDark,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _StatTile(
                  label: stat.$1,
                  value: stat.$2,
                  emoji: stat.$3,
                  color: stat.$4,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  });

  final String label;
  final String value;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18, height: 1)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: color),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicProgress extends StatelessWidget {
  const _TopicProgress({required this.profile});

  final MathProfile profile;

  @override
  Widget build(BuildContext context) {
    if (profile.skills.isEmpty) {
      return const EmptyState(
        emoji: '🌱',
        title: 'Your mastery map is empty',
        message: 'Play a match or a practice round to start growing skills.',
        compact: true,
      );
    }

    final grouped = <MathTopic, List<MathSkillProgress>>{};
    for (final skill in profile.skills) {
      grouped.putIfAbsent(skill.topic, () => []).add(skill);
    }
    final summaries = grouped.entries.map((entry) {
      final attempts = entry.value.fold<int>(0, (sum, s) => sum + s.attempts);
      final correct = entry.value.fold<int>(0, (sum, s) => sum + s.correct);
      final mastery = entry.value
          .map((s) => s.mastery)
          .reduce((a, b) => a.order >= b.order ? a : b);
      return (
        topic: entry.key,
        attempts: attempts,
        accuracy: attempts == 0 ? 0.0 : correct / attempts,
        mastery: mastery,
      );
    }).toList()..sort((a, b) => b.mastery.order.compareTo(a.mastery.order));

    return CandyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < summaries.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _TopicRow(summary: summaries[i]),
          ],
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.summary});

  final ({MathTopic topic, int attempts, double accuracy, MasteryLevel mastery})
  summary;

  @override
  Widget build(BuildContext context) {
    final color = topicColor(summary.topic);
    return Column(
      children: [
        Row(
          children: [
            Text(
              summary.topic.symbol,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                summary.topic.label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            MasteryPill(mastery: summary.mastery, compact: true),
            const SizedBox(width: 8),
            Text(
              '${summary.attempts} tries',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: summary.accuracy,
            minHeight: 8,
            backgroundColor: AppColors.surfaceSoft,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _AchievementPreview extends StatelessWidget {
  const _AchievementPreview({required this.profile});

  final MathProfile profile;

  @override
  Widget build(BuildContext context) {
    if (profile.achievements.isEmpty) {
      return const EmptyState(
        emoji: '🎖️',
        title: 'No badges yet',
        message: 'Finish a match to unlock your first badge.',
        compact: true,
      );
    }
    final items = profile.achievements.take(4).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final achievement in items)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purpleSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        achievementEmoji(achievement.icon),
                        style: const TextStyle(fontSize: 22, height: 1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          achievement.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentMatches extends StatelessWidget {
  const _RecentMatches({required this.matches});

  final List<MathMatchHistoryItem> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const EmptyState(
        emoji: '🎈',
        title: 'No matches played',
        message: 'Stats appear after the first completed clash.',
        compact: true,
      );
    }
    final theme = Theme.of(context);
    return CandyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (var i = 0; i < matches.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: matches[i].rank <= 3
                        ? AppColors.yellowSoft
                        : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _medal(matches[i].rank),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${matches[i].grade.label} · ${Formatters.topics(matches[i].topics)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${Formatters.relativeDate(matches[i].completedAt)} · '
                        '${matches[i].correctCount}/${matches[i].questionCount} correct',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${matches[i].points} pts',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _medal(int rank) {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };
  }
}
