import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class Pulse extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double? opacity;

  const Pulse({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = VRadius.sm,
    this.opacity,
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: (isDark ? VColors.surfaceContainerHighestDark : VColors.surfaceContainerHighest).withValues(
              alpha: widget.opacity ?? (0.3 + (_controller.value * 0.2)),
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// Keep old Shimmer class as a compatibility alias
class Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const Shimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = VRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Pulse(width: width, height: height, borderRadius: borderRadius);
  }
}

// ──────────────────────────────────────────────────────────
// ShimmerPostCard — backward-compatible, uses Pulse
// ──────────────────────────────────────────────────────────

class ShimmerPostCard extends StatelessWidget {
  const ShimmerPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Pulse(width: 48, height: 48, borderRadius: VRadius.pill),
          const SizedBox(width: VSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: VSpacing.xs),
                Pulse(
                  width: MediaQuery.of(context).size.width * 0.35,
                  height: VSpacing.md,
                  borderRadius: VRadius.sm,
                ),
                const SizedBox(height: VSpacing.sm),
                const Pulse(borderRadius: VRadius.sm),
                const SizedBox(height: VSpacing.xs),
                Pulse(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: VFontSize.bodyMd,
                  borderRadius: VRadius.sm,
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
// ShimmerChatTile — backward-compatible, uses Pulse
// ──────────────────────────────────────────────────────────

class ShimmerChatTile extends StatelessWidget {
  const ShimmerChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: Row(
        children: [
          const Pulse(width: 56, height: 56, borderRadius: VRadius.pill),
          const SizedBox(width: VSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pulse(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: VSpacing.md,
                  borderRadius: VRadius.sm,
                ),
                const SizedBox(height: VSpacing.xs),
                Pulse(
                  width: MediaQuery.of(context).size.width * 0.55,
                  height: VSpacing.md,
                  borderRadius: VRadius.sm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
