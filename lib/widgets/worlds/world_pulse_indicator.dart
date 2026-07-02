import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';

class WorldPulseIndicator extends StatefulWidget {
  final double activityScore;
  final Widget child;

  const WorldPulseIndicator({
    super.key,
    required this.activityScore,
    required this.child,
  });

  @override
  State<WorldPulseIndicator> createState() => _WorldPulseIndicatorState();
}

class _WorldPulseIndicatorState extends State<WorldPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (_shouldAnimate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WorldPulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!_shouldAnimate && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _pulseColor {
    if (widget.activityScore > 50) return VColors.success;
    if (widget.activityScore >= 20) return VColors.warning;
    return VColors.outline;
  }

  bool get _shouldAnimate => widget.activityScore > 10;

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _pulseColor.withValues(alpha: _animation.value),
                blurRadius: 12 + (_animation.value * 8),
                spreadRadius: 2 + (_animation.value * 4),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
