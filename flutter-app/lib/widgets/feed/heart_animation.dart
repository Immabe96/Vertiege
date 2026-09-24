import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';

class HeartAnimation extends StatefulWidget {
  final Offset tapPosition;
  final VoidCallback onDone;

  const HeartAnimation({
    super.key,
    required this.tapPosition,
    required this.onDone,
  });

  @override
  State<HeartAnimation> createState() => _HeartAnimationState();
}

class _HeartAnimationState extends State<HeartAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        widget.onDone();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.tapPosition.dx - 30,
      top: widget.tapPosition.dy - 30,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: const Icon(
                Icons.favorite,
                size: 60,
                color: VColors.error,
              ),
            ),
          );
        },
      ),
    );
  }
}

class HeartAnimationOverlay {
  static void show(BuildContext context, Offset tapPosition) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => HeartAnimation(
        tapPosition: tapPosition,
        onDone: () => entry.remove(),
      ),
    );

    Overlay.of(context).insert(entry);
  }
}
