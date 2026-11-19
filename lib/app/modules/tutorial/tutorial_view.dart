import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import 'tutorial_controller.dart';

class TutorialView extends GetView<TutorialController> {
  const TutorialView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppScaffold(
        title: 'Learn to play',
        subtitle: 'Step ${controller.stepNumber} of ${controller.stepCount}',
        background: CandyBackgroundStyle.hero,
        actions: [
          IconButton(
            onPressed: () => _showGrownUpHelp(context),
            tooltip: 'For grown-ups',
            icon: const Icon(Icons.support_agent_rounded),
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
            _StepDots(
              current: controller.stepNumber,
              total: controller.stepCount,
              duration: controller.reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
            ),
            const SizedBox(height: 12),
            Center(
              child: NarrationBar(
                text: controller.script,
                autoPlay: false,
                label: 'Hear it again',
                compact: true,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: controller.reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOut,
              child: KeyedSubtree(
                key: ValueKey(controller.step.value),
                child: switch (controller.step.value) {
                  TutorialStep.welcome => const _WelcomeStep(),
                  TutorialStep.count => const _CountStep(),
                  TutorialStep.choose => const _ChooseStep(),
                  TutorialStep.celebrate => const _CelebrateStep(),
                  TutorialStep.add => const _AddStep(),
                  TutorialStep.results => const _ResultsStep(),
                  TutorialStep.done => const _DoneStep(),
                },
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'No timer. No score. Just one tap at a time.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGrownUpHelp(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('For grown-ups'),
        content: const Text(
          'Sit beside your child for the first round. The voice reads every '
          'instruction, and the same words stay on screen for sound-off play.\n\n'
          'Kindergarten rooms get 30 seconds per question and no speed bonus '
          'by default. You can replay this tutorial or change sound and motion '
          'in Settings at any time.\n\n'
          'There is no open chat. Other players only see a display name, an '
          'emoji avatar and game stats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.current,
    required this.total,
    required this.duration,
  });

  final int current;
  final int total;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < total; index++)
          AnimatedContainer(
            duration: duration,
            width: index + 1 == current ? 28 : 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: index + 1 <= current
                  ? AppColors.primary
                  : AppColors.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: index + 1 <= current
                    ? AppColors.primary
                    : AppColors.outline,
                width: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TutorialController>();
    final theme = Theme.of(context);
    return _StepCard(
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.2),
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('🦊', style: TextStyle(fontSize: 64, height: 1)),
          ),
          const SizedBox(height: 18),
          Text(
            'Tap. Count. Choose.',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 8),
          Text(
            'We will practise three easy moves before the first match.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          ArcadeButton(
            label: 'Start',
            icon: Icons.play_arrow_rounded,
            size: ArcadeButtonSize.large,
            expand: true,
            onPressed: controller.start,
          ),
        ],
      ),
    );
  }
}

class _CountStep extends StatelessWidget {
  const _CountStep();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TutorialController>();
    final theme = Theme.of(context);
    return _StepCard(
      child: Column(
        children: [
          Text(
            'Tap each apple',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Count them out loud with the voice.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Obx(
            () => Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var index = 0; index < controller.apples.length; index++)
                  _CountApple(
                    number: index + 1,
                    tapped: controller.apples[index],
                    onTap: () => controller.tapApple(index),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.countComplete
                  ? 'Three apples! 🎉'
                  : '${controller.counted} of 3',
              style: theme.textTheme.titleMedium?.copyWith(
                color: controller.countComplete
                    ? AppColors.mintDark
                    : AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => ArcadeButton(
              label: 'Next',
              icon: Icons.arrow_forward_rounded,
              size: ArcadeButtonSize.large,
              expand: true,
              enabled: controller.countComplete,
              onPressed: controller.nextFromCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountApple extends StatelessWidget {
  const _CountApple({
    required this.number,
    required this.tapped,
    required this.onTap,
  });

  final int number;
  final bool tapped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tapped ? 'Apple $number counted' : 'Tap apple $number',
      child: InkWell(
        onTap: tapped ? null : onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: tapped ? AppColors.mintSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: tapped ? AppColors.mintDark : AppColors.outline,
              width: 3,
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '🍎',
                style: TextStyle(fontSize: tapped ? 38 : 48, height: 1),
              ),
              if (tapped)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.mintDark,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChooseStep extends StatelessWidget {
  const _ChooseStep();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TutorialController>();
    final theme = Theme.of(context);
    return _StepCard(
      child: Column(
        children: [
          Text(
            'Which card has 3 apples?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the card, then count to check.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _AppleChoiceCard(
                  count: 2,
                  onTap: () => controller.chooseThree(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AppleChoiceCard(
                  count: 3,
                  onTap: () => controller.chooseThree(true),
                ),
              ),
            ],
          ),
          Obx(() {
            if (controller.wrongAttempts.value == 0) {
              return const SizedBox(height: 12);
            }
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InlineBanner(
                message: 'Almost! Tap the card and count: 1, 2, 3.',
                icon: Icons.favorite_rounded,
                color: AppColors.yellowDark,
                background: AppColors.yellowSoft,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AppleChoiceCard extends StatelessWidget {
  const _AppleChoiceCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Card with $count apples',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < count; i++)
                    const Text('🍎', style: TextStyle(fontSize: 27, height: 1)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$count apples',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CelebrateStep extends StatelessWidget {
  const _CelebrateStep();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TutorialController>();
    final theme = Theme.of(context);
    return _StepCard(
      child: Column(
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.check_rounded,
              size: 72,
              color: AppColors.mintDark,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'You counted 3!',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 6),
          Text(
            'Three apples. That is exactly right.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          ArcadeButton(
            label: 'Next move',
            icon: Icons.arrow_forward_rounded,
            size: ArcadeButtonSize.large,
            expand: true,
            onPressed: controller.nextFromCelebrate,
          ),
        ],
      ),
    );
  }
}

class _AddStep extends StatelessWidget {
  const _AddStep();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TutorialController>();
    final theme = Theme.of(context);
    return _StepCard(
      child: Column(
        children: [
          Text(
            '1 apple + 2 apples',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'How many apples altogether?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.yellow, width: 2),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: const [
                Text('🍎', style: TextStyle(fontSize: 34, height: 1)),
                Text(
                  '+',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                Text('🍎🍎', style: TextStyle(fontSize: 34, height: 1)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final choice in [2, 3, 4])
                _NumberChoice(
                  number: choice,
                  onTap: () => controller.answerAdd(choice),
                ),
            ],
          ),
          Obx(() {
            if (controller.wrongAttempts.value < 2) {
              return const SizedBox(height: 12);
            }
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InlineBanner(
                message: 'Count them all: 1, 2, 3. Try once more.',
                icon: Icons.lightbulb_rounded,
                color: AppColors.yellowDark,
                background: AppColors.yellowSoft,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NumberChoice extends StatelessWidget {
  const _NumberChoice({required this.number, required this.onTap});

  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Answer $number',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 86,
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.outline, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 34),
          ),
        ),
      ),
    );
  }
}

class _ResultsStep extends StatelessWidget {
  const _ResultsStep();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TutorialController>();
    final theme = Theme.of(context);
    return _StepCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.yellow, width: 2),
            ),
            child: Text(
              'PRACTICE RESULTS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.yellowDark,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '3 out of 3!',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 36),
          ),
          const SizedBox(height: 4),
          const Text('⭐⭐⭐', style: TextStyle(fontSize: 30, height: 1.2)),
          const SizedBox(height: 10),
          Text(
            'Every try helps your number brain grow.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mintDark, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.mintDark,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your progress',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '3 / 3',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.mintDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 1,
                    minHeight: 10,
                    backgroundColor: AppColors.surface,
                    color: AppColors.mintDark,
                    semanticsLabel: 'Practice progress: 3 of 3 correct',
                    semanticsValue: '100',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final medal in const ['🥇', '🥈', '🥉']) ...[
                Text(medal, style: const TextStyle(fontSize: 22, height: 1)),
                if (medal != '🥉') const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'In a match you will see this podium too.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 18),
          ArcadeButton(
            label: 'Next',
            icon: Icons.arrow_forward_rounded,
            size: ArcadeButtonSize.large,
            expand: true,
            onPressed: controller.nextFromResults,
          ),
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TutorialController>();
    final theme = Theme.of(context);
    return _StepCard(
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 74, height: 1)),
          const SizedBox(height: 12),
          Text(
            'You are ready!',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 6),
          Text(
            'You can tap answers, count pictures and check your work. '
            'A grown-up can sit beside you for the first match.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ArcadeButton(
            label: 'Play a match',
            icon: Icons.bolt_rounded,
            variant: ArcadeButtonVariant.yellow,
            size: ArcadeButtonSize.large,
            expand: true,
            onPressed: () => controller.finish(playMatch: true),
          ),
          const SizedBox(height: 8),
          ArcadeButton(
            label: 'Practise with pictures',
            icon: Icons.image_rounded,
            variant: ArcadeButtonVariant.outline,
            size: ArcadeButtonSize.medium,
            expand: true,
            onPressed: () => controller.finish(practice: true),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: controller.replay,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Do the tutorial again'),
          ),
        ],
      ),
    );
  }
}
