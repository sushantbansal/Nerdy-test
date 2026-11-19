import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'arcade_button.dart';
import 'candy_card.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.message = 'Getting things ready…',
    this.emoji = '🎈',
    this.compact = false,
  });

  final String message;
  final String emoji;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 24 : 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BouncingEmoji(emoji: emoji, size: compact ? 34 : 52),
            SizedBox(height: compact ? 12 : 20),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: compact ? 10 : 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncingEmoji extends StatefulWidget {
  const _BouncingEmoji({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  State<_BouncingEmoji> createState() => _BouncingEmojiState();
}

class _BouncingEmojiState extends State<_BouncingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -6 * _controller.value),
          child: child,
        );
      },
      child: Text(
        widget.emoji,
        style: TextStyle(fontSize: widget.size, height: 1),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.emoji = '🧩',
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String message;
  final String emoji;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      padding: EdgeInsets.all(compact ? 20 : 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 56 : 74,
            height: compact ? 56 : 74,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: TextStyle(fontSize: compact ? 26 : 34, height: 1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            ArcadeButton(
              label: actionLabel!,
              onPressed: onAction,
              size: ArcadeButtonSize.small,
              variant: ArcadeButtonVariant.outline,
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.title = 'Something went sideways',
    this.onRetry,
    this.retryLabel = 'Try again',
    this.compact = false,
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      color: AppColors.errorSoft,
      borderColor: AppColors.isDark
          ? AppColors.error.withValues(alpha: 0.5)
          : const Color(0xFFFFB4B4),
      padding: EdgeInsets.all(compact ? 18 : 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('😅', style: TextStyle(fontSize: compact ? 30 : 40, height: 1)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.errorDark),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.errorDark),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ArcadeButton(
              label: retryLabel,
              onPressed: onRetry,
              size: ArcadeButtonSize.small,
              variant: ArcadeButtonVariant.outline,
              icon: Icons.refresh_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class InlineBanner extends StatelessWidget {
  const InlineBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color,
    this.background,
    this.action,
  });

  final String message;
  final IconData icon;
  final Color? color;
  final Color? background;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.primary;
    final resolvedBackground = background ?? AppColors.primarySoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: resolvedColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: resolvedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.ink),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}
