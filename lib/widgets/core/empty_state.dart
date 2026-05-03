import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/colors.dart';
import '../../theme/design_system.dart';

/// Variant determines the color tint applied to the empty state.
enum EmptyStateVariant { default_, error, success }

/// A branded, animated "no data" widget for Vertiege.
///
/// Displays a large icon in a rounded container with a subtle background glow,
/// staggered entrance animations (icon scales in, then text slides up), and
/// an optional CTA button that fades in last.
class AppEmptyState extends ConsumerStatefulWidget {
  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateVariant variant;

  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.variant = EmptyStateVariant.default_,
  });

  @override
  ConsumerState<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends ConsumerState<AppEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _buttonFade;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AnimDurations.entrance,
      vsync: this,
    );

    // Icon scales in with a bouncy curve, starting large and settling.
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: AnimCurves.bouncy),
      ),
    );

    // Text fades and slides up after the icon starts.
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.55, curve: Curves.easeInOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.55, curve: Curves.easeInOut),
      ),
    );

    // Button fades in last.
    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeInOut),
      ),
    );

    // Subtle glowing shadow oscillates after entrance completes.
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Trigger entrance after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _variantColor() {
    switch (widget.variant) {
      case EmptyStateVariant.error:
        return AppColors.dangerRed;
      case EmptyStateVariant.success:
        return AppColors.online;
      case EmptyStateVariant.default_:
        return AppColors.seed;
    }
  }

  Color _variantBackground(Color variantColor) {
    switch (widget.variant) {
      case EmptyStateVariant.error:
        return variantColor.withValues(alpha: 0.10);
      case EmptyStateVariant.success:
        return variantColor.withValues(alpha: 0.10);
      case EmptyStateVariant.default_:
        return variantColor.withValues(alpha: 0.08);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variantColor = _variantColor();
    final variantBg = _variantBackground(variantColor);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon container with animated glow ──
                _buildIconContainer(
                  variantColor: variantColor,
                  variantBg: variantBg,
                ),

                const SizedBox(height: Spacing.lg),

                // ── Title ──
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight(FontWeights.semibold),
                        color: theme.colorScheme.onSurface,
                        letterSpacing: LetterSpacing.tight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // ── Description (optional) ──
                if (widget.description != null) ...[
                  const SizedBox(height: Spacing.sm),
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Text(
                        widget.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                          height: LineHeight.relaxed,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],

                // ── CTA button (optional) ──
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: Spacing.xl),
                  FadeTransition(
                    opacity: _buttonFade,
                    child: FilledButton.icon(
                      onPressed: widget.onAction,
                      icon: const Icon(Icons.refresh, size: IconSizes.sm),
                      label: Text(widget.actionLabel!),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lg,
                          vertical: Spacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(RadiusTokens.round),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconContainer({
    required Color variantColor,
    required Color variantBg,
  }) {
    final glowOpacity = _glowOpacity.value;
    final iconScale = _iconScale.value;

    return Transform.scale(
      scale: iconScale,
      child: Container(
        width: IconSizes.hero + Spacing.xl,
        height: IconSizes.hero + Spacing.xl,
        decoration: BoxDecoration(
          color: variantBg,
          shape: BoxShape.circle,
          boxShadow: [
            // Ambient shadow
            BoxShadow(
              color: variantColor.withValues(
                alpha: 0.12 * glowOpacity,
              ),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
            // Glow ring
            BoxShadow(
              color: variantColor.withValues(
                alpha: 0.20 * glowOpacity,
              ),
              blurRadius: 32,
              offset: Offset.zero,
            ),
          ],
        ),
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                variantColor,
                variantColor.withValues(alpha: 0.85),
              ],
            ).createShader(bounds);
          },
          child: Icon(
            widget.icon,
            size: IconSizes.hero,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Convenience widget wrapping [AppEmptyState] for error states.
///
/// Pre-configured with an error icon, "Something went wrong" title,
/// a customizable [message], and a "Retry" button wired to [onRetry].
class AppErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Something went wrong',
      description: message ?? 'An unexpected error occurred. Please try again.',
      icon: Icons.error_outline,
      actionLabel: 'Retry',
      onAction: onRetry,
      variant: EmptyStateVariant.error,
    );
  }
}
