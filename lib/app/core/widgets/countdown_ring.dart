import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Circular countdown driven by the server deadline.
///
/// The parent passes the remaining duration from the latest authoritative
/// snapshot; the ring interpolates between snapshots for a smooth sweep.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    this.size = 72,
    this.label,
    this.showLabel = true,
  });

  final Duration remaining;
  final Duration total;
  final double size;
  final String? label;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final totalMs = total.inMilliseconds <= 0 ? 1 : total.inMilliseconds;
    final clamped = remaining.inMilliseconds.clamp(0, totalMs);
    final fraction = clamped / totalMs;
    final seconds = (clamped / 1000).ceil();
    final urgent = seconds <= 5;
    final color = urgent
        ? AppColors.error
        : seconds <= 10
        ? AppColors.yellowDark
        : AppColors.primary;

    return Semantics(
      label: '$seconds seconds remaining',
      value: '$seconds',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: fraction, end: fraction),
        duration: const Duration(milliseconds: 220),
        curve: Curves.linear,
        builder: (context, value, child) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: _RingPainter(
                    progress: value.clamp(0, 1),
                    color: color,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      showLabel ? '$seconds' : Formatters.countdown(remaining),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontSize: size * 0.32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    if (label != null)
                      Text(
                        label!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkSoft,
                          fontSize: size * 0.13,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 8) / 2;

    final track = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
