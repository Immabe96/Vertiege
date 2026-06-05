import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Discord-style three-panel shell: server rail | channel list | main content.
///
/// On narrow viewports the [primary] rail stays fixed; [content] fills the rest.
/// [secondary] slides in from the left over [content] when [showSecondary] is true.
/// On wide viewports all three panels are shown side by side.
class VOverlappingPanels extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final Widget content;
  final bool showSecondary;
  final VoidCallback? onSecondaryDismissed;
  final double secondaryWidth;
  final double narrowBreakpoint;

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeOutCubic;

  const VOverlappingPanels({
    super.key,
    required this.primary,
    required this.secondary,
    required this.content,
    this.showSecondary = false,
    this.onSecondaryDismissed,
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
    return ColoredBox(
      color: VCommuneColors.surfacePrimary,
      child: Row(
        children: [
          primary,
          SizedBox(
            width: secondaryWidth,
            child: ColoredBox(
              color: VCommuneColors.surfaceSecondary,
              child: secondary,
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: VCommuneColors.surfacePrimary,
              child: content,
            ),
          ),
        ],
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
  final double secondaryWidth;

  const _NarrowLayout({
    required this.primary,
    required this.secondary,
    required this.content,
    required this.showSecondary,
    this.onSecondaryDismissed,
    required this.secondaryWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VCommuneColors.surfacePrimary,
      child: Row(
        children: [
          primary,
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                content,
                if (onSecondaryDismissed != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !showSecondary,
                      child: AnimatedOpacity(
                        opacity: showSecondary ? 1 : 0,
                        duration: VOverlappingPanels.animationDuration,
                        curve: VOverlappingPanels.animationCurve,
                        child: GestureDetector(
                          onTap: onSecondaryDismissed,
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
                  duration: VOverlappingPanels.animationDuration,
                  curve: VOverlappingPanels.animationCurve,
                  child: SizedBox(
                    width: secondaryWidth,
                    child: ColoredBox(
                      color: VCommuneColors.surfaceSecondary,
                      child: secondary,
                    ),
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
