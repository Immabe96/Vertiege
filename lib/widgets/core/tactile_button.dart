import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

/// Smooth glass-era button with a soft press animation.
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
    this.height = 48,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _pressed = false;

  Color get _fillColor => widget.color ?? VColors.primary;
  Color get _shadowColor {
    final hsl = HSLColor.fromColor(_fillColor);
    return hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onPressed != null;
    final textColor = (widget.textColor ?? VColors.onPrimary).withValues(
      alpha: enabled ? 1 : 0.58,
    );
    final secondFill = Color.lerp(_fillColor, VColors.secondary, 0.18)!;

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      height: widget.height,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: widget.onPressed != null
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.onPressed != null
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _fillColor.withValues(alpha: enabled ? 1 : 0.32),
                secondFill.withValues(alpha: enabled ? 1 : 0.24),
              ],
            ),
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
            border: Border.all(
              color: VColors.onPrimary.withValues(alpha: enabled ? 0.14 : 0.08),
            ),
            boxShadow: !enabled
                ? null
                : [
                    BoxShadow(
                      color: _shadowColor.withValues(
                        alpha: _pressed ? 0.15 : 0.32,
                      ),
                      blurRadius: _pressed ? 12 : 24,
                      offset: Offset(0, _pressed ? 6 : 12),
                    ),
                  ],
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
                    Icon(widget.icon, size: IconSizes.md, color: textColor),
                    const SizedBox(width: Spacing.sm),
                  ],
                  Text(
                    widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeights.semiBold,
                      letterSpacing: LetterSpacing.normal,
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
