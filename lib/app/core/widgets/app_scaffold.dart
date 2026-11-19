import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'candy_background.dart';

/// Standard page shell: candy background, safe area, optional header and a
/// centred content column that stays readable on tablets and the web.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.background = CandyBackgroundStyle.sky,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.maxWidth = 780,
    this.scrollable = true,
    this.bottomBar,
    this.onBack,
    this.showShapes = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final CandyBackgroundStyle background;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final bool scrollable;
  final Widget? bottomBar;
  final VoidCallback? onBack;
  final bool showShapes;

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole page subtree when the brightness changes. Most of the
    // UI uses the AppColors palette directly rather than Theme.of, so a keyed
    // subtree is what makes every colour swap in realtime.
    final brightness = Theme.of(context).brightness;

    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );

    return KeyedSubtree(
      key: ValueKey('app-scaffold-${brightness.name}'),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: CandyBackground(
          style: background,
          showShapes: showShapes,
          child: SafeArea(
            bottom: bottomBar == null,
            child: Column(
              children: [
                if (title != null || actions.isNotEmpty)
                  _Header(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    showBack: showBack,
                    onBack: onBack,
                    maxWidth: maxWidth,
                  ),
                Expanded(
                  child: scrollable
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: body,
                        )
                      : body,
                ),
                if (bottomBar != null)
                  SafeArea(
                    top: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: bottomBar,
                        ),
                      ),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.showBack,
    required this.onBack,
    required this.maxWidth,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showBack && Navigator.of(context).canPop())
                IconButton.filledTonal(
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.outline, width: 2),
                  ),
                ),
              if (showBack && Navigator.of(context).canPop())
                const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
