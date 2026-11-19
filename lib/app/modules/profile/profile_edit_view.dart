import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/selectors.dart';
import '../../core/widgets/widgets.dart';
import 'profile_edit_controller.dart';

class ProfileEditView extends GetView<ProfileEditController> {
  const ProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Edit profile',
      subtitle: 'Pick a friendly name, buddy and grade.',
      background: CandyBackgroundStyle.purple,
      bottomBar: Obx(
        () => ArcadeButton(
          label: 'Save changes',
          icon: Icons.check_rounded,
          size: ArcadeButtonSize.large,
          expand: true,
          loading: controller.isSaving.value,
          onPressed: controller.canSave ? controller.save : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CandyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display name', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.nameController,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[A-Za-z0-9 ._'-]"),
                    ),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Turbo Fox',
                    counterText: '',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Letters, numbers, spaces, dots, dashes and apostrophes only. '
                  'Please do not use your full real name.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CandyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grade', style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                Obx(
                  () => GradePicker(
                    value: controller.grade.value,
                    onChanged: (value) => controller.grade.value = value,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CandyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your buddy', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                Obx(
                  () => AvatarPicker(
                    avatarIndex: controller.avatarIndex.value,
                    onChanged: controller.selectAvatar,
                  ),
                ),
              ],
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
