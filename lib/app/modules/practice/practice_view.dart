import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/math_api_models.dart';
import '../../domain/models/math_models.dart';
import 'practice_controller.dart';

class PracticeView extends GetView<PracticeController> {
  const PracticeView({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.isYoungLearner) {
      return _LearningPractice(controller: controller);
    }
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Practice arena',
      subtitle: 'Adaptive drills — no timer pressure.',
      background: CandyBackgroundStyle.mint,
      actions: [
        IconButton(
          onPressed: controller.loadNext,
          tooltip: 'Skip question',
          icon: const Icon(Icons.skip_next_rounded),
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
          _PracticeStats(),
          const SizedBox(height: 14),
          _SetupCard(),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isLoading.value &&
                controller.question.value == null) {
              return const LoadingView(message: 'Finding a good question…');
            }
            if (controller.error.value.isNotEmpty &&
                controller.question.value == null) {
              return ErrorState(
                message: controller.error.value,
                onRetry: controller.loadNext,
              );
            }
            final question = controller.question.value;
            if (question == null) {
              return const EmptyState(
                emoji: '🧠',
                title: 'No question yet',
                message: 'Tap below to start a practice round.',
                actionLabel: 'Load a question',
              );
            }
            return _QuestionCard(question: question);
          }),
          const SizedBox(height: 16),
          Obx(() {
            final result = controller.result.value;
            if (result == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResultCard(result: result, theme: theme),
                const SizedBox(height: 14),
                ArcadeButton(
                  label: controller.isKindergarten
                      ? 'Try another picture'
                      : 'Next question',
                  icon: Icons.arrow_forward_rounded,
                  size: ArcadeButtonSize.large,
                  expand: true,
                  loading: controller.isLoading.value,
                  onPressed: controller.loadNext,
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Practice is private. It never changes your leaderboard points.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PracticeController>();
    return Obx(
      () => CandyCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: QuickStat(
                value: '${controller.correctCount.value}',
                label: 'correct',
                emoji: '✅',
                color: AppColors.mintDark,
              ),
            ),
            Expanded(
              child: QuickStat(
                value: '${controller.answeredCount.value}',
                label: 'answered',
                emoji: '📝',
                color: AppColors.primaryDark,
              ),
            ),
            Expanded(
              child: QuickStat(
                value: '${(controller.accuracy * 100).round()}%',
                label: 'accuracy',
                emoji: '🎯',
                color: AppColors.yellowDark,
              ),
            ),
            Expanded(
              child: QuickStat(
                value: '${controller.streak.value}',
                label: 'streak',
                emoji: '🔥',
                color: AppColors.pinkDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<PracticeController>();
    return CandyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Grade', style: theme.textTheme.titleSmall),
              const Spacer(),
              Obx(
                () => GradePill(grade: controller.grade.value, compact: true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Focus', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TopicChip(
                  label: 'Adaptive mix',
                  emoji: '🧠',
                  selected: controller.topic.value == null,
                  onTap: () => controller.setTopic(null),
                ),
                for (final topic in controller.availableTopics)
                  if (topic != MathTopic.mixed)
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

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.emoji,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectionSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.selectionSurface : AppColors.outline,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13, height: 1)),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.onSelection : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final MathPracticeQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<PracticeController>();
    final visual = question.visual;
    return CandyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              TopicPill(topic: question.topic, compact: true),
              const Spacer(),
              DifficultyPill(difficulty: question.difficulty, compact: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 27,
              height: 1.25,
            ),
          ),
          if (visual != null) ...[
            const SizedBox(height: 16),
            MathVisual(
              type: '${visual['type']}',
              data:
                  (visual['data'] as Map?)?.cast<String, dynamic>() ?? const {},
              height: controller.isKindergarten ? 168 : 140,
            ),
          ],
          if (controller.isKindergarten &&
              controller.questionNarration != null) ...[
            const SizedBox(height: 12),
            Center(
              child: NarrationBar(
                text: controller.questionNarration!,
                autoPlay: true,
                label: 'Hear it again',
                compact: true,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Obx(() {
            if (controller.hasAnswered) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                label: 'Drop the answer here',
                child: DragTarget<String>(
                  onAcceptWithDetails: (details) {
                    if (!controller.hasAnswered &&
                        !controller.isSubmitting.value) {
                      controller.submit(details.data);
                    }
                  },
                  builder: (context, candidate, rejected) {
                    final active = candidate.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      height: 56,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primarySoft
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.outline,
                          width: active ? 3 : 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            active ? '✨' : '👇',
                            style: const TextStyle(fontSize: 20, height: 1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            active ? 'Let go!' : 'Drop answer here',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: active
                                      ? AppColors.primaryDark
                                      : AppColors.inkSoft,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
          Obx(() {
            return Column(
              children: [
                for (var i = 0; i < question.options.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final card = AnswerOptionCard(
                        answer: question.options[i],
                        index: i,
                        state: controller.optionState(question.options[i]),
                        disabled:
                            controller.hasAnswered ||
                            controller.isSubmitting.value,
                        onTap: controller.hasAnswered
                            ? null
                            : () => controller.submit(question.options[i]),
                      );
                      if (controller.hasAnswered) return card;
                      return Draggable<String>(
                        data: question.options[i],
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 220,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 3,
                              ),
                            ),
                            child: Text(
                              question.options[i],
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(opacity: 0.35, child: card),
                        child: card,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          }),
          Obx(() {
            if (!controller.supportsTyping || controller.hasAnswered) {
              return const SizedBox.shrink();
            }
            if (controller.typingAnswer.value) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: controller.typedAnswerController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.submitTyped(),
                      decoration: const InputDecoration(
                        hintText: 'Type your answer',
                        prefixIcon: Icon(Icons.keyboard_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ArcadeButton(
                      label: 'Check my answer',
                      icon: Icons.check_rounded,
                      expand: true,
                      onPressed: controller.submitTyped,
                    ),
                  ],
                ),
              );
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.toggleTyping,
                icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
                label: const Text('Type the answer instead'),
              ),
            );
          }),
          Obx(() {
            final hint = question.hint;
            // Read the observables before the early return so the Obx keeps a
            // valid subscription when this question has no hint.
            final hintVisible = controller.hintVisible.value;
            final answered = controller.hasAnswered;
            if (hint == null || hint.isEmpty) return const SizedBox.shrink();
            if (!hintVisible && !answered) {
              return Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: controller.revealHint,
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  label: Text(
                    controller.isKindergarten
                        ? 'Show me a hint'
                        : 'Need a hint?',
                  ),
                ),
              );
            }
            return InlineBanner(
              message: hint,
              icon: Icons.lightbulb_rounded,
              color: AppColors.yellowDark,
              background: AppColors.yellowSoft,
            );
          }),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.theme});

  final MathPracticeResult result;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final correct = result.isCorrect;
    final controller = Get.find<PracticeController>();
    final kindergarten = controller.isKindergarten;
    final inkColor = correct
        ? AppColors.mintDark
        : (kindergarten ? AppColors.yellowDark : AppColors.errorDark);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: correct ? AppColors.mintSoft : AppColors.errorSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: correct ? AppColors.mintDark : AppColors.errorDark,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                correct ? '🎉' : '💡',
                style: const TextStyle(fontSize: 26, height: 1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  correct
                      ? (kindergarten ? 'You did it!' : 'Correct!')
                      : (kindergarten
                            ? 'Let’s look together'
                            : 'Not quite — here is the trick'),
                  style: theme.textTheme.titleLarge?.copyWith(color: inkColor),
                ),
              ),
              if (result.xpEarned > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${result.xpEarned} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Answer: ${result.correctAnswer}',
            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            result.explanation,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallBadge(
                label:
                    '${result.skillCorrect}/${result.skillAttempts} on this skill',
              ),
              _SmallBadge(label: 'Mastery: ${result.mastery.label}'),
              if (result.newAchievements.isNotEmpty)
                const _SmallBadge(label: '🎖️ New badge unlocked!'),
            ],
          ),
          if (kindergarten && controller.resultNarration != null) ...[
            const SizedBox(height: 12),
            NarrationBar(
              text: controller.resultNarration!,
              autoPlay: true,
              label: 'Say it again',
              compact: true,
            ),
            const SizedBox(height: 8),
            Text(
              correct
                  ? 'Count it once more, then try a new picture.'
                  : 'Count the pictures, then try a new one just like this.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

// ---------------------------------------------------------------------------
// Kindergarten learning mode
// ---------------------------------------------------------------------------

/// A picture-first practice flow for pre-readers:
/// look and count -> choose a big answer -> hear friendly feedback.
class _LearningPractice extends StatelessWidget {
  const _LearningPractice({required this.controller});

  final PracticeController controller;

  AppScaffold _scaffold({required Widget child, Widget? bottomBar}) {
    final kindergarten = controller.isKindergarten;
    return AppScaffold(
      title: kindergarten ? '⭐ Let’s learn' : 'Let’s learn',
      subtitle: kindergarten
          ? 'Look, listen, then tap.'
          : 'Look, listen, then choose.',
      background: CandyBackgroundStyle.mint,
      actions: [
        IconButton(
          onPressed: controller.trySimilar,
          tooltip: 'New picture',
          icon: const Icon(Icons.casino_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.ink,
            side: BorderSide(color: AppColors.outline, width: 2),
          ),
        ),
      ],
      bottomBar: bottomBar,
      child: child,
    );
  }

  Widget _withMultiplayer(Widget primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        primary,
        const SizedBox(height: 6),
        ArcadeButton(
          label: 'Play with friends',
          icon: Icons.groups_rounded,
          variant: ArcadeButtonVariant.outline,
          size: ArcadeButtonSize.medium,
          expand: true,
          onPressed: controller.openMultiplayer,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final question = controller.question.value;
      final result = controller.result.value;
      final answered = controller.answeredCount.value;
      final correct = controller.correctCount.value;
      final showAnswers = controller.showAnswerChoices.value;
      final narration = result != null
          ? controller.resultNarration
          : showAnswers
          ? controller.questionNarration
          : controller.lookNarration;

      if (controller.isLoading.value && question == null) {
        return _scaffold(
          child: const LoadingView(message: 'Getting a picture…'),
        );
      }
      if (controller.error.value.isNotEmpty && question == null) {
        return _scaffold(
          child: ErrorState(
            message: controller.error.value,
            onRetry: controller.loadNext,
          ),
        );
      }
      if (question == null) {
        return _scaffold(
          child: EmptyState(
            emoji: '🧸',
            title: 'Ready to play?',
            message: 'Tap below to see a picture.',
            actionLabel: 'Show a picture',
            onAction: controller.loadNext,
          ),
        );
      }

      Widget? bottomBar;
      if (result != null) {
        bottomBar = _withMultiplayer(
          ArcadeButton(
            label: result.isCorrect ? 'One more!' : 'Try a similar one',
            icon: Icons.replay_rounded,
            size: ArcadeButtonSize.large,
            variant: result.isCorrect
                ? ArcadeButtonVariant.primary
                : ArcadeButtonVariant.yellow,
            expand: true,
            loading: controller.isLoading.value,
            onPressed: controller.trySimilar,
          ),
        );
      } else if (!showAnswers) {
        bottomBar = _withMultiplayer(
          ArcadeButton(
            label: 'I’m ready',
            icon: Icons.check_circle_rounded,
            size: ArcadeButtonSize.large,
            expand: true,
            onPressed: controller.beginAnswering,
          ),
        );
      }

      return _scaffold(
        bottomBar: bottomBar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KStarStrip(correct: correct, answered: answered),
            const SizedBox(height: 12),
            if (result == null && !showAnswers) ...[
              if (controller.isKindergarten)
                _KGamePicker(controller: controller)
              else
                _LearningTopicPicker(controller: controller),
              const SizedBox(height: 12),
            ],
            if (narration != null) ...[
              Center(
                child: NarrationBar(
                  key: ValueKey(
                    'learning-narration-${question.id}-'
                    '${result != null
                        ? 'result'
                        : showAnswers
                        ? 'answer'
                        : 'look'}',
                  ),
                  text: narration,
                  autoPlay: true,
                  label: 'Hear it again',
                  compact: true,
                ),
              ),
              const SizedBox(height: 10),
            ],
            AnimatedSwitcher(
              duration: controller.reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOut,
              child: result != null
                  ? _KResultCard(
                      key: const ValueKey('learning-result'),
                      result: result,
                      question: question,
                      controller: controller,
                    )
                  : showAnswers
                  ? _KAnswerCard(
                      key: ValueKey('learning-answer-${question.id}'),
                      question: question,
                      controller: controller,
                    )
                  : _KLookCard(
                      key: ValueKey('learning-look-${question.id}'),
                      question: question,
                      kindergarten: controller.isKindergarten,
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _KStarStrip extends StatelessWidget {
  const _KStarStrip({required this.correct, required this.answered});

  final int correct;
  final int answered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KPill(
            emoji: '⭐',
            value: '$correct',
            label: 'stars',
            color: AppColors.yellowDark,
            background: AppColors.yellowSoft,
            border: AppColors.yellow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KPill(
            emoji: '🎯',
            value: '$answered',
            label: 'tried',
            color: AppColors.primaryDark,
            background: AppColors.primarySoft,
            border: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _KPill extends StatelessWidget {
  const _KPill({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    required this.border,
  });

  final String emoji;
  final String value;
  final String label;
  final Color color;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22, height: 1)),
            const SizedBox(width: 7),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningTopicPicker extends StatelessWidget {
  const _LearningTopicPicker({required this.controller});

  final PracticeController controller;

  String _emojiFor(MathTopic topic) => switch (topic) {
    MathTopic.addition => '➕',
    MathTopic.subtraction => '➖',
    MathTopic.multiplication => '✖️',
    MathTopic.division => '➗',
    MathTopic.fractions => '🍕',
    MathTopic.geometry => '🔺',
    MathTopic.measurement => '📏',
    MathTopic.placeValue => '🔢',
    MathTopic.mixed => '🎲',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _TopicChip(
          label: 'Mix',
          emoji: '🎲',
          selected: controller.topic.value == null,
          onTap: () => controller.setTopic(null),
        ),
        for (final topic in controller.availableTopics)
          if (topic != MathTopic.mixed)
            _TopicChip(
              label: topic.label,
              emoji: _emojiFor(topic),
              selected: controller.topic.value == topic,
              onTap: () => controller.setTopic(topic),
            ),
      ],
    );
  }
}

class _KGamePicker extends StatelessWidget {
  const _KGamePicker({required this.controller});

  final PracticeController controller;

  static const _games = <({String emoji, String label, MathTopic topic})>[
    (emoji: '🍎', label: 'Count', topic: MathTopic.mixed),
    (emoji: '➕', label: 'Add', topic: MathTopic.addition),
    (emoji: '➖', label: 'Take away', topic: MathTopic.subtraction),
    (emoji: '🔺', label: 'Shapes', topic: MathTopic.geometry),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final game in _games)
          _KGameButton(
            emoji: game.emoji,
            label: game.label,
            selected: (controller.topic.value ?? MathTopic.mixed) == game.topic,
            onTap: () => controller.setTopic(game.topic),
          ),
      ],
    );
  }
}

class _KGameButton extends StatelessWidget {
  const _KGameButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: selected ? AppColors.primarySoft : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 30, height: 1)),
          ),
        ),
      ),
    );
  }
}

class _KLookCard extends StatelessWidget {
  const _KLookCard({
    super.key,
    required this.question,
    required this.kindergarten,
  });

  final MathPracticeQuestion question;
  final bool kindergarten;

  @override
  Widget build(BuildContext context) {
    final visual = question.visual;
    return CandyCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          if (visual != null)
            MathVisual(
              type: '${visual['type']}',
              data:
                  (visual['data'] as Map?)?.cast<String, dynamic>() ?? const {},
              height: kindergarten ? 210 : 170,
              scale: kindergarten ? 1.8 : 1.0,
            )
          else
            Text(
              '🔢',
              style: TextStyle(fontSize: kindergarten ? 90 : 70, height: 1),
            ),
          const SizedBox(height: 14),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: kindergarten ? 32 : 30,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _KAnswerCard extends StatelessWidget {
  const _KAnswerCard({
    super.key,
    required this.question,
    required this.controller,
  });

  final MathPracticeQuestion question;
  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final visual = question.visual;
    return CandyCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          if (visual != null) ...[
            MathVisual(
              type: '${visual['type']}',
              data:
                  (visual['data'] as Map?)?.cast<String, dynamic>() ?? const {},
              height: 120,
              scale: 1.1,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 30, height: 1.2),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Drop the answer here',
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                if (!controller.hasAnswered && !controller.isSubmitting.value) {
                  controller.submit(details.data);
                }
              },
              builder: (context, candidate, rejected) {
                final active = candidate.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  height: 68,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primarySoft : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.outline,
                      width: active ? 3 : 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        active ? '✨' : '👇',
                        style: const TextStyle(fontSize: 24, height: 1),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        active ? 'Let go!' : 'Put it here',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: active
                              ? AppColors.primaryDark
                              : AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final shortAnswers = question.options.every(
                (option) => option.length <= 2,
              );
              final columns = shortAnswers
                  ? (question.options.length == 3 ? 3 : 2)
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < question.options.length; i++)
                    SizedBox(
                      width: width,
                      child: _answerCard(context, question.options[i], i),
                    ),
                ],
              );
            },
          ),
          if (controller.isSubmitting.value)
            const LinearProgressIndicator(minHeight: 3),
          Obx(() {
            if (!controller.supportsTyping || controller.hasAnswered) {
              return const SizedBox.shrink();
            }
            if (controller.typingAnswer.value) {
              return Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    TextField(
                      controller: controller.typedAnswerController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.submitTyped(),
                      decoration: const InputDecoration(
                        hintText: 'Type your answer',
                        prefixIcon: Icon(Icons.keyboard_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ArcadeButton(
                      label: 'Check my answer',
                      icon: Icons.check_rounded,
                      expand: true,
                      onPressed: controller.submitTyped,
                    ),
                  ],
                ),
              );
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.toggleTyping,
                icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
                label: const Text('Type the answer instead'),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _answerCard(BuildContext context, String option, int index) {
    final card = AnswerOptionCard(
      answer: option,
      index: index,
      large: true,
      state: controller.optionState(option),
      disabled: controller.hasAnswered || controller.isSubmitting.value,
      onTap: controller.hasAnswered ? null : () => controller.submit(option),
    );
    return Draggable<String>(
      data: option,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

class _KResultCard extends StatelessWidget {
  const _KResultCard({
    super.key,
    required this.result,
    required this.question,
    required this.controller,
  });

  final MathPracticeResult result;
  final MathPracticeQuestion question;
  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final correct = result.isCorrect;
    final kindergarten = controller.isKindergarten;
    final visual = question.visual;
    final color = correct ? AppColors.mintDark : AppColors.yellowDark;
    final background = correct ? AppColors.mintSoft : AppColors.yellowSoft;
    final border = correct ? AppColors.mintDark : AppColors.yellow;
    return CandyCard(
      color: background,
      borderColor: border,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _BounceIn(
            enabled: correct && !controller.reducedMotion,
            child: Text(
              kindergarten ? '🦊' : (correct ? '🎉' : '💡'),
              style: const TextStyle(fontSize: 68, height: 1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            correct
                ? 'Great job!'
                : kindergarten
                ? 'Let’s count together'
                : 'Let’s look together',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  correct ? '⭐' : '👉',
                  style: const TextStyle(fontSize: 24, height: 1),
                ),
                const SizedBox(width: 8),
                Text(
                  result.correctAnswer,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: color,
                    fontSize: 38,
                  ),
                ),
              ],
            ),
          ),
          if (visual != null) ...[
            const SizedBox(height: 12),
            _BounceIn(
              enabled: correct && !controller.reducedMotion,
              child: MathVisual(
                type: '${visual['type']}',
                data:
                    (visual['data'] as Map?)?.cast<String, dynamic>() ??
                    const {},
                height: 150,
                scale: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            result.explanation,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BounceIn extends StatelessWidget {
  const _BounceIn({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.55, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
