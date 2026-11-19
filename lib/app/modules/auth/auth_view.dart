import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/selectors.dart';
import '../../core/widgets/widgets.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final mode = controller.mode.value;
      final upgrade = mode == AuthMode.upgrade;
      final signUp = mode == AuthMode.signUp;
      return AppScaffold(
        title: upgrade ? 'Save your progress' : 'MathClash account',
        subtitle: upgrade
            ? 'Keep your guest progress on every device.'
            : 'For grown-ups — or ask a grown-up to help.',
        background: CandyBackgroundStyle.hero,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        onBack: controller.close,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!upgrade) ...[
              _PlayHero(
                onPlay: controller.backToWelcome,
                onSpeak: controller.speakHelp,
              ),
              const SizedBox(height: 12),
            ],
            if (!upgrade)
              SegmentedChoice<AuthMode>(
                options: const [AuthMode.signIn, AuthMode.signUp],
                value: signUp ? AuthMode.signUp : AuthMode.signIn,
                labelBuilder: (value) =>
                    value == AuthMode.signIn ? 'Sign in' : 'Create account',
                onChanged: controller.switchMode,
              ),
            if (!upgrade) const SizedBox(height: 16),
            CandyCard(
              padding: const EdgeInsets.all(20),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (upgrade) const _GuestBanner(),
                    if (signUp) ...[
                      _SectionTitle(
                        emoji: '🦊',
                        title: 'Player setup',
                        subtitle: 'This is what other players will see.',
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller.nameController,
                        onChanged: (_) => controller.clearError(),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: 20,
                        autofillHints: const [AutofillHints.nickname],
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          hintText: 'e.g. Turbo Fox',
                          prefixIcon: Icon(Icons.badge_rounded),
                          counterText: '',
                          helperText: 'A nickname is perfect — no real name.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Grade', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      GradePicker(
                        value: controller.grade.value,
                        onChanged: (value) => controller.grade.value = value,
                        compact: true,
                      ),
                      const SizedBox(height: 14),
                      Text('Buddy', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      AvatarPicker(
                        avatarIndex: controller.avatarIndex.value,
                        onChanged: controller.selectAvatar,
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        emoji: '🔐',
                        title: 'Sign-in details',
                        subtitle: 'Only used to keep your progress safe.',
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: controller.emailController,
                      onChanged: (_) => controller.clearError(),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                        helperText: 'We only use this to sign you in.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller.passwordController,
                      onChanged: (_) => controller.clearError(),
                      obscureText: controller.obscurePassword.value,
                      textInputAction: TextInputAction.done,
                      autofillHints: [
                        signUp || upgrade
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      onSubmitted: (_) {
                        if (!controller.submitting.value) controller.submit();
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'At least 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        helperText: signUp || upgrade
                            ? 'Use at least 8 characters.'
                            : null,
                        suffixIcon: IconButton(
                          onPressed: () => controller.obscurePassword.toggle(),
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          tooltip: controller.obscurePassword.value
                              ? 'Show password'
                              : 'Hide password',
                        ),
                      ),
                    ),
                    if (controller.error.value.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      InlineBanner(
                        message: controller.error.value,
                        icon: Icons.error_outline_rounded,
                        color: AppColors.errorDark,
                        background: AppColors.errorSoft,
                      ),
                    ],
                    const SizedBox(height: 20),
                    ArcadeButton(
                      label: switch (mode) {
                        AuthMode.signIn => 'Sign in',
                        AuthMode.signUp => 'Create my account',
                        AuthMode.upgrade => 'Save my progress',
                      },
                      icon: switch (mode) {
                        AuthMode.signIn => Icons.login_rounded,
                        AuthMode.signUp => Icons.rocket_launch_rounded,
                        AuthMode.upgrade => Icons.cloud_upload_rounded,
                      },
                      expand: true,
                      size: ArcadeButtonSize.large,
                      loading: controller.submitting.value,
                      onPressed: controller.submit,
                    ),
                    if (!upgrade) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: controller.submitting.value
                              ? null
                              : controller.sendResetEmail,
                          icon: const Icon(Icons.lock_reset_rounded, size: 18),
                          label: const Text('Forgot password?'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _SafetyCard(),
            const SizedBox(height: 12),
            if (!upgrade)
              Center(
                child: TextButton.icon(
                  onPressed: controller.showAccountHelp,
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: const Text('Why create an account?'),
                ),
              )
            else
              Center(
                child: TextButton.icon(
                  onPressed: controller.close,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Not now, keep playing'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}

class _PlayHero extends StatelessWidget {
  const _PlayHero({required this.onPlay, required this.onSpeak});

  final VoidCallback onPlay;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Play as guest',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0062C4), AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.24),
                  offset: const Offset(0, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '🦊',
                      style: TextStyle(fontSize: 28, height: 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Play!',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onSpeak,
                    tooltip: 'Hear this',
                    icon: const Icon(Icons.volume_up_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.primaryDark,
                      size: 31,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22, height: 1.2)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safe for kids', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'No real name, photo or address. No open chat. '
                  'A guest profile stays on this device — ask a grown-up '
                  'before creating an account for a child.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSoft,
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

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.yellow, width: 2),
      ),
      child: Row(
        children: [
          const Text('💾', style: TextStyle(fontSize: 24, height: 1)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are playing as a guest. Add an email to keep your XP, '
              'badges and match history.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
