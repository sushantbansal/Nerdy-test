import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/math_api_models.dart';
import '../../domain/models/math_models.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: false,
      background: CandyBackgroundStyle.sky,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Obx(() {
        final profile = controller.profile;
        if (profile == null) {
          if (controller.isLoading.value) {
            return const LoadingView(message: 'Loading your arena…');
          }
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: ErrorState(
              message: controller.error.value.isEmpty
                  ? 'Your profile could not be loaded.'
                  : controller.error.value,
              onRetry: controller.refresh,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(profile: profile, onProfile: controller.openProfile),
            const SizedBox(height: 16),
            _HeroCard(profile: profile),
            if (controller.activeRoom.value != null) ...[
              const SizedBox(height: 14),
              _ActiveRoomBanner(room: controller.activeRoom.value!),
            ],
            if (controller.isKindergarten) ...[
              const SizedBox(height: 14),
              _KindergartenGuide(
                needsTutorial: controller.needsTutorial,
                onStart: controller.openTutorial,
              ),
            ],
            const SizedBox(height: 22),
            const SectionHeader(
              eyebrow: 'Jump in',
              title: 'Pick your next move',
              emoji: '🎮',
            ),
            const _ActionGrid(),
            const SizedBox(height: 22),
            _ContinueLearning(profile: profile),
            const SizedBox(height: 22),
            SectionHeader(
              eyebrow: 'Friends & ranks',
              title: 'This week',
              emoji: '🏆',
              trailing: TextButton(
                onPressed: controller.openLeaderboards,
                child: const Text('See all'),
              ),
            ),
            _WeeklyBoard(),
            const SizedBox(height: 22),
            SectionHeader(
              eyebrow: 'History',
              title: 'Recent clashes',
              emoji: '🗂️',
              trailing: profile.recentMatches.isEmpty
                  ? null
                  : TextButton(
                      onPressed: controller.openProfile,
                      child: const Text('Profile'),
                    ),
            ),
            _RecentMatches(matches: profile.recentMatches),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Play smart. Clash kindly. 💙',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.profile, required this.onProfile});

  final MathProfile profile;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: onProfile,
          child: PlayerAvatar(
            avatarIndex: profile.avatarIndex,
            avatarColor: profile.avatarColor,
            size: 54,
            displayName: profile.displayName,
            showRing: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${profile.displayName.split(' ').first}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
              Text(
                '${profile.grade.label} · Level ${profile.level}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Obx(() {
          final home = Get.find<HomeController>();
          return _RankBadge(
            rank: home.weeklyRank.value,
            loading: home.isLoading.value,
          );
        }),
        const SizedBox(width: 4),
        IconButton(
          onPressed: Get.find<HomeController>().openSettings,
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.ink,
            side: BorderSide(color: AppColors.outline, width: 2),
          ),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.loading});

  final int rank;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && rank == 0) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (rank == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.yellow, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏅', style: TextStyle(fontSize: 12, height: 1)),
          const SizedBox(width: 4),
          Text(
            '#$rank',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.yellowDark),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile});

  final MathProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.30),
            offset: const Offset(0, 8),
            blurRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.16),
            offset: const Offset(0, 16),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY TO CLASH?',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your brain vs.\nthe room.',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.02,
                      ),
                    ),
                  ],
                ),
              ),
              const Text('⚡', style: TextStyle(fontSize: 62, height: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: XpProgress(
              xp: profile.xp,
              level: profile.level,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroStat(
                value: '${profile.gamesPlayed}',
                label: 'matches',
                emoji: '🎯',
              ),
              _HeroStat(value: '${profile.wins}', label: 'wins', emoji: '👑'),
              _HeroStat(
                value: Formatters.percent(profile.accuracy),
                label: 'accuracy',
                emoji: '🧠',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final home = Get.find<HomeController>();
            // Read the observable unconditionally so this Obx always has a
            // subscription, even for players who only see one button.
            final isQuickPlaying = home.isQuickPlaying.value;
            final kindergarten = profile.grade == GradeLevel.kindergarten;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ArcadeButton(
                  label: kindergarten ? 'Start learning' : 'Play now',
                  icon: kindergarten
                      ? Icons.school_rounded
                      : Icons.bolt_rounded,
                  variant: ArcadeButtonVariant.yellow,
                  size: ArcadeButtonSize.large,
                  expand: true,
                  loading: isQuickPlaying,
                  onPressed: kindergarten ? home.openPractice : home.quickPlay,
                ),
                if (kindergarten) ...[
                  const SizedBox(height: 8),
                  ArcadeButton(
                    label: 'Play with friends',
                    icon: Icons.sports_esports_rounded,
                    variant: ArcadeButtonVariant.outline,
                    size: ArcadeButtonSize.medium,
                    expand: true,
                    loading: isQuickPlaying,
                    onPressed: home.quickPlay,
                  ),
                ],
              ],
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: Text(
              profile.grade == GradeLevel.kindergarten
                  ? 'No timer · pictures & voice'
                  : '5 quick questions · speed bonus on',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
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
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16, height: 1)),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 9,
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

class _ActiveRoomBanner extends StatelessWidget {
  const _ActiveRoomBanner({required this.room});

  final MathActiveRoom room;

  @override
  Widget build(BuildContext context) {
    final inProgress = room.status.isActiveMatch;
    return CandyCard(
      color: AppColors.yellowSoft,
      borderColor: AppColors.yellow,
      padding: const EdgeInsets.all(14),
      onTap: () => Get.find<HomeController>().openRoom(room),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              inProgress ? '⚔️' : '🪑',
              style: const TextStyle(fontSize: 22, height: 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inProgress ? 'Match in progress' : 'Your room is waiting',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${room.name} · ${Formatters.roomCode(room.roomCode)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.yellowDark),
        ],
      ),
    );
  }
}

class _KindergartenGuide extends StatelessWidget {
  const _KindergartenGuide({
    required this.needsTutorial,
    required this.onStart,
  });

  final bool needsTutorial;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CandyCard(
      color: AppColors.yellowSoft,
      borderColor: AppColors.yellow,
      padding: const EdgeInsets.all(16),
      onTap: onStart,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              needsTutorial ? '🦊' : '✅',
              style: const TextStyle(fontSize: 26, height: 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  needsTutorial
                      ? 'New here? Learn to play'
                      : 'Tutorial complete',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  needsTutorial
                      ? 'Tap, count and choose with the friendly fox.'
                      : 'Play it again whenever you want a warm-up.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.yellowDark),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    final actions = [
      if (home.isKindergarten)
        _Action(
          emoji: '🦊',
          title: 'How to play',
          subtitle: '3 easy moves',
          color: AppColors.primaryLight,
          onTap: home.openTutorial,
        ),
      _Action(
        emoji: '🏗️',
        title: 'Create room',
        subtitle: 'Pick grade & topics',
        color: AppColors.primary,
        onTap: home.openCreate,
      ),
      _Action(
        emoji: '🔑',
        title: 'Join code',
        subtitle: 'Enter a 6-letter code',
        color: AppColors.purple,
        onTap: home.openJoin,
      ),
      _Action(
        emoji: '🧭',
        title: 'Browse rooms',
        subtitle: 'Find a public clash',
        color: AppColors.mintDark,
        onTap: home.openBrowse,
      ),
      _Action(
        emoji: '🎯',
        title: 'Practice',
        subtitle: home.isKindergarten
            ? 'No timer · pictures & voice'
            : 'Adaptive solo drills',
        color: AppColors.pink,
        onTap: () => home.openPractice(),
      ),
      _Action(
        emoji: '🏆',
        title: 'Leaderboards',
        subtitle: 'Weekly & all-time',
        color: AppColors.yellowDark,
        onTap: home.openLeaderboards,
      ),
      _Action(
        emoji: '🎖️',
        title: 'Achievements',
        subtitle: 'Badges & XP',
        color: AppColors.purpleDark,
        onTap: home.openAchievements,
      ),
      _Action(
        emoji: '🧠',
        title: 'Learning progress',
        subtitle: 'Mastery by topic',
        color: AppColors.primaryDark,
        onTap: home.openProgress,
      ),
      _Action(
        emoji: '🦊',
        title: 'Profile',
        subtitle: 'Stats & settings',
        color: AppColors.mint,
        onTap: home.openProfile,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: _ActionTile(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _Action {
  const _Action({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _Action action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CandyCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      onTap: action.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                action.color.withValues(alpha: 0.14),
                AppColors.surface,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              action.emoji,
              style: const TextStyle(fontSize: 21, height: 1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            action.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            action.subtitle,
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.inkSoft,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueLearning extends StatelessWidget {
  const _ContinueLearning({required this.profile});

  final MathProfile profile;

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    final topic = home.recommendedTopic;
    final accuracy = home.recommendedAccuracy;
    final matches = profile.skills.where((s) => s.topic == topic).toList();
    final skill = matches.isEmpty ? null : matches.first;
    final mastery = skill?.mastery ?? MasteryLevel.notStarted;
    final color = topicColor(topic);
    final theme = Theme.of(context);

    return CandyCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    color.withValues(alpha: 0.15),
                    AppColors.surface,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  topic.symbol,
                  style: TextStyle(
                    fontSize: 24,
                    color: color,
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
                      'Continue learning',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.inkSoft,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(topic.label, style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
              MasteryPill(mastery: mastery, compact: true),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: accuracy,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                accuracy == 0
                    ? 'New skill'
                    : Formatters.percent(accuracy * 100),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Practice adapts to your level — perfect for a quick warm-up.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ArcadeButton(
            label: 'Practice ${topic.label.toLowerCase()}',
            icon: Icons.play_arrow_rounded,
            variant: ArcadeButtonVariant.outline,
            size: ArcadeButtonSize.medium,
            expand: true,
            onPressed: () => home.openPractice(topic),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final home = Get.find<HomeController>();
      final entries = home.weeklyTop.take(3).toList();
      if (entries.isEmpty) {
        return const EmptyState(
          emoji: '🏁',
          title: 'The board is wide open',
          message: 'Finish two matches this week to appear on the leaderboard.',
          compact: true,
        );
      }
      return CandyCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              if (index > 0) const Divider(height: 14),
              _BoardRow(entry: entries[index]),
            ],
          ],
        ),
      );
    });
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.entry});

  final MathLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${entry.rank}',
    };
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            medal,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 1.3),
          ),
        ),
        const SizedBox(width: 6),
        PlayerAvatar(
          avatarIndex: entry.avatarIndex,
          avatarColor: entry.avatarColor,
          size: 34,
          displayName: entry.displayName,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${entry.wins} wins · ${Formatters.percent(entry.accuracy)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        Text(
          '${entry.points}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.yellowDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 3),
        Text('pts', style: Theme.of(context).textTheme.labelSmall),
      ],
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
        title: 'No matches yet',
        message:
            'Your first clash is one tap away. Invite a friend or join a room!',
        compact: true,
      );
    }
    final theme = Theme.of(context);
    return CandyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (var i = 0; i < matches.take(3).length; i++) ...[
            if (i > 0) const Divider(height: 18),
            Builder(
              builder: (context) {
                final match = matches[i];
                final podium = match.rank <= 3;
                return Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: podium
                            ? AppColors.yellowSoft
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        podium ? '#${match.rank}' : '${match.rank}th',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: podium
                              ? AppColors.yellowDark
                              : AppColors.inkSoft,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${match.grade.label} · ${Formatters.topics(match.topics)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${Formatters.relativeDate(match.completedAt)} · ${match.correctCount}/${match.questionCount} correct',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${match.points} pts',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
