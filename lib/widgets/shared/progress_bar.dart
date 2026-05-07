import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class AppProgressBar extends StatelessWidget {
  final int current;
  final int max;
  final String? label;
  final double height;

  const AppProgressBar({super.key, required this.current, required this.max, this.label, this.height = 8});

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
              Text(label!, style: const TextStyle(fontSize: FontSizes.caption, fontWeight: FontWeights.bold, color: AppColors.ink)),
              Text('$current/$max', style: const TextStyle(fontSize: FontSizes.micro, fontWeight: FontWeights.regular, color: AppColors.inkSecondary)),
            ],
          ),
          const SizedBox(height: Spacing.xs),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: height,
            backgroundColor: AppColors.surfaceHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentLevel),
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
    final barColor = color ?? AppColors.primary;
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
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.regular,
                    color: AppColors.inkSecondary,
                    letterSpacing: LetterSpacing.label,
                  ),
                ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.semiBold,
                    color: barColor,
                  ),
                ),
            ],
          ),
        if (label != null || trailing != null) const SizedBox(height: Spacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }
}
