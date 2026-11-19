import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../../services/narration_service.dart';

/// Visible, repeatable narration control.
///
/// The same instructions are always available as text, so playing with sound
/// off never removes information. New questions can opt into reading aloud
/// automatically; the speaker button lets a child hear it again as often as
/// they like.
class NarrationBar extends StatefulWidget {
  const NarrationBar({
    super.key,
    required this.text,
    this.label = 'Hear it again',
    this.autoPlay = false,
    this.compact = false,
  });

  final String text;
  final String label;
  final bool autoPlay;
  final bool compact;

  @override
  State<NarrationBar> createState() => _NarrationBarState();
}

class _NarrationBarState extends State<NarrationBar> {
  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) _scheduleSpeak();
  }

  @override
  void didUpdateWidget(NarrationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoPlay && oldWidget.text != widget.text) {
      _scheduleSpeak();
    }
  }

  void _scheduleSpeak() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speak();
    });
  }

  void _speak() {
    if (!Get.isRegistered<NarrationService>()) return;
    unawaited(Get.find<NarrationService>().speak(widget.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 10 : 12,
        vertical: widget.compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.yellow, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volume_up_rounded, size: 19, color: AppColors.yellowDark),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.compact ? 'Listen' : 'Listen with pictures',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.yellowDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _speak,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.yellowDark,
              minimumSize: const Size(48, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              widget.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.yellowDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
