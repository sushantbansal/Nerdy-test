import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum CandyBackgroundStyle { sky, hero, mint, pink, purple, warm }

/// Soft, arcade-inspired background with floating candy shapes.
///
/// The decoration is static (no continuous animation) so it stays calm for
/// children who prefer reduced motion, and it never competes with content.
class CandyBackground extends StatelessWidget {
  const CandyBackground({
    super.key,
    required this.child,
    this.style = CandyBackgroundStyle.sky,
    this.showShapes = true,
  });

  final Widget child;
  final CandyBackgroundStyle style;
  final bool showShapes;

  List<Color> get _gradient {
    if (AppColors.isDark) {
      return switch (style) {
        CandyBackgroundStyle.hero => const [
          Color(0xFF122039),
          Color(0xFF172A4A),
          Color(0xFF101A2F),
        ],
        CandyBackgroundStyle.mint => const [
          Color(0xFF10241F),
          Color(0xFF142D27),
          Color(0xFF0E1B20),
        ],
        CandyBackgroundStyle.pink => const [
          Color(0xFF241426),
          Color(0xFF2C1830),
          Color(0xFF171321),
        ],
        CandyBackgroundStyle.purple => const [
          Color(0xFF1B1633),
          Color(0xFF211A3D),
          Color(0xFF121226),
        ],
        CandyBackgroundStyle.warm => const [
          Color(0xFF241E12),
          Color(0xFF2C2517),
          Color(0xFF17150F),
        ],
        CandyBackgroundStyle.sky => AppColors.skyGradient,
      };
    }
    return switch (style) {
      CandyBackgroundStyle.hero => const [
        Color(0xFFE8F4FF),
        Color(0xFFDDE9FF),
        Color(0xFFF4F9FF),
      ],
      CandyBackgroundStyle.mint => const [
        Color(0xFFE9FFF7),
        Color(0xFFDDF7EE),
        Color(0xFFF8FFFC),
      ],
      CandyBackgroundStyle.pink => const [
        Color(0xFFFFF0F7),
        Color(0xFFFDE4F0),
        Color(0xFFFFF9FC),
      ],
      CandyBackgroundStyle.purple => const [
        Color(0xFFF4EEFF),
        Color(0xFFE9E0FF),
        Color(0xFFFBF8FF),
      ],
      CandyBackgroundStyle.warm => const [
        Color(0xFFFFF9E8),
        Color(0xFFFFF1CC),
        Color(0xFFFFFCF5),
      ],
      CandyBackgroundStyle.sky => AppColors.skyGradient,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [if (showShapes) ..._shapes(), child],
      ),
    );
  }

  List<Widget> _shapes() {
    return [
      Positioned(
        top: -70,
        right: -50,
        child: _Blob(
          size: 220,
          color: AppColors.primary.withValues(alpha: 0.10),
        ),
      ),
      Positioned(
        top: 130,
        left: -70,
        child: _Blob(
          size: 180,
          color: AppColors.yellow.withValues(alpha: 0.18),
        ),
      ),
      Positioned(
        bottom: -90,
        right: 30,
        child: _Blob(size: 240, color: AppColors.mint.withValues(alpha: 0.13)),
      ),
      Positioned(
        bottom: 180,
        left: 20,
        child: _Blob(size: 90, color: AppColors.pink.withValues(alpha: 0.10)),
      ),
    ];
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size * 0.5),
            topRight: Radius.circular(size * 0.42),
            bottomLeft: Radius.circular(size * 0.38),
            bottomRight: Radius.circular(size * 0.5),
          ),
        ),
      ),
    );
  }
}
