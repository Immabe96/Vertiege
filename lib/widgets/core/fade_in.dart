import 'package:flutter/material.dart';

class FadeIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;

  const FadeIn({super.key, required this.child, this.delayMs = 0, this.durationMs = 400});

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMs),
      vsync: this,
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _slide = Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
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
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(translation: _slide.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}
