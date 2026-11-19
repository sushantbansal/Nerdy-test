import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/selectors.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/models/math_models.dart';
import 'create_room_controller.dart';

class CreateRoomView extends GetView<CreateRoomController> {
  const CreateRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Create a room',
      subtitle: 'Set the rules. You are the host.',
      background: CandyBackgroundStyle.hero,
      bottomBar: Obx(
        () => ArcadeButton(
          label: 'Create room',
          icon: Icons.rocket_launch_rounded,
          size: ArcadeButtonSize.large,
          expand: true,
          loading: controller.isCreating.value,
          onPressed: controller.createRoom,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CandyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room name', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.nameController,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Turbo Comets',
                    counterText: '',
                    prefixIcon: const Icon(Icons.meeting_room_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Surprise me',
                      onPressed: controller.shuffleName,
                      icon: const Icon(Icons.casino_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => SegmentedChoice<RoomVisibility>(
                    options: RoomVisibility.values,
                    value: controller.visibility.value,
                    labelBuilder: (value) => value.label,
                    onChanged: (value) => controller.visibility.value = value,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Text(
                    controller.visibility.value.description,
                    style: theme.textTheme.labelSmall,
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
                const SectionHeader(
                  eyebrow: 'Curriculum',
                  title: 'Grade & topics',
                  emoji: '🎓',
                ),
                Obx(
                  () => GradePicker(
                    value: controller.grade.value,
                    onChanged: (value) => controller.grade.value = value,
                    compact: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose up to 3 topics',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Obx(
                  () => TopicPicker(
                    selected: controller.selectedTopics,
                    topics: controller.availableTopics,
                    onChanged: controller.setTopics,
                    includeMixed: true,
                    maxSelection: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mixed Challenge pulls from every topic for a surprise round.',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 18),
                Text('Difficulty', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in MathDifficulty.values)
                        _Choice(
                          label: option.label,
                          emoji: switch (option) {
                            MathDifficulty.easy => '🌱',
                            MathDifficulty.medium => '⚡',
                            MathDifficulty.hard => '🔥',
                            MathDifficulty.adaptive => '🧠',
                          },
                          selected: controller.difficulty.value == option,
                          onTap: () => controller.difficulty.value = option,
                        ),
                    ],
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
                const SectionHeader(
                  eyebrow: 'Match setup',
                  title: 'Tune the challenge',
                  emoji: '🎛️',
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Questions',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Obx(
                      () => _Stepper(
                        value: '${controller.questionCount.value}',
                        onMinus: () => controller.setQuestions(
                          controller.questionCount.value - 1,
                        ),
                        onPlus: () => controller.setQuestions(
                          controller.questionCount.value + 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Between ${AppConstants.minQuestionCount} and '
                  '${AppConstants.maxQuestionCount} questions.',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 18),
                Text('Seconds per question', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final seconds in CreateRoomController.answerChoices)
                        _Choice(
                          label: '${seconds}s',
                          selected: controller.answerSeconds.value == seconds,
                          onTap: () => controller.setAnswerSeconds(seconds),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Players', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final players in CreateRoomController.playerChoices)
                        _Choice(
                          label: '$players',
                          emoji: players == 2 ? '👥' : '🎉',
                          selected: controller.maxPlayers.value == players,
                          onTap: () => controller.setMaxPlayers(players),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => _ToggleRow(
                    title: 'Speed bonus',
                    subtitle: 'Fastest correct answer earns +1 extra point.',
                    value: controller.speedBonus.value,
                    onChanged: (value) => controller.speedBonus.value = value,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => _ToggleRow(
                    title: 'Auto-start',
                    subtitle:
                        'Start automatically when at least 2 players are ready.',
                    value: controller.autoStart.value,
                    onChanged: (value) => controller.autoStart.value = value,
                  ),
                ),
              ],
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
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
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
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 13, height: 1)),
              const SizedBox(width: 5),
            ],
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

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 28,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
      activeTrackColor: AppColors.primary,
    );
  }
}
