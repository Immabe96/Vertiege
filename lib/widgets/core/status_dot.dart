import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Discord-style presence indicator.
/// Online=green, idle=yellow, dnd=red, offline=gray.
enum Presence { online, idle, dnd, offline }

class StatusDot extends StatelessWidget {
  final Presence presence;
  final double size;
  final double borderWidth;

  const StatusDot({
    super.key,
    this.presence = Presence.offline,
    this.size = 12,
    this.borderWidth = 2,
  });

  Color get _color => switch (presence) {
    Presence.online => AppColors.online,
    Presence.idle => AppColors.idle,
    Presence.dnd => AppColors.dnd,
    Presence.offline => AppColors.offline,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.surface, width: borderWidth),
      ),
    );
  }
}

/// Duolingo-style animated progress bar.
/// Fills from 0.0 to 1.0 with a 320ms ease-out animation.
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = color ?? AppColors.owlGreen;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (context, val, _) {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
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
    );
  }
}
