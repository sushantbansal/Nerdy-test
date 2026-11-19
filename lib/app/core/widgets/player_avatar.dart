import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Friendly emoji avatar. Images are never uploaded, which keeps the game
/// child-safe and avoids storing personal media.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.avatarIndex,
    required this.avatarColor,
    this.size = 48,
    this.displayName,
    this.showRing = false,
    this.ringColor,
    this.isHost = false,
    this.isConnected = true,
    this.dimmed = false,
  });

  final int avatarIndex;
  final String avatarColor;
  final double size;
  final String? displayName;
  final bool showRing;
  final Color? ringColor;
  final bool isHost;
  final bool isConnected;
  final bool dimmed;

  String get _emoji {
    final index = avatarIndex % AppConstants.avatarEmojis.length;
    return AppConstants.avatarEmojis[index < 0 ? 0 : index];
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.forAvatar(avatarColor);
    final ring = ringColor ?? base;
    final content = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(Colors.white.withValues(alpha: 0.55), base),
              Color.alphaBlend(Colors.white.withValues(alpha: 0.18), base),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: showRing ? ring : AppColors.surface,
            width: showRing ? 3.5 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(_emoji, style: TextStyle(fontSize: size * 0.52, height: 1)),
      ),
    );

    return SizedBox(
      width: size + (isHost ? 4 : 0),
      height: size + (isHost ? 10 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isHost ? 8 : 0),
            child: Semantics(
              label: displayName == null
                  ? 'Player avatar'
                  : '${displayName!}, ${Formatters.initials(displayName!)}',
              image: true,
              child: content,
            ),
          ),
          if (isHost)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: size * 0.22,
                  color: AppColors.ink,
                ),
              ),
            ),
          if (!isConnected)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  color: AppColors.inkSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
