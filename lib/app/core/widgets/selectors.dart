import 'package:flutter/material.dart';

import '../../domain/models/math_models.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'pills.dart';
import 'player_avatar.dart';

/// A single, compact grade selector.
///
/// Grades used to be a row of pill "tags"; a dropdown keeps the same choice
/// set without taking up a line for every grade on small screens.
class GradePicker extends StatelessWidget {
  const GradePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final GradeLevel value;
  final ValueChanged<GradeLevel> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 8 : 12,
        ),
        prefixIcon: const Icon(Icons.school_rounded),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GradeLevel>(
          value: value,
          isExpanded: true,
          isDense: compact,
          borderRadius: BorderRadius.circular(18),
          menuMaxHeight: 340,
          icon: const Icon(Icons.expand_more_rounded),
          onChanged: (grade) {
            if (grade != null && grade != value) onChanged(grade);
          },
          items: [
            for (final grade in GradeLevel.values)
              DropdownMenuItem<GradeLevel>(
                value: grade,
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: grade == value
                            ? AppColors.primarySoft
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        grade.shortLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        grade.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.avatarIndex,
    required this.onChanged,
    this.size = 52,
  });

  final int avatarIndex;
  final void Function(int index, String color) onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (var index = 0; index < AppConstants.avatarEmojis.length; index++)
          GestureDetector(
            onTap: () => onChanged(
              index,
              AppConstants.avatarColors[index %
                  AppConstants.avatarColors.length],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: index == avatarIndex
                      ? AppColors.ink
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: PlayerAvatar(
                avatarIndex: index,
                avatarColor: AppConstants
                    .avatarColors[index % AppConstants.avatarColors.length],
                size: size,
                showRing: index == avatarIndex,
              ),
            ),
          ),
      ],
    );
  }
}

class TopicPicker extends StatelessWidget {
  const TopicPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.topics = MathTopic.values,
    this.includeMixed = false,
    this.maxSelection,
  });

  final Set<MathTopic> selected;
  final ValueChanged<Set<MathTopic>> onChanged;
  final List<MathTopic> topics;
  final bool includeMixed;
  final int? maxSelection;

  @override
  Widget build(BuildContext context) {
    final available = topics
        .where((topic) => includeMixed || topic != MathTopic.mixed)
        .toList(growable: false);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final topic in available)
          TopicPill(
            topic: topic,
            selected: selected.contains(topic),
            onTap: () {
              final next = Set<MathTopic>.from(selected);
              if (next.contains(topic)) {
                next.remove(topic);
              } else {
                if (maxSelection != null && next.length >= maxSelection!) {
                  next.remove(next.first);
                }
                next.add(topic);
              }
              if (next.isEmpty) return;
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.options,
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> options;
  final T value;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: option == value
                        ? AppColors.selectionSurface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labelBuilder(option),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: option == value
                          ? AppColors.onSelection
                          : AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
