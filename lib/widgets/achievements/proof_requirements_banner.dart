import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Explains what proof to submit for an achievement.
class ProofRequirementsBanner extends StatelessWidget {
  final Achievement achievement;

  const ProofRequirementsBanner({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final min = achievement.effectiveMinImages;
    final max = achievement.effectiveMaxImages;

    final requirement = switch (achievement.proofType) {
      AchievementProofType.optional =>
        'Photo optional — add one to get approved faster.',
      AchievementProofType.required => 'At least one clear photo required.',
      AchievementProofType.location =>
        'Include the place or landmark in frame ($min–$max photos).',
      AchievementProofType.multi =>
        'Submit $min–$max photos that show your proof.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerHighDark
            : VColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(
          color: isDark
              ? VColors.outlineVariantDark.withValues(alpha: 0.4)
              : VColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proof requirements',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: VFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            requirement,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
          ),
          if (achievement.proofHint != null &&
              achievement.proofHint!.trim().isNotEmpty) ...[
            const SizedBox(height: VSpacing.xs),
            Text(
              achievement.proofHint!.trim(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
