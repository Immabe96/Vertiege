import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/achievement_reject_feedback.dart';

/// Structured guidance when an achievement was rejected.
class AchievementResubmitBanner extends StatelessWidget {
  final String? reviewerNotes;

  const AchievementResubmitBanner({super.key, this.reviewerNotes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final parsed = parseRejectFeedback(reviewerNotes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: VColors.error.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(color: VColors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.refresh, color: VColors.error, size: VIconSize.md),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Text(
                  'Resubmit with fixes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: VColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            parsed.reasonLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: VFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            parsed.message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            'What to do next',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: VFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          ...parsed.fixSteps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: VColors.error)),
                  Expanded(
                    child: Text(
                      step,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
