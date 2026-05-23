import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Discord-style presence indicator.
/// Online=green, idle=yellow, dnd=red, offline=gray.
enum Presence { online, idle, dnd, offline }

class StatusDot extends StatefulWidget {
  final Presence presence;
  final double size;
  final double borderWidth;
  final bool pulseWhenOnline;

  const StatusDot({
    super.key,
    this.presence = Presence.offline,
    this.size = 12,
    this.borderWidth = 2,
    this.pulseWhenOnline = false,
  });

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  Color get _color => switch (widget.presence) {
    Presence.online => VColors.success,
    Presence.idle => VColors.warning,
    Presence.dnd => VColors.error,
    Presence.offline => VColors.outline,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.pulseWhenOnline && widget.presence == Presence.online) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseWhenOnline &&
        widget.presence == Presence.online &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if ((!widget.pulseWhenOnline ||
            widget.presence != Presence.online) &&
        _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pulseWhenOnline && widget.presence == Presence.online) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.3);
          return Transform.scale(scale: scale, child: child);
        },
        child: _buildDot(context, 0.25 + (_pulseController.value * 0.15)),
      );
    }
    return _buildDot(context, 1.0);
  }

  Widget _buildDot(BuildContext context, double opacity) {
    final glassSize = widget.size + widget.borderWidth * 2 + 4;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
            width: glassSize,
            height: glassSize,
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: VColors.outlineVariant),
            ),
            child: Center(
              child: Container(
                width: widget.size - widget.borderWidth,
                height: widget.size - widget.borderWidth,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
    );
  }
}

/// Duolingo-style animated progress bar with optional label.
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  final bool showLabel;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 16,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = color ?? VColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          builder: (context, val, _) {
            return Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: VColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(height / 2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: val,
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            );
          },
        ),
        if (showLabel) ...[
          const SizedBox(height: VSpacing.xs),
          Text(
            '${(value * 100).round()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ],
    );
  }
}
