import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/math_api_models.dart';
import '../../domain/models/math_models.dart';
import 'match_controller.dart';

class MatchView extends GetView<MatchController> {
  const MatchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final snapshot = controller.snapshot;
      if (snapshot == null) {
        if (controller.isLoading.value || controller.error.value.isEmpty) {
          return const AppScaffold(
            showBack: false,
            scrollable: false,
            child: LoadingView(message: 'Starting the clash…'),
          );
        }
        return AppScaffold(
          showBack: false,
          background: CandyBackgroundStyle.pink,
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: ErrorState(
              message: controller.error.value,
              onRetry: controller.goHome,
              retryLabel: 'Back home',
            ),
          ),
        );
      }

      final phase = controller.phase;
      final isFinal = phase == RoomPhase.finalResults;
      return AppScaffold(
        title: _title(phase),
        subtitle: snapshot.room.name,
        showBack: false,
        scrollable: isFinal,
        background: _background(phase),
        actions: [
          IconButton(
            onPressed: () => _confirmLeave(context),
            tooltip: 'Leave match',
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.inkSoft,
              side: BorderSide(color: AppColors.outline, width: 2),
            ),
          ),
        ],
        child: AnimatedSwitcher(
          duration: controller.reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          child: KeyedSubtree(
            key: ValueKey(phase),
            child: switch (phase) {
              RoomPhase.countdown => _CountdownPhase(snapshot: snapshot),
              RoomPhase.questionActive => _QuestionPhase(snapshot: snapshot),
              RoomPhase.questionReveal => _RevealPhase(snapshot: snapshot),
              RoomPhase.nextQuestion => _NextQuestionPhase(snapshot: snapshot),
              RoomPhase.finalResults => _FinalResults(snapshot: snapshot),
              _ => const EmptyState(
                emoji: '🏁',
                title: 'This match is over',
                message: 'Head home to start a fresh clash.',
              ),
            },
          ),
        ),
      );
    });
  }

  String _title(RoomPhase phase) {
    return switch (phase) {
      RoomPhase.countdown => 'Get ready!',
      RoomPhase.questionActive =>
        'Question ${controller.questionNumber} of ${controller.questionCount}',
      RoomPhase.questionReveal => 'Let’s check',
      RoomPhase.nextQuestion => 'Next up…',
      RoomPhase.finalResults => 'Final results',
      _ => 'Match',
    };
  }

  CandyBackgroundStyle _background(RoomPhase phase) {
    return switch (phase) {
      RoomPhase.countdown => CandyBackgroundStyle.hero,
      RoomPhase.questionActive => CandyBackgroundStyle.sky,
      RoomPhase.questionReveal => CandyBackgroundStyle.mint,
      RoomPhase.nextQuestion => CandyBackgroundStyle.hero,
      RoomPhase.finalResults => CandyBackgroundStyle.warm,
      _ => CandyBackgroundStyle.sky,
    };
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the match?'),
        content: const Text(
          'You will keep the points you have already earned, but you will '
          'not be able to answer the remaining questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorDark),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true) {
      await controller.leaveRoom();
    }
  }
}

// ---------------------------------------------------------------------------
// Countdown
// ---------------------------------------------------------------------------

class _CountdownPhase extends StatelessWidget {
  const _CountdownPhase({required this.snapshot});

  final MathRoomState snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<MatchController>();
    final kindergarten = controller.isKindergarten;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.14),
                  offset: const Offset(0, 10),
                  blurRadius: 30,
                ),
              ],
            ),
            child: _LiveCountdown(size: 128, label: 'seconds'),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          kindergarten
              ? 'Look and tap!\nCollect ⭐'
              : 'Brains ready?\nLet’s clash!',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 6),
        Text(
          kindergarten
              ? 'Take your time. ${snapshot.room.answerSeconds} seconds each.'
              : '${snapshot.room.questionCount} questions · '
                    '${snapshot.room.answerSeconds}s each',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
        ),
        if (kindergarten) ...[
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _KGoalPath(animate: !controller.reducedMotion),
          const SizedBox(height: 16),
          CandyCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('🐾 Animal friends', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (final player in snapshot.players)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlayerAvatar(
                            avatarIndex: player.avatarIndex,
                            avatarColor: player.avatarColor,
                            size: 58,
                            displayName: player.displayName,
                            isHost: player.isHost,
                            showRing:
                                player.playerId == controller.currentPlayerId,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 74,
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
          ),
        ] else ...[
          const SizedBox(height: 24),
          CandyCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var i = 0; i < snapshot.players.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  PlayerScoreChip(
                    displayName: snapshot.players[i].displayName,
                    avatarIndex: snapshot.players[i].avatarIndex,
                    avatarColor: snapshot.players[i].avatarColor,
                    isHost: snapshot.players[i].isHost,
                    isMe:
                        snapshot.players[i].playerId ==
                        controller.currentPlayerId,
                    subtitle: snapshot.players[i].isReady
                        ? 'Ready'
                        : 'Getting set',
                    trailing: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.mintDark,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          kindergarten
              ? 'Same questions for everyone. No speed bonus unless a grown-up turns it on.'
              : 'The same question appears for everyone at the same time.',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _KGoalPath extends StatelessWidget {
  const _KGoalPath({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = const [
      (emoji: '✋', label: 'Tap'),
      (emoji: '⭐', label: 'Stars'),
      (emoji: '🏆', label: 'Results'),
    ];
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.yellowDark,
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                steps[i].emoji,
                style: const TextStyle(fontSize: 30, height: 1),
              ),
              Text(
                steps[i].label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ],
    );
    if (!animate) return row;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: row,
    );
  }
}

// ---------------------------------------------------------------------------
// Question
// ---------------------------------------------------------------------------

class _QuestionPhase extends StatelessWidget {
  const _QuestionPhase({required this.snapshot});

  final MathRoomState snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = snapshot.question;
    if (question == null) {
      return const LoadingView(message: 'Loading the question…');
    }
    final matchController = Get.find<MatchController>();
    final kindergarten = matchController.isKindergarten;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionHeader(snapshot: snapshot),
        const SizedBox(height: 14),
        if (!kindergarten) ...[
          _ScoreStrip(snapshot: snapshot),
          const SizedBox(height: 14),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.outline, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.06),
                offset: const Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              if (!kindergarten) ...[
                Row(
                  children: [
                    TopicPill(topic: question.topic, compact: true),
                    const Spacer(),
                    if (snapshot.room.speedBonusEnabled)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 15,
                            color: AppColors.yellowDark,
                          ),
                          Text(
                            'Speed bonus',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.yellowDark,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              Text(
                question.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: kindergarten ? 34 : 26,
                  height: 1.2,
                ),
              ),
              if (question.visual != null) ...[
                const SizedBox(height: 16),
                MathVisual(
                  type: '${question.visual!['type']}',
                  data:
                      (question.visual!['data'] as Map?)
                          ?.cast<String, dynamic>() ??
                      const {},
                  height: kindergarten ? 200 : 140,
                  scale: kindergarten ? 1.6 : 1,
                ),
              ],
              if (kindergarten &&
                  matchController.questionNarration != null) ...[
                const SizedBox(height: 12),
                NarrationBar(
                  text: matchController.questionNarration!,
                  autoPlay: true,
                  label: 'Hear it again',
                  compact: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final controller = Get.find<MatchController>();
          return Column(
            children: [
              if (controller.isKindergarten)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < question.options.length; i++)
                          SizedBox(
                            width: width,
                            child: AnswerOptionCard(
                              answer: question.options[i],
                              index: i,
                              large: true,
                              state: controller.optionState(
                                question.options[i],
                              ),
                              disabled: controller.optionsLocked,
                              onTap: controller.optionsLocked
                                  ? null
                                  : () => controller.submitAnswer(
                                      question.options[i],
                                    ),
                            ),
                          ),
                      ],
                    );
                  },
                )
              else
                for (var i = 0; i < question.options.length; i++) ...[
                  AnswerOptionCard(
                    answer: question.options[i],
                    index: i,
                    state: controller.optionState(question.options[i]),
                    disabled: controller.optionsLocked,
                    onTap: controller.optionsLocked
                        ? null
                        : () => controller.submitAnswer(question.options[i]),
                  ),
                  const SizedBox(height: 12),
                ],
              if (controller.hasAnswered)
                InlineBanner(
                  message: controller.phase == RoomPhase.questionActive
                      ? 'Answer locked in! Waiting for the other players…'
                      : 'Answer locked in.',
                  icon: Icons.lock_clock_rounded,
                  color: AppColors.mintDark,
                  background: AppColors.mintSoft,
                )
              else if (!controller.isKindergarten)
                Text(
                  'Tap an answer to lock it in.',
                  style: theme.textTheme.labelSmall,
                ),
              if (controller.isSubmitting.value)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(height: 3, child: LinearProgressIndicator()),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.snapshot});

  final MathRoomState snapshot;

  @override
  Widget build(BuildContext context) {
    final questions = snapshot.match?.questionCount ?? 5;
    final current = snapshot.match?.questionIndex ?? 1;
    final kindergarten = Get.find<MatchController>().isKindergarten;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kindergarten
                    ? '⭐ $current / $questions'
                    : 'QUESTION $current OF $questions',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryDark,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i < questions; i++)
                    Container(
                      width: i == current - 1 ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i < current
                            ? AppColors.primary
                            : AppColors.outline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        _LiveCountdown(size: 66),
      ],
    );
  }
}

class _LiveCountdown extends StatelessWidget {
  const _LiveCountdown({required this.size, this.label});

  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MatchController>();
    return Obx(
      () => CountdownRing(
        remaining: controller.remaining,
        total: controller.phaseTotal,
        size: size,
        label: label,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reveal
// ---------------------------------------------------------------------------

class _RevealPhase extends StatelessWidget {
  const _RevealPhase({required this.snapshot});

  final MathRoomState snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reveal = snapshot.reveal;
    if (reveal == null) {
      return const LoadingView(message: 'Checking the answers…');
    }
    final controller = Get.find<MatchController>();
    final mine = controller.playerResult(controller.currentPlayerId);
    final correct = mine?.isCorrect ?? false;
    final points = mine?.points ?? 0;
    final speedBonus = mine?.speedBonus ?? false;
    final kindergarten = controller.isKindergarten;
    final visual = snapshot.question?.visual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                correct
                    ? 'Nailed it! 🎉'
                    : (kindergarten
                          ? 'Let’s look together 💡'
                          : 'Let’s learn it 💡'),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            _LiveCountdown(size: 58),
          ],
        ),
        if (kindergarten && controller.revealNarration != null) ...[
          const SizedBox(height: 8),
          Center(
            child: NarrationBar(
              text: controller.revealNarration!,
              autoPlay: true,
              label: 'Say it again',
              compact: true,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline, width: 2),
          ),
          child: Column(
            children: [
              Text(
                'CORRECT ANSWER',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.mintDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                reveal.correctAnswer,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.mintDark,
                ),
              ),
              if (visual != null) ...[
                const SizedBox(height: 10),
                MathVisual(
                  type: '${visual['type']}',
                  data:
                      (visual['data'] as Map?)?.cast<String, dynamic>() ??
                      const {},
                  height: kindergarten ? 150 : 110,
                ),
              ],
              if (mine != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ResultPill(
                      label: correct ? 'Correct' : 'Not this time',
                      color: correct ? AppColors.mintDark : AppColors.errorDark,
                      emoji: correct ? '✅' : '💭',
                    ),
                    const SizedBox(width: 8),
                    _ResultPill(
                      label: kindergarten
                          ? '+$points'
                          : '+$points ${points == 1 ? 'point' : 'points'}',
                      color: AppColors.yellowDark,
                      emoji: '⭐',
                    ),
                    if (speedBonus) ...[
                      const SizedBox(width: 8),
                      _ResultPill(
                        label: 'Speed +1',
                        color: AppColors.primaryDark,
                        emoji: '⚡',
                      ),
                    ],
                  ],
                ),
              ],
              if (reveal.speedBonusWithheldForTie) ...[
                const SizedBox(height: 8),
                Text(
                  'Dead heat — the speed bonus was withheld.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        CandyCard(
          color: AppColors.yellowSoft,
          borderColor: AppColors.yellow,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🧠', style: TextStyle(fontSize: 22, height: 1.2)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reveal.explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader(
          eyebrow: 'This question',
          title: 'How everyone did',
          emoji: '👀',
        ),
        CandyCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (var i = 0; i < reveal.results.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _RevealRow(
                  result: reveal.results[i],
                  fastestPlayerId: reveal.fastestPlayerId,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _MiniLeaderboard(leaderboard: snapshot.leaderboard),
      ],
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({
    required this.label,
    required this.color,
    required this.emoji,
  });

  final String label;
  final Color color;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.12),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12, height: 1)),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _RevealRow extends StatelessWidget {
  const _RevealRow({required this.result, required this.fastestPlayerId});

  final MathRevealPlayerResult result;
  final String? fastestPlayerId;

  @override
  Widget build(BuildContext context) {
    final fastest = result.playerId == fastestPlayerId;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: result.isCorrect ? AppColors.mintSoft : AppColors.errorSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            result.isCorrect ? '✓' : '—',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: result.isCorrect
                  ? AppColors.mintDark
                  : AppColors.errorDark,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      result.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (fastest) ...[
                    const SizedBox(width: 6),
                    const Text('⚡', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
              Text(
                result.submitted
                    ? '${result.answer} · ${Formatters.responseTime(result.responseMs)}'
                    : 'No answer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        Text(
          '+${result.points}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: result.points > 0
                ? AppColors.primaryDark
                : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _MiniLeaderboard extends StatelessWidget {
  const _MiniLeaderboard({required this.leaderboard});

  final List<MathStanding> leaderboard;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (var i = 0; i < leaderboard.length; i++) ...[
            if (i > 0) const Divider(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    _medal(leaderboard[i].rank),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 6),
                PlayerAvatar(
                  avatarIndex: leaderboard[i].avatarIndex,
                  avatarColor: leaderboard[i].avatarColor,
                  size: 30,
                  displayName: leaderboard[i].displayName,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    leaderboard[i].displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${leaderboard[i].points} pts',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
}

String _medal(int rank) {
  return switch (rank) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '$rank',
  };
}

// ---------------------------------------------------------------------------
// Between questions
// ---------------------------------------------------------------------------

class _NextQuestionPhase extends StatelessWidget {
  const _NextQuestionPhase({required this.snapshot});

  final MathRoomState snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(child: _LiveCountdown(size: 112)),
        const SizedBox(height: 20),
        Text(
          'Next question coming up',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Keep your eyes on the prize.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 26),
        _MiniLeaderboard(leaderboard: snapshot.leaderboard),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class _FinalResults extends StatelessWidget {
  const _FinalResults({required this.snapshot});

  final MathRoomState snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<MatchController>();
    final results = snapshot.finalResults;
    if (results == null) {
      return const LoadingView(message: 'Adding up the scores…');
    }
    final standings = results.standings;
    final mine = controller.myStanding;
    final rank = mine?.rank ?? standings.length;
    final isHost = snapshot.room.isHost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _Podium(standings: standings),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: rank == 1
                  ? AppColors.podiumGradient
                  : [AppColors.primarySoft, AppColors.surface],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: rank == 1 ? AppColors.yellowDark : AppColors.outline,
              width: 2.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                rank == 1
                    ? 'You are the clash champion! 🏆'
                    : 'Great clash! You finished #$rank',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SummaryStat(
                    label: 'Correct',
                    value:
                        '${mine?.correctCount ?? 0}/${snapshot.match?.questionCount ?? 5}',
                  ),
                  _SummaryStat(
                    label: controller.isKindergarten ? 'Stars' : 'Points',
                    value: '${mine?.points ?? 0}',
                  ),
                  _SummaryStat(
                    label: 'Speed',
                    value: '${mine?.speedBonusCount ?? 0}⚡',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PersonalProgressCard(
          correct: mine?.correctCount ?? 0,
          total: snapshot.match?.questionCount ?? 5,
          points: mine?.points ?? 0,
          bestPoints: controller.myProfile?.bestMatchPoints,
          isKindergarten: controller.isKindergarten,
          onPractice: () => controller.practiseMore(
            topic: results.review.isNotEmpty
                ? results.review.first.topic
                : null,
          ),
          onProgress: controller.openProgress,
        ),
        const SizedBox(height: 18),
        const SectionHeader(
          eyebrow: 'Standings',
          title: 'Final table',
          emoji: '📊',
        ),
        CandyCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (var i = 0; i < standings.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                PlayerScoreChip(
                  displayName: standings[i].displayName,
                  avatarIndex: standings[i].avatarIndex,
                  avatarColor: standings[i].avatarColor,
                  points: standings[i].points,
                  rank: standings[i].rank,
                  isMe: standings[i].playerId == controller.currentPlayerId,
                  subtitle:
                      '${standings[i].correctCount} correct · '
                      '${standings[i].speedBonusCount} speed',
                ),
              ],
            ],
          ),
        ),
        if (mine != null && mine.newAchievements.isNotEmpty) ...[
          const SizedBox(height: 18),
          CandyCard(
            color: AppColors.purpleSoft,
            borderColor: AppColors.purple,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🎖️', style: TextStyle(fontSize: 26, height: 1)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New badges unlocked!',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        mine.newAchievements
                            .map((code) => code.replaceAll('_', ' '))
                            .join(', '),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Get.toNamed('/achievements'),
                  child: const Text('View'),
                ),
              ],
            ),
          ),
        ],
        if (results.review.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionHeader(
            eyebrow: 'Learn',
            title: 'Question review',
            emoji: '📚',
            subtitle: 'Revisit every answer and explanation.',
          ),
          CandyCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final item in results.review) _ReviewTile(item: item),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        if (isHost)
          ArcadeButton(
            label: 'Rematch',
            icon: Icons.replay_rounded,
            size: ArcadeButtonSize.large,
            expand: true,
            loading: controller.isBusy.value,
            onPressed: controller.playAgain,
          )
        else
          InlineBanner(
            message: 'Waiting for the host to start a rematch…',
            icon: Icons.hourglass_top_rounded,
            color: AppColors.purpleDark,
            background: AppColors.purpleSoft,
          ),
        const SizedBox(height: 10),
        ArcadeButton(
          label: 'Back home',
          icon: Icons.home_rounded,
          variant: ArcadeButtonVariant.outline,
          expand: true,
          onPressed: controller.goHome,
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: controller.leaveRoom,
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Leave room'),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _PersonalProgressCard extends StatelessWidget {
  const _PersonalProgressCard({
    required this.correct,
    required this.total,
    required this.points,
    required this.isKindergarten,
    required this.onPractice,
    required this.onProgress,
    this.bestPoints,
  });

  final int correct;
  final int total;
  final int points;
  final int? bestPoints;
  final bool isKindergarten;
  final VoidCallback onPractice;
  final VoidCallback onProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = total == 0 ? 0.0 : correct / total;
    final percent = (accuracy * 100).round();
    final best = bestPoints ?? 0;
    return CandyCard(
      color: AppColors.primarySoft,
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 22, height: 1)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your progress',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                'This match',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKindergarten
                ? 'You answered $correct of $total. Every try helps your '
                      'number brain grow.'
                : 'You answered $correct of $total correctly. Keep building '
                      'your streak.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: accuracy,
              minHeight: 10,
              backgroundColor: AppColors.surface,
              color: AppColors.mintDark,
              semanticsLabel: 'Personal progress: $correct of $total correct',
              semanticsValue: '$percent',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryStat(label: 'Correct', value: '$correct/$total'),
              _SummaryStat(label: 'Accuracy', value: '$percent%'),
              _SummaryStat(
                label: 'Personal best',
                value:
                    '${best > points ? best : points} '
                    '${isKindergarten ? '⭐' : 'pts'}',
              ),
            ],
          ),
          if (best > 0 && points > best) ...[
            const SizedBox(height: 10),
            InlineBanner(
              message: 'New personal best! You beat $best points.',
              icon: Icons.trending_up_rounded,
              color: AppColors.yellowDark,
              background: AppColors.yellowSoft,
            ),
          ],
          const SizedBox(height: 10),
          if (isKindergarten) ...[
            ArcadeButton(
              label: 'Practise with pictures',
              icon: Icons.image_rounded,
              variant: ArcadeButtonVariant.yellow,
              size: ArcadeButtonSize.medium,
              expand: true,
              onPressed: onPractice,
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: onProgress,
                icon: const Icon(Icons.insights_rounded, size: 18),
                label: const Text('See all my progress'),
              ),
            ),
          ] else
            ArcadeButton(
              label: 'See my progress',
              icon: Icons.insights_rounded,
              variant: ArcadeButtonVariant.outline,
              size: ArcadeButtonSize.medium,
              expand: true,
              onPressed: onProgress,
            ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.standings});

  final List<MathStanding> standings;

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) return const SizedBox.shrink();
    final top = standings.take(3).toList();
    final order = <MathStanding>[
      if (top.length > 1) top[1],
      top[0],
      if (top.length > 2) top[2],
    ];
    return SizedBox(
      height: 262,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final standing in order)
            Expanded(
              child: _PodiumPlace(
                standing: standing,
                height: standing.rank == 1
                    ? 112
                    : standing.rank == 2
                    ? 86
                    : 70,
              ),
            ),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({required this.standing, required this.height});

  final MathStanding standing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = standing.rank == 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (first) const Text('👑', style: TextStyle(fontSize: 22, height: 1)),
        PlayerAvatar(
          avatarIndex: standing.avatarIndex,
          avatarColor: standing.avatarColor,
          size: first ? 68 : 54,
          displayName: standing.displayName,
          showRing: true,
          ringColor: first ? AppColors.yellow : AppColors.primary,
        ),
        const SizedBox(height: 5),
        Text(
          standing.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        Text(
          '${standing.points} pts',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.yellowDark,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: first
                ? LinearGradient(
                    colors: AppColors.podiumGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : LinearGradient(
                    colors: [
                      Color.alphaBlend(
                        AppColors.primary.withValues(alpha: 0.18),
                        AppColors.surface,
                      ),
                      AppColors.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: first ? AppColors.yellowDark : AppColors.outline,
              width: 2,
            ),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _medal(standing.rank),
            style: const TextStyle(fontSize: 20, height: 1),
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.ink),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.item});

  final MathReviewItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = item.myAnswer == item.correctAnswer;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: correct ? AppColors.mintSoft : AppColors.errorSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            correct ? '✓' : '✗',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: correct ? AppColors.mintDark : AppColors.errorDark,
            ),
          ),
        ),
        title: Text(
          'Q${item.position}. ${item.questionText}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
        ),
        subtitle: Text(
          item.myAnswer == null ? 'No answer' : 'You answered ${item.myAnswer}',
          style: theme.textTheme.labelSmall,
        ),
        children: [
          if (item.visual != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MathVisual(
                type: '${item.visual!['type']}',
                data:
                    (item.visual!['data'] as Map?)?.cast<String, dynamic>() ??
                    const {},
                height: 110,
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in item.options)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: option == item.correctAnswer
                          ? AppColors.mintSoft
                          : option == item.myAnswer
                          ? AppColors.errorSoft
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: option == item.correctAnswer
                            ? AppColors.mintDark
                            : AppColors.outline,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      option,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: option == item.correctAnswer
                            ? AppColors.mintDark
                            : AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(item.explanation, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.snapshot});

  final MathRoomState snapshot;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MatchController>();
    final order = [...snapshot.players]
      ..sort((a, b) => b.points.compareTo(a.points));
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: order.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final player = order[index];
          final isMe = player.playerId == controller.currentPlayerId;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primarySoft : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isMe ? AppColors.primary : AppColors.outline,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                PlayerAvatar(
                  avatarIndex: player.avatarIndex,
                  avatarColor: player.avatarColor,
                  size: 32,
                  displayName: player.displayName,
                  isHost: player.isHost,
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Row(
                      children: [
                        Text(
                          '${player.points} pts',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.yellowDark,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (player.submittedCurrent) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 11,
                            color: AppColors.mintDark,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
