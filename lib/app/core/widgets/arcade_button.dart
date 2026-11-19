import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/feedback.dart';

enum ArcadeButtonVariant { primary, yellow, mint, pink, purple, outline, ghost }

enum ArcadeButtonSize { small, medium, large }

/// Playful, tactile button with a chunky bottom edge that compresses on press.
class ArcadeButton extends StatefulWidget {
  const ArcadeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailing,
    this.variant = ArcadeButtonVariant.primary,
    this.size = ArcadeButtonSize.medium,
    this.loading = false,
    this.expand = false,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? trailing;
  final ArcadeButtonVariant variant;
  final ArcadeButtonSize size;
  final bool loading;
  final bool expand;
  final bool enabled;
  final String? semanticLabel;

  bool get _interactive => enabled && !loading && (onPressed != null);

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _pressed = false;

  ({Color background, Color foreground, Color edge, Color border})
  get _palette {
    return switch (widget.variant) {
      ArcadeButtonVariant.primary => (
        background: AppColors.primary,
        foreground: AppColors.onAccent,
        edge: AppColors.primaryDark,
        border: AppColors.primaryDark,
      ),
      ArcadeButtonVariant.yellow => (
        background: AppColors.yellow,
        foreground: AppColors.ink,
        edge: AppColors.yellowDark,
        border: AppColors.yellowDark,
      ),
      ArcadeButtonVariant.mint => (
        background: AppColors.mint,
        foreground: const Color(0xFF063B2A),
        edge: AppColors.mintDark,
        border: AppColors.mintDark,
      ),
      ArcadeButtonVariant.pink => (
        background: AppColors.pink,
        foreground: AppColors.onAccent,
        edge: AppColors.pinkDark,
        border: AppColors.pinkDark,
      ),
      ArcadeButtonVariant.purple => (
        background: AppColors.purple,
        foreground: AppColors.onAccent,
        edge: AppColors.purpleDark,
        border: AppColors.purpleDark,
      ),
      ArcadeButtonVariant.outline => (
        background: AppColors.surface,
        foreground: AppColors.ink,
        edge: AppColors.outline,
        border: AppColors.outline,
      ),
      ArcadeButtonVariant.ghost => (
        background: Colors.transparent,
        foreground: AppColors.primaryDark,
        edge: Colors.transparent,
        border: Colors.transparent,
      ),
    };
  }

  EdgeInsets get _padding => switch (widget.size) {
    ArcadeButtonSize.small => const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 10,
    ),
    ArcadeButtonSize.medium => const EdgeInsets.symmetric(
      horizontal: 22,
      vertical: 15,
    ),
    ArcadeButtonSize.large => const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 18,
    ),
  };

  double get _fontSize => switch (widget.size) {
    ArcadeButtonSize.small => 14,
    ArcadeButtonSize.medium => 16,
    ArcadeButtonSize.large => 19,
  };

  double get _radius => widget.size == ArcadeButtonSize.small ? 16 : 22;

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final disabled = !widget._interactive;
    final background = disabled ? AppColors.surfaceSoft : palette.background;
    final foreground = disabled ? AppColors.inkSoft : palette.foreground;
    final edge = disabled ? AppColors.outline : palette.edge;
    final depth = _pressed ? 2.0 : 5.0;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox(
            width: _fontSize + 2,
            height: _fontSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: _fontSize + 4, color: foreground),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: _fontSize,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: widget._interactive,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        onTapDown: widget._interactive
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: widget._interactive
            ? (_) {
                setState(() => _pressed = false);
                AppFeedback.tap();
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: widget.expand ? double.infinity : null,
          padding: _padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: disabled ? AppColors.outline : palette.border,
              width: 2,
            ),
            boxShadow: widget.variant == ArcadeButtonVariant.ghost
                ? null
                : [
                    BoxShadow(
                      color: edge,
                      offset: Offset(0, depth),
                      blurRadius: 0,
                    ),
                  ],
          ),
          transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
          child: content,
        ),
      ),
    );
  }
}
