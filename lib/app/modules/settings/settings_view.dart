import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../routes/app_routes.dart';
import 'settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Settings',
      subtitle: 'Make the game feel right for you.',
      background: CandyBackgroundStyle.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AccountCard(),
          const SizedBox(height: 16),
          SectionHeader(eyebrow: 'Comfort', title: 'Game feel', emoji: '🎛️'),
          CandyCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Obx(
              () => Column(
                children: [
                  _Toggle(
                    title: 'Dark mode',
                    subtitle: 'Calm night colours that are easy on the eyes.',
                    icon: Icons.dark_mode_rounded,
                    value: controller.darkMode.value,
                    onChanged: controller.setDarkMode,
                  ),
                  const Divider(height: 1),
                  _Toggle(
                    title: 'Sound effects',
                    subtitle: 'Celebration and answer sounds.',
                    icon: Icons.volume_up_rounded,
                    value: controller.soundEnabled.value,
                    onChanged: controller.isSaving.value
                        ? null
                        : controller.setSound,
                  ),
                  const Divider(height: 1),
                  _Toggle(
                    title: 'Reduce motion',
                    subtitle: 'Calmer transitions and fewer animations.',
                    icon: Icons.motion_photos_off_rounded,
                    value: controller.reducedMotion.value,
                    onChanged: controller.isSaving.value
                        ? null
                        : controller.setReducedMotion,
                  ),
                  const Divider(height: 1),
                  _Toggle(
                    title: 'Show me on leaderboards',
                    subtitle:
                        'When off, your name stays off public rankings. '
                        'Your stats still count for you.',
                    icon: Icons.leaderboard_rounded,
                    value: controller.leaderboardVisible.value,
                    onChanged: controller.isSaving.value
                        ? null
                        : controller.setLeaderboardVisible,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            eyebrow: 'Safety',
            title: 'Privacy & fair play',
            emoji: '🛡️',
          ),
          CandyCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(
                  icon: Icons.chat_bubble_outline_rounded,
                  text:
                      'There is no open chat. Players can only choose answers '
                      'and emoji avatars.',
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.visibility_off_outlined,
                  text:
                      'Other players see your display name, avatar, grade and '
                      'game stats — never your email or settings.',
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.verified_user_outlined,
                  text:
                      'Questions, timing, scoring and rankings are checked on '
                      'the server, so results cannot be edited by the app.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            eyebrow: 'Account',
            title: 'Your data',
            emoji: '🗂️',
          ),
          CandyCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.isGuest) ...[
                  InlineBanner(
                    message:
                        'You are playing as a guest on this device. Add an '
                        'email to keep your progress everywhere.',
                    icon: Icons.cloud_off_rounded,
                    color: AppColors.yellowDark,
                    background: AppColors.yellowSoft,
                  ),
                  const SizedBox(height: 12),
                  ArcadeButton(
                    label: 'Save my progress',
                    icon: Icons.cloud_upload_rounded,
                    variant: ArcadeButtonVariant.yellow,
                    expand: true,
                    onPressed: controller.saveGuestProgress,
                  ),
                  const SizedBox(height: 8),
                ],
                ArcadeButton(
                  label: 'Edit profile',
                  icon: Icons.edit_rounded,
                  variant: ArcadeButtonVariant.outline,
                  expand: true,
                  onPressed: () => Get.toNamed(AppRoutes.editProfile),
                ),
                const SizedBox(height: 8),
                ArcadeButton(
                  label: 'Sign out',
                  icon: Icons.logout_rounded,
                  variant: ArcadeButtonVariant.outline,
                  expand: true,
                  loading: controller.isSigningOut.value,
                  onPressed: () => _confirmSignOut(context),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _confirmDelete(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorDark,
                  ),
                  child: const Text('Delete my account and data'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} ${AppConstants.appVersion}',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Made for curious K–5 maths brains.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your progress stays safe. Sign back in to pick up where you left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (result == true) await controller.signOut();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
          'This permanently removes your profile, stats, badges and match '
          'history. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep my data'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorDark),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == true) await controller.deleteAccount();
  }
}

class _AccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    final theme = Theme.of(context);
    return CandyCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              controller.isGuest ? '👤' : '✅',
              style: const TextStyle(fontSize: 24, height: 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  controller.isGuest
                      ? 'Guest account · saved on this device'
                      : 'Registered account',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: AppColors.primaryDark),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
      activeTrackColor: AppColors.primary,
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              height: 1.5,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}
