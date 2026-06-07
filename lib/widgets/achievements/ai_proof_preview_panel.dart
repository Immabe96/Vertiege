import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Client-side proof assist preview before submission (DCX-140).
class AiProofPreviewPanel extends StatelessWidget {
  final Achievement achievement;
  final int proofImageCount;
  final String storyText;

  const AiProofPreviewPanel({
    super.key,
    required this.achievement,
    required this.proofImageCount,
    this.storyText = '',
  });

  List<({String label, bool met})> _checklist() {
    final min = achievement.effectiveMinImages;
    final hasPhotos = proofImageCount >= min;
    final hasStory = storyText.trim().length >= 12;
    final hasHint = achievement.proofHint != null &&
        achievement.proofHint!.trim().isNotEmpty;

    return [
      (
        label: min > 0
            ? 'At least $min proof photo${min > 1 ? 's' : ''}'
            : 'Proof photos optional',
        met: min == 0 || hasPhotos,
      ),
      (
        label: 'Story adds context for verifiers',
        met: hasStory || proofImageCount > 0,
      ),
      if (hasHint)
        (
          label: 'Matches proof hint guidance',
          met: proofImageCount > 0,
        ),
      (
        label: 'Ready for human verifier review',
        met: (min == 0 || hasPhotos) && (hasStory || proofImageCount > 0),
      ),
    ];
  }

  double get _confidence {
    final items = _checklist();
    if (items.isEmpty) return 0;
    final met = items.where((i) => i.met).length;
    return met / items.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _checklist();
    final confidence = _confidence;
    final confidenceLabel = confidence >= 0.85
        ? 'Strong'
        : confidence >= 0.5
        ? 'Needs review'
        : 'Incomplete';

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: VSpacing.xs),
              Text(
                'Proof assist',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$confidenceLabel · ${(confidence * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            'Automated checklist — a human verifier makes the final call.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.met ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: item.met ? VColors.success : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodySmall,
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
