import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

// ──────────────────────────────────────────────────────────
// Shimmer — gradient-sweep loading placeholder
//
// Uses a sliding highlight gradient (like Twitter / Instagram /
// LinkedIn) instead of a plain opacity pulse. An AnimationController
// drives the highlight band across the widget surface on repeat.
// ──────────────────────────────────────────────────────────

/// A shimmer loading placeholder with a sweeping gradient highlight.
///
/// Drop-in replacement for [Skeleton] (opacity-pulse) with a modern
/// gradient-sweep effect. Configure [width], [height], and
/// [borderRadius] to match the target content.
class Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const Shimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Sweep from before the widget (-1) to beyond it (2) so the
    // highlight travels smoothly across the entire surface.
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect the current brightness so the shimmer works correctly
    // in both light and dark themes.
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final baseColor = isDark
        ? AppColors.darkSurfaceCard
        : const Color(0xFFE0E0E0);

    // The highlight colour is white blended over the base so it looks
    // like a natural reflection rather than a hard white bar.
    final highlightColor = isDark
        ? const Color(0x33FFFFFF) // ~20 % white over dark surface
        : const Color(0x66FFFFFF); // ~40 % white over light surface

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildShimmerOverlay(highlightColor, isDark),
        );
      },
    );
  }

  Widget _buildShimmerOverlay(Color highlightColor, bool isDark) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (Rect bounds) {
        final start = bounds.left + (_animation.value * bounds.width);
        // Narrow highlight band — wider for dark theme to stay visible.
        final bandWidth = bounds.width * 0.35;

        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [
            0.0,
            ((start - bounds.left) / bounds.width).clamp(0.0, 1.0),
            ((start + bandWidth * 0.5 - bounds.left) / bounds.width)
                .clamp(0.0, 1.0),
            ((start + bandWidth - bounds.left) / bounds.width)
                .clamp(0.0, 1.0),
            1.0,
          ],
          colors: [
            Colors.transparent,
            Colors.transparent,
            highlightColor,
            Colors.transparent,
            Colors.transparent,
          ],
        ).createShader(bounds);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        color: isDark
            ? AppColors.darkSurfaceCard
            : const Color(0xFFE0E0E0),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// ShimmerPostCard
// ──────────────────────────────────────────────────────────

/// A shimmer placeholder that mimics a post-card layout:
///   - Circular avatar (left)
///   - Three text lines to the right (different lengths)
class ShimmerPostCard extends StatelessWidget {
  const ShimmerPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ─────────────────────────────────
          const Shimmer(
            width: 48,
            height: 48,
            borderRadius: RadiusTokens.round,
          ),
          const SizedBox(width: Spacing.md),

          // ── Text lines ─────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spacing.xs),
                // Name / handle line
                Shimmer(
                  width: MediaQuery.of(context).size.width * 0.35,
                  height: FontSizes.body,
                  borderRadius: RadiusTokens.xs,
                ),
                const SizedBox(height: Spacing.sm),
                // Body line 1 (full width)
                const Shimmer(borderRadius: RadiusTokens.xs),
                const SizedBox(height: Spacing.xs),
                // Body line 2 (80 %)
                Shimmer(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 14,
                  borderRadius: RadiusTokens.xs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// ShimmerChatTile
// ──────────────────────────────────────────────────────────

/// A shimmer placeholder that mimics a chat-list item:
///   - Circular avatar
///   - Name line (top, ~40 % width)
///   - Message preview line (bottom, ~70 % width)
class ShimmerChatTile extends StatelessWidget {
  const ShimmerChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm + 2, // 10 px
      ),
      child: Row(
        children: [
          // ── Avatar ─────────────────────────────────
          const Shimmer(
            width: 56,
            height: 56,
            borderRadius: RadiusTokens.round,
          ),
          const SizedBox(width: Spacing.md),

          // ── Text ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Shimmer(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: FontSizes.bodyLarge,
                  borderRadius: RadiusTokens.xs,
                ),
                const SizedBox(height: Spacing.xs + 2), // 6 px
                // Message preview
                Shimmer(
                  width: MediaQuery.of(context).size.width * 0.55,
                  height: FontSizes.body,
                  borderRadius: RadiusTokens.xs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
