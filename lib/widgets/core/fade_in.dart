import 'package:flutter/material.dart';

class FadeIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;
  final Curve curve;
  final bool withScale;

  const FadeIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.durationMs = 500,
    this.curve = Curves.easeOutCubic,
    this.withScale = false,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMs),
      vsync: this,
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _scale = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
    // Fallback: show content after 2s even if animation never triggers
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _controller.value < 0.99) _controller.value = 1.0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show content immediately if delay is 0 (no point in animating instant content)
    if (widget.delayMs <= 0) _controller.value = 1.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(
            translation: _slide.value,
            child: widget.withScale
                ? Transform.scale(scale: _scale.value, child: child)
                : child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
