import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class AppProgressBar extends StatelessWidget {
  final int current;
  final int max;
  final String? label;
  final double height;

  const AppProgressBar({
    super.key,
    required this.current,
    required this.max,
    this.label,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: const TextStyle(
                  fontSize: VFontSize.labelMd,
                  fontWeight: VFontWeight.bold,
                  color: VColors.onSurfaceDark,
                ),
              ),
              Text(
                '$current/$max',
                style: const TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.regular,
                  color: VColors.onSurfaceVariantDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.xs),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: height,
            backgroundColor: VColors.surfaceContainerHighestDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              VColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class SovereignProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final String? label;
  final String? trailing;

  const SovereignProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? VColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || trailing != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.regular,
                    color: VColors.onSurfaceVariantDark,
                    letterSpacing: 0,
                  ),
                ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.semiBold,
                    color: barColor,
                  ),
                ),
            ],
          ),
        if (label != null || trailing != null)
          const SizedBox(height: VSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.sm),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: VColors.surfaceContainerHighestDark.withValues(
                alpha: 0.55,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }
}
