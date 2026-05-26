import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/achievement_reject_feedback.dart';
import 'achievement_icon.dart';

/// Compact achievement row (Forui tile style) for category lists.
class AchievementListTile extends StatelessWidget {
  final Achievement achievement;
  final AchievementStatus status;
  final VoidCallback? onPress;
  final String? aiNotes;
  final String? proofUri;
  final bool isInApp;

  const AchievementListTile({
    super.key,
    required this.achievement,
    required this.status,
    this.onPress,
    this.aiNotes,
    this.proofUri,
    this.isInApp = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = statusColor(status);
    final canOpen = status != AchievementStatus.verified;
    final isFunnyOrCreative = achievement.category == AchievementCategory.funny ||
        achievement.category == AchievementCategory.creative ||
        achievement.isFunny;

    Widget prefix = AchievementBadgeAvatar(
      achievement: achievement,
      accentColor: isFunnyOrCreative ? VColors.tertiary : accent,
      status: status,
    );

    if (hasProofThumbnail(proofUri)) {
      prefix = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          prefix,
          const SizedBox(width: VSpacing.sm),
          _ProofThumbnail(uri: proofUri!),
        ],
      );
    } else if (proofUri == 'manual' &&
        (status == AchievementStatus.submitted ||
            status == AchievementStatus.rejected)) {
      prefix = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          prefix,
          const SizedBox(width: VSpacing.sm),
          _ManualReviewBadge(),
        ],
      );
    }

    return FTile(
      enabled: canOpen,
      onPress: canOpen ? onPress : null,
      prefix: prefix,
      title: Text(
        achievement.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: VFontWeight.semiBold,
          color: isFunnyOrCreative ? VColors.tertiary : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            achievement.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _StatusPill(label: statusLabel(status), color: accent),
              const SizedBox(width: VSpacing.sm),
              Text(
                '+${achievement.xpValue} XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: VColors.warning,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
              if (isInApp) ...[
                const SizedBox(width: VSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: VColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Text(
                    'Auto',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.primary,
                      fontWeight: VFontWeight.semiBold,
                      fontSize: VFontSize.labelSm,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (status == AchievementStatus.rejected)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                aiNotes != null && aiNotes!.trim().isNotEmpty
                    ? rejectSummaryForList(aiNotes)
                    : 'Rejected — tap to review feedback and resubmit',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: VColors.error,
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
            ),
        ],
      ),
      suffix: canOpen
          ? Icon(
              FIcons.chevronRight,
              size: 18,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            )
          : Icon(Icons.check_circle, size: 20, color: accent),
    );
  }
}

class _ProofThumbnail extends StatelessWidget {
  final String uri;

  const _ProofThumbnail({required this.uri});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(VRadius.sm);
    Widget image;
    if (uri.startsWith('http')) {
      image = Image.network(
        uri,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _ThumbFallback(),
      );
    } else {
      final file = File(uri);
      image = file.existsSync()
          ? Image.file(
              file,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ThumbFallback(),
            )
          : const _ThumbFallback();
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: VColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: image,
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: VColors.surfaceContainerHigh,
      child: const Icon(Icons.image_outlined, size: 20),
    );
  }
}

class _ManualReviewBadge extends StatelessWidget {
  const _ManualReviewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: VColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.sm),
      ),
      child: const Text(
        'Manual',
        style: TextStyle(
          fontSize: VFontSize.labelSm,
          fontWeight: VFontWeight.bold,
          color: VColors.secondary,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: VFontSize.labelSm,
          fontWeight: VFontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
