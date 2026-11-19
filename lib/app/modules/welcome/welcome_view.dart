import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/selectors.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/models/math_models.dart';
import 'welcome_controller.dart';

class WelcomeView extends GetView<WelcomeController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: CandyBackground(
        style: CandyBackgroundStyle.hero,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.heroGradient,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '⚡',
                            style: TextStyle(fontSize: 24, height: 1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'MathClash',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 22,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.outline,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'K–5 math',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _HeroCard(),
                    const SizedBox(height: 20),
                    CandyCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Who is playing?',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pick a name, grade and buddy. No real names needed.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: controller.nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            maxLength: 20,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[A-Za-z0-9 ._'-]"),
                              ),
                              LengthLimitingTextInputFormatter(20),
                            ],
                            onSubmitted: (_) => controller.startAsGuest(),
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              hintText: 'e.g. Turbo Fox',
                              prefixIcon: Icon(Icons.badge_rounded),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('Grade', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 10),
                          Obx(
                            () => GradePicker(
                              value: controller.grade.value,
                              onChanged: (value) =>
                                  controller.grade.value = value,
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Choose a buddy',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 10),
                          Obx(
                            () => AvatarPicker(
                              avatarIndex: controller.avatarIndex.value,
                              onChanged: controller.selectAvatar,
                            ),
                          ),
                          Obx(
                            () => controller.error.value.isEmpty
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: InlineBanner(
                                      message: controller.error.value,
                                      icon: Icons.error_outline_rounded,
                                      color: AppColors.errorDark,
                                      background: AppColors.errorSoft,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 18),
                          Obx(
                            () => ArcadeButton(
                              label: 'Let’s play',
                              icon: Icons.bolt_rounded,
                              size: ArcadeButtonSize.large,
                              expand: true,
                              loading: controller.isStarting.value,
                              onPressed: controller.startAsGuest,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ArcadeButton(
                                  label: 'Sign in',
                                  variant: ArcadeButtonVariant.outline,
                                  icon: Icons.login_rounded,
                                  onPressed: controller.goToSignIn,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ArcadeButton(
                                  label: 'Sign up',
                                  variant: ArcadeButtonVariant.ghost,
                                  onPressed: controller.goToSignUp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: AppColors.inkSoft,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'No open chat. Progress can be saved to an email later.',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  _showGrownUpHelp(context, controller),
                              icon: const Icon(
                                Icons.support_agent_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'For grown-ups: setup & accessibility',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGrownUpHelp(
    BuildContext context,
    WelcomeController controller,
  ) async {
    final useKindergarten = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('For grown-ups'),
        content: const SingleChildScrollView(
          child: Text(
            'MathClash is made for children in Kindergarten to Grade 5.\n\n'
            'For a 5–6 year old, choose Kindergarten. The first visit starts '
            'with a short picture tutorial that teaches one tap at a time, '
            'with spoken instructions. Sit beside your child for the first '
            'round.\n\n'
            'Kindergarten play starts with no-timer practice. Optional rooms '
            'default to 30 seconds per question with the speed bonus off, and '
            'every player in a room gets the same rules.\n\n'
            'Sound can be muted, and the same words stay on screen as '
            'captions. Reduce motion is available in Settings after you '
            'start. There is no open chat or photo sharing.\n\n'
            'A guest profile needs no email or real name. If you create an '
            'account for a child, please give the appropriate parental or '
            'guardian consent first.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Got it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Use Kindergarten'),
          ),
        ],
      ),
    );
    if (useKindergarten == true) {
      controller.grade.value = GradeLevel.kindergarten;
    }
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
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
            color: AppColors.primaryDark.withValues(alpha: 0.32),
            offset: const Offset(0, 8),
            blurRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            offset: const Offset(0, 16),
            blurRadius: 30,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -18,
            child: Opacity(
              opacity: 0.22,
              child: Text(
                '＋−×÷',
                style: TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'MULTIPLAYER MATH ARENA',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Race your friends\nwith numbers.',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                  height: 1.05,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.35),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Fast fingers + clever thinking = clash champion.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
