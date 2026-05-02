import 'package:flutter/material.dart';

/// Duolingo-inspired tactile button with bottom-shadow press animation.
///
/// Resting state: 4px solid bottom border in a darker shade of the fill.
/// Pressed state: button drops 3px, bottom border shrinks to 1px.
/// Duration: 180ms (matching Duolingo's press timing).
class TactileButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  const TactileButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.fullWidth = false,
    this.height = 52,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _pressed = false;

  Color get _fillColor => widget.color ?? Theme.of(context).colorScheme.primary;
  Color get _shadowColor {
    // Compute a darker shade: Duolingo uses ~25% darker for shadow
    final hsl = HSLColor.fromColor(_fillColor);
    return hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = widget.textColor ?? theme.colorScheme.onPrimary;
    final shadowH = _pressed ? 1.0 : 4.0;

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      height: widget.height,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: widget.onPressed != null ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.onPressed != null ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(top: 4 - shadowH),
          height: widget.height - 4,
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border(bottom: BorderSide(color: _shadowColor, width: shadowH)),
          ),
          child: Center(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              offset: Offset(0, _pressed ? 0.08 : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.02,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
