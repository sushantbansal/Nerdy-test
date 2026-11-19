import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Chunky white card with a candy outline and a soft offset shadow.
class CandyCard extends StatelessWidget {
  const CandyCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
    this.radius = 28,
    this.shadowColor,
    this.onTap,
    this.elevated = true,
    this.margin = EdgeInsets.zero,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final Color? shadowColor;
  final VoidCallback? onTap;
  final bool elevated;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.surface;
    final resolvedBorder = borderColor ?? AppColors.outline;
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: resolvedBorder, width: 2),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: (shadowColor ?? AppColors.primaryDark).withValues(
                    alpha: 0.10,
                  ),
                  offset: const Offset(0, 6),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.04),
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return card;
  }
}
