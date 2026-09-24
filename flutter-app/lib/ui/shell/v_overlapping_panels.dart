import 'package:flutter/material.dart';

import '../../theme/v_animation.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Panel depth for Home → Channels → Chat hierarchy (DCX-015).
enum VPanelDepth {
  /// Center feed / Nexus (Home).
  home,

  /// Channel list overlay for the selected world.
  channels,
}

/// Three-panel shell: world rail | channel list | main content.
///
/// On narrow viewports the [primary] rail stays fixed; [content] fills the rest.
/// [secondary] slides in from the left over [content] when [showSecondary] is true.
/// System back dismisses [secondary] before popping the route (no ambiguous scrim-only exit).
/// On wide viewports all three panels are shown side by side.
class VOverlappingPanels extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final Widget content;
  final bool showSecondary;
  final VoidCallback? onSecondaryDismissed;
  final VPanelDepth panelDepth;
  final double secondaryWidth;
  final double narrowBreakpoint;

  static const Duration animationDuration = VAnimation.normal;
  static const Curve animationCurve = VAnimation.standard;

  const VOverlappingPanels({
    super.key,
    required this.primary,
    required this.secondary,
    required this.content,
    this.showSecondary = false,
    this.onSecondaryDismissed,
    this.panelDepth = VPanelDepth.home,
    this.secondaryWidth = 272,
    this.narrowBreakpoint = VBreakpoint.tablet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < narrowBreakpoint;
        if (isNarrow) {
          return _NarrowLayout(
            primary: primary,
            secondary: secondary,
            content: content,
            showSecondary: showSecondary,
            onSecondaryDismissed: onSecondaryDismissed,
            panelDepth: panelDepth,
            secondaryWidth: secondaryWidth,
          );
        }
        return _WideLayout(
          primary: primary,
          secondary: secondary,
          content: content,
          secondaryWidth: secondaryWidth,
        );
      },
    );
  }
}

class _WideLayout extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final Widget content;
  final double secondaryWidth;

  const _WideLayout({
    required this.primary,
    required this.secondary,
    required this.content,
    required this.secondaryWidth,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: ColoredBox(
        color: VCommuneColors.surfacePrimary,
        child: Row(
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: primary,
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: SizedBox(
                width: secondaryWidth,
                child: ColoredBox(
                  color: VCommuneColors.surfaceSecondary,
                  child: secondary,
                ),
              ),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(3),
              child: Expanded(
                child: ColoredBox(
                  color: VCommuneColors.surfacePrimary,
                  child: content,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final Widget content;
  final bool showSecondary;
  final VoidCallback? onSecondaryDismissed;
  final VPanelDepth panelDepth;
  final double secondaryWidth;

  const _NarrowLayout({
    required this.primary,
    required this.secondary,
    required this.content,
    required this.showSecondary,
    this.onSecondaryDismissed,
    required this.panelDepth,
    required this.secondaryWidth,
  });

  void _dismissSecondary() => onSecondaryDismissed?.call();

  @override
  Widget build(BuildContext context) {
    final panelDuration = VMotion.panel(context);
    final panelCurve = VMotion.curve(context);

    final stack = FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: ColoredBox(
        color: VCommuneColors.surfacePrimary,
        child: Row(
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: primary,
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: content,
                  ),
                  if (onSecondaryDismissed != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !showSecondary,
                        child: AnimatedOpacity(
                          opacity: showSecondary ? 1 : 0,
                          duration: panelDuration,
                          curve: panelCurve,
                          child: GestureDetector(
                            onTap: _dismissSecondary,
                            behavior: HitTestBehavior.opaque,
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                    ),
                  AnimatedSlide(
                    offset: showSecondary ? Offset.zero : const Offset(-1, 0),
                    duration: panelDuration,
                    curve: panelCurve,
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(2),
                      child: SizedBox(
                        width: secondaryWidth,
                        child: ColoredBox(
                          color: VCommuneColors.surfaceSecondary,
                          child: secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onSecondaryDismissed == null) return stack;

    return PopScope(
      canPop: panelDepth == VPanelDepth.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && showSecondary) _dismissSecondary();
      },
      child: stack,
    );
  }
}
