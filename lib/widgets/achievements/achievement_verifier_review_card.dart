import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/achievements.dart' as ach_config;
import '../../services/achievement_review_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import 'achievement_icon.dart';
import 'achievement_verifier_checklist.dart';
import 'proof_image_gallery.dart';
import 'proof_requirements_banner.dart';

/// Staff review card for a pending achievement proof submission.
class AchievementVerifierReviewCard extends StatefulWidget {
  final PendingAchievementSubmission submission;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool compact;

  const AchievementVerifierReviewCard({
    super.key,
    required this.submission,
    required this.onApprove,
    required this.onReject,
    this.compact = false,
  });

  @override
  State<AchievementVerifierReviewCard> createState() =>
      _AchievementVerifierReviewCardState();
}

class _AchievementVerifierReviewCardState
    extends State<AchievementVerifierReviewCard> {
  ResidentReviewHistory? _history;
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await AchievementReviewService.getResidentReviewHistory(
      widget.submission.userId,
    );
    if (mounted) {
      setState(() {
        _history = history;
        _historyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = widget.submission;
    final definition = ach_config.achievements
        .where((a) => a.id == s.achievementId)
        .firstOrNull;
    final tier = ach_config.getTierForXp(s.residentTotalXp);
    final submittedLabel = s.submittedAt != null
        ? DateFormat.yMMMd().add_jm().format(s.submittedAt!.toLocal())
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (definition != null)
              AchievementBadgeAvatar(
                achievement: definition,
                accentColor: Theme.of(context).colorScheme.primary,
                size: VBadgeSize.avatar,
              )
            else
              Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary, size: VBadgeSize.avatar),
            const SizedBox(width: VSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.achievementTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: VFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.residentName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                  Text(
                    '${tier.label} · ${s.residentTotalXp} XP total',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (submittedLabel != null)
                    Text(
                      'Submitted $submittedLabel',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: VColors.error),
              tooltip: 'Reject',
              onPressed: widget.onReject,
            ),
            IconButton(
              icon: Icon(Icons.check, color: VColors.success),
              tooltip: 'Approve',
              onPressed: widget.onApprove,
            ),
          ],
        ),
        if (!widget.compact &&
            s.achievementDescription != null &&
            s.achievementDescription!.trim().isNotEmpty) ...[
          const SizedBox(height: VSpacing.sm),
          Text(
            s.achievementDescription!.trim(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
        if (!widget.compact && definition != null) ...[
          const SizedBox(height: VSpacing.md),
          ProofRequirementsBanner(achievement: definition),
          const SizedBox(height: VSpacing.md),
          AchievementVerifierChecklist(achievement: definition),
        ],
        if (!widget.compact) ...[
          const SizedBox(height: VSpacing.md),
          _ResidentHistorySection(
            loading: _historyLoading,
            history: _history,
          ),
        ],
        if (s.aiNotes != null && s.aiNotes!.trim().isNotEmpty) ...[
          const SizedBox(height: VSpacing.sm),
          Text(
            'Resident note: ${s.aiNotes!.trim()}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (s.proofUris.isNotEmpty) ...[
          const SizedBox(height: VSpacing.md),
          Text(
            'Proof (${s.proofUris.length} image${s.proofUris.length == 1 ? '' : 's'}) — tap to zoom',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: VFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          ProofImageGallery(imageUrls: s.proofUris, height: 200),
        ] else ...[
          const SizedBox(height: VSpacing.sm),
          Text(
            'No image proof (manual / text-only submission).',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ResidentHistorySection extends StatelessWidget {
  final bool loading;
  final ResidentReviewHistory? history;

  const _ResidentHistorySection({required this.loading, this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (loading) {
      return Text(
        'Loading resident history…',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final h = history ?? const ResidentReviewHistory();
    if (!h.hasPriorRejections && h.verifiedCount == 0) {
      return Text(
        'First achievement submission on record for this resident.',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resident history',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          '${h.verifiedCount} verified · ${h.rejectedCount} rejected (all time)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (h.recentRejections.isNotEmpty) ...[
          const SizedBox(height: VSpacing.xs),
          ...h.recentRejections.map((e) {
            final note = e.reviewerNotes?.trim();
            return Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.xxs),
              child: Text(
                '• ${e.achievementTitle}'
                '${note != null && note.isNotEmpty ? ': $note' : ''}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: VColors.error.withValues(alpha: 0.9),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
