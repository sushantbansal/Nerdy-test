import 'package:flutter/material.dart';

import '../../domain/models/math_models.dart';
import '../theme/app_colors.dart';

Color topicColor(MathTopic topic) {
  return switch (topic) {
    MathTopic.addition => AppColors.primary,
    MathTopic.subtraction => AppColors.purple,
    MathTopic.multiplication => AppColors.pink,
    MathTopic.division => AppColors.mintDark,
    MathTopic.fractions => AppColors.yellowDark,
    MathTopic.geometry => const Color(0xFFF97316),
    MathTopic.measurement => const Color(0xFF0891B2),
    MathTopic.placeValue => const Color(0xFF2563EB),
    MathTopic.mixed => AppColors.purpleDark,
  };
}

class TopicPill extends StatelessWidget {
  const TopicPill({
    super.key,
    required this.topic,
    this.selected = false,
    this.onTap,
    this.compact = false,
    this.showSymbol = true,
  });

  final MathTopic topic;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;
  final bool showSymbol;

  @override
  Widget build(BuildContext context) {
    final color = topicColor(topic);
    final background = selected
        ? color
        : Color.alphaBlend(color.withValues(alpha: 0.13), AppColors.surface);
    final foreground = selected ? AppColors.onAccent : color;

    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? color : color.withValues(alpha: 0.28),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSymbol) ...[
            Text(
              topic.symbol,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w900,
                color: foreground,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              topic.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ),
        ],
      ),
    );

    final sized = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: child,
    );

    if (onTap == null) return sized;
    return GestureDetector(onTap: onTap, child: sized);
  }
}

class GradePill extends StatelessWidget {
  const GradePill({
    super.key,
    required this.grade,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final GradeLevel grade;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.selectionSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.selectionSurface : AppColors.outline,
          width: 2,
        ),
      ),
      child: Text(
        grade.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: selected ? AppColors.onSelection : AppColors.ink,
          fontSize: compact ? 12 : 13,
        ),
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

class DifficultyPill extends StatelessWidget {
  const DifficultyPill({
    super.key,
    required this.difficulty,
    this.compact = false,
  });

  final MathDifficulty difficulty;
  final bool compact;

  Color get _color => switch (difficulty) {
    MathDifficulty.easy => AppColors.mintDark,
    MathDifficulty.medium => AppColors.primaryDark,
    MathDifficulty.hard => AppColors.pinkDark,
    MathDifficulty.adaptive => AppColors.purpleDark,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.12),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Text(
        difficulty.label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, letterSpacing: 0.4),
      ),
    );
  }
}

class MasteryPill extends StatelessWidget {
  const MasteryPill({super.key, required this.mastery, this.compact = false});

  final MasteryLevel mastery;
  final bool compact;

  Color get _color => switch (mastery) {
    MasteryLevel.notStarted => AppColors.inkSoft,
    MasteryLevel.learning => AppColors.primaryDark,
    MasteryLevel.practicing => const Color(0xFF0891B2),
    MasteryLevel.proficient => AppColors.mintDark,
    MasteryLevel.mastered => AppColors.purpleDark,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.13),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Text(
        mastery.label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, letterSpacing: 0.3),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.value,
    required this.label,
    this.emoji,
    this.icon,
    this.color,
    this.compact = false,
    this.expanded = false,
  });

  final String value;
  final String label;
  final String? emoji;
  final IconData? icon;
  final Color? color;
  final bool compact;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? AppColors.primaryDark;
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          resolvedColor.withValues(alpha: 0.08),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: resolvedColor.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emoji != null)
            Text(emoji!, style: TextStyle(fontSize: compact ? 14 : 18))
          else if (icon != null)
            Icon(icon, size: compact ? 15 : 18, color: resolvedColor),
          if (emoji != null || icon != null) const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontSize: compact ? 13 : 15,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontSize: compact ? 9 : 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return content;
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, this.color});

  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final resolvedColor = color ?? AppColors.pink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.onAccent,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
