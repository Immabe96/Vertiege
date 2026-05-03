import 'package:flutter/material.dart';

/// {@template Skeleton}
/// **DEPRECATED — use [Shimmer] from `shimmer.dart` instead.**
///
/// This widget uses a plain opacity pulse. The replacement [Shimmer]
/// (same directory) provides a gradient-sweep highlight effect that
/// matches modern apps (Twitter, Instagram, LinkedIn) and supports
/// the same `width`, `height`, and `borderRadius` parameters.
///
/// Kept to avoid a hard break for any existing import, but new code
/// should prefer `Shimmer`, `ShimmerPostCard`, and `ShimmerChatTile`.
/// {@endtemplate}
class Skeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const Skeleton({super.key, this.width = double.infinity, this.height = 20, this.borderRadius = 8});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this)
      ..repeat(reverse: true);
  }

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
        final opacity = 0.3 + (_controller.value * 0.7);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
