import 'package:flutter/material.dart';

import '../../utils/v_motion.dart';

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
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMs),
      vsync: this,
    );
    _opacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _slide = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _scale = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (!context.motionEnabled || widget.durationMs <= 0) {
      _controller.value = 1.0;
      return;
    }

    void start() {
      if (!mounted) return;
      _controller.forward(from: 0);
    }

    if (widget.delayMs <= 0) {
      start();
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs), start);
    }

    // Safety: never leave content at opacity 0 (blocks taps on iOS/Android).
    Future.delayed(
      Duration(milliseconds: widget.delayMs + widget.durationMs + 400),
      () {
        if (mounted) _controller.value = 1.0;
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Opacity 0 excludes the subtree from hit-testing; keep a tiny floor.
  double get _hitTestOpacity {
    final v = _opacity.value;
    return v < 0.01 ? 0.01 : v;
  }

  @override
  Widget build(BuildContext context) {
    if (!context.motionEnabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _hitTestOpacity,
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
