import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'player_avatar.dart';

class PlayerScoreChip extends StatelessWidget {
  const PlayerScoreChip({
    super.key,
    required this.displayName,
    required this.avatarIndex,
    required this.avatarColor,
    this.points = 0,
    this.subtitle,
    this.isHost = false,
    this.isMe = false,
    this.isConnected = true,
    this.submitted = false,
    this.trailing,
    this.rank,
  });

  final String displayName;
  final int avatarIndex;
  final String avatarColor;
  final int points;
  final String? subtitle;
  final bool isHost;
  final bool isMe;
  final bool isConnected;
  final bool submitted;
  final Widget? trailing;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isMe
            ? Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.surface,
              )
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.outline,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (rank != null)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: rank == 1 ? AppColors.yellow : AppColors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          PlayerAvatar(
            avatarIndex: avatarIndex,
            avatarColor: avatarColor,
            size: 36,
            displayName: displayName,
            isHost: isHost,
            isConnected: isConnected,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'YOU',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.onAccent,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
              ],
            ),
          ),
          if (submitted)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: Color(0xFF063B2A),
              ),
            ),
          if (trailing != null)
            trailing!
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.yellow.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$points',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.yellowDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'pts',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.yellowDark,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
