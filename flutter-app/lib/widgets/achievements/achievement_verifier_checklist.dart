import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Staff-facing prompts while reviewing proof submissions.
List<String> reviewerChecklistFor(Achievement achievement) {
  final lines = <String>[
    'Image(s) clearly show what "${achievement.title}" describes',
    'Proof is recent and authentic (not a stock photo or unrelated screenshot)',
  ];
  switch (achievement.proofType) {
    case AchievementProofType.location:
      lines.add('Location or landmark is visible in frame');
    case AchievementProofType.multi:
      lines.add(
        'At least ${achievement.effectiveMinImages} distinct photo(s) provided',
      );
    case AchievementProofType.required:
      lines.add('Required photo evidence is present and readable');
    case AchievementProofType.optional:
      lines.add('If no photo: written claim is plausible on its own');
  }
  if (achievement.proofHint != null && achievement.proofHint!.trim().isNotEmpty) {
    lines.add('Hint for residents: ${achievement.proofHint!.trim()}');
  }
  return lines;
}

class AchievementVerifierChecklist extends StatelessWidget {
  final Achievement achievement;

  const AchievementVerifierChecklist({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = reviewerChecklistFor(achievement);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviewer checklist',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        ...items.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_box_outline_blank,
                  size: VIconSize.sm,
                  color: VColors.onSurfaceVariantDark,
                ),
                const SizedBox(width: VSpacing.xs),
                Expanded(
                  child: Text(
                    line,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: VColors.onSurfaceVariantDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
