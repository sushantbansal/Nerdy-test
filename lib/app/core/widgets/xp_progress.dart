import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class XpProgress extends StatelessWidget {
  const XpProgress({
    super.key,
    required this.xp,
    required this.level,
    this.height = 14,
    this.showLabels = true,
    this.color,
  });

  final int xp;
  final int level;
  final double height;
  final bool showLabels;
  final Color? color;

  double get _progress {
    final within = xp % AppConstants.xpPerLevel;
    return (within / AppConstants.xpPerLevel).clamp(0, 1);
  }

  int get _toNext => AppConstants.xpPerLevel - (xp % AppConstants.xpPerLevel);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? AppColors.purple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: resolvedColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'LVL $level',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$_toNext XP to next level',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress == 0 ? 0.02 : _progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      resolvedColor,
                      Color.alphaBlend(Colors.white, resolvedColor),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QuickStat extends StatelessWidget {
  const QuickStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.emoji,
    this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final String? emoji;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              color.withValues(alpha: 0.14),
              AppColors.surface,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: emoji != null
              ? Text(emoji!, style: const TextStyle(fontSize: 18, height: 1))
              : Icon(icon, size: 19, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: AppColors.ink),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.inkSoft,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
