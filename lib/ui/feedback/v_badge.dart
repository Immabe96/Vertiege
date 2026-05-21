import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class VBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isOutlined;

  const VBadge({
    super.key,
    required this.label,
    this.color,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final badgeColor = color ?? VColors.primary;

    final bgColor = isOutlined
        ? Colors.transparent
        : badgeColor.withValues(alpha: isDark ? 0.15 : 0.1);

    final textColor = isOutlined ? badgeColor : badgeColor;

    final borderColor = isOutlined
        ? badgeColor.withValues(alpha: 0.4)
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: VSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: VFontWeight.medium,
        ),
      ),
    );
  }
}

class VDotBadge extends StatelessWidget {
  final Color color;
  final double size;

  const VDotBadge({
    super.key,
    required this.color,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: VColors.surfaceBright,
          width: 1.5,
        ),
      ),
    );
  }
}
