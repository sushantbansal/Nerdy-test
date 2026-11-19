import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AnswerOptionState { idle, selected, correct, incorrect, muted }

/// Large, tappable multiple-choice answer.
///
/// States drive the post-answer feedback so children can immediately see what
/// the server marked correct.
class AnswerOptionCard extends StatefulWidget {
  const AnswerOptionCard({
    super.key,
    required this.answer,
    required this.index,
    this.state = AnswerOptionState.idle,
    this.onTap,
    this.disabled = false,
    this.large = false,
  });

  final String answer;
  final int index;
  final AnswerOptionState state;
  final VoidCallback? onTap;
  final bool disabled;

  /// Extra-large presentation for pre-readers: bigger number, taller tap area
  /// and fewer visual distractions.
  final bool large;

  @override
  State<AnswerOptionCard> createState() => _AnswerOptionCardState();
}

class _AnswerOptionCardState extends State<AnswerOptionCard> {
  bool _pressed = false;
  bool _focused = false;

  String get _letter => String.fromCharCode(65 + (widget.index % 26));

  ({Color background, Color border, Color foreground, Color badge}) get _style {
    return switch (widget.state) {
      AnswerOptionState.correct => (
        background: AppColors.mintSoft,
        border: AppColors.mintDark,
        foreground: AppColors.isDark
            ? AppColors.mintDark
            : const Color(0xFF065F46),
        badge: AppColors.mintDark,
      ),
      AnswerOptionState.incorrect => (
        background: AppColors.errorSoft,
        border: AppColors.error,
        foreground: AppColors.errorDark,
        badge: AppColors.error,
      ),
      AnswerOptionState.selected => (
        background: AppColors.primarySoft,
        border: AppColors.primary,
        foreground: AppColors.ink,
        badge: AppColors.primary,
      ),
      AnswerOptionState.muted => (
        background: AppColors.surfaceSoft,
        border: AppColors.outline,
        foreground: AppColors.inkSoft,
        badge: AppColors.outline,
      ),
      AnswerOptionState.idle => (
        background: AppColors.surface,
        border: AppColors.outline,
        foreground: AppColors.ink,
        badge: AppColors.surfaceSoft,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final canTap = !widget.disabled && widget.onTap != null;
    final selected = widget.state == AnswerOptionState.selected;
    final showBadge =
        !widget.large ||
        widget.state == AnswerOptionState.correct ||
        widget.state == AnswerOptionState.incorrect;

    return Semantics(
      button: true,
      selected: selected,
      enabled: canTap,
      label: 'Answer $_letter: ${widget.answer}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: canTap
              ? () {
                  setState(() => _pressed = false);
                  widget.onTap?.call();
                }
              : null,
          onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: canTap ? () => setState(() => _pressed = false) : null,
          onFocusChange: (focused) => setState(() => _focused = focused),
          canRequestFocus: canTap,
          borderRadius: BorderRadius.circular(22),
          focusColor: AppColors.primary.withValues(alpha: 0.10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
            constraints: widget.large
                ? const BoxConstraints(minHeight: 78)
                : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 18 : 16,
              vertical: widget.large ? 16 : 14,
            ),
            decoration: BoxDecoration(
              color: _focused && canTap
                  ? Color.alphaBlend(
                      AppColors.primary.withValues(alpha: 0.06),
                      style.background,
                    )
                  : style.background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _focused && canTap
                    ? AppColors.primaryDark
                    : style.border,
                width:
                    selected ||
                        _focused ||
                        widget.state == AnswerOptionState.correct
                    ? 3
                    : 2,
              ),
              boxShadow: canTap && !_pressed
                  ? [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.06),
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (showBadge) ...[
                  Container(
                    width: widget.large ? 42 : 34,
                    height: widget.large ? 42 : 34,
                    decoration: BoxDecoration(
                      color: style.badge,
                      borderRadius: BorderRadius.circular(
                        widget.large ? 16 : 12,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: widget.state == AnswerOptionState.correct
                        ? Icon(
                            Icons.check_rounded,
                            size: widget.large ? 28 : 20,
                            color: AppColors.onAccent,
                          )
                        : widget.state == AnswerOptionState.incorrect
                        ? Icon(
                            Icons.close_rounded,
                            size: widget.large ? 28 : 20,
                            color: AppColors.onAccent,
                          )
                        : Text(
                            _letter,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color:
                                      widget.state == AnswerOptionState.selected
                                      ? AppColors.onAccent
                                      : widget.state == AnswerOptionState.muted
                                      ? Colors.white
                                      : AppColors.inkSoft,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                  ),
                  SizedBox(width: widget.large ? 16 : 14),
                ],
                Expanded(
                  child: Text(
                    widget.answer,
                    textAlign: widget.large
                        ? TextAlign.center
                        : TextAlign.start,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: style.foreground,
                      fontSize: widget.large ? 30 : 17,
                      fontWeight: widget.large ? FontWeight.w900 : null,
                    ),
                  ),
                ),
                if (!widget.large && widget.state == AnswerOptionState.correct)
                  Text(
                    'Correct',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mintDark,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
