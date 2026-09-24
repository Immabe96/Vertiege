import 'package:flutter/material.dart';

import '../../config/achievements.dart' as ach_config;
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../achievements/achievement_category_meta.dart';
import '../achievements/achievement_icon.dart';

/// Marker prefix for achievement shares in channel message content.
String achievementShareContent(String achievementId, {String? note}) {
  final base = '[achievement:$achievementId]';
  if (note == null || note.trim().isEmpty) return base;
  return '$base ${note.trim()}';
}

String? achievementIdFromMessageContent(String content) {
  final match = RegExp(r'\[achievement:([^\]]+)\]').firstMatch(content);
  return match?.group(1);
}

String messageTextWithoutAchievementMarker(String content) {
  return content
      .replaceFirst(RegExp(r'\[achievement:[^\]]+\]\s*'), '')
      .trim();
}

/// Rich verified-achievement card embedded in chat bubbles.
class VAchievementAttachment extends StatelessWidget {
  final String achievementId;
  final String? trailingText;

  const VAchievementAttachment({
    super.key,
    required this.achievementId,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final ach = ach_config.achievementForId(achievementId);
    if (ach == null) return const SizedBox.shrink();

    final meta = metaForCategory(ach.category);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpacing.sm),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: meta.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AchievementBadgeAvatar(
            achievement: ach,
            accentColor: meta.color,
            size: VBadgeSize.avatarCompact,
            showEarnedBadge: true,
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified achievement',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: VColors.tertiary,
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
                Text(
                  ach.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: VCommuneColors.headerPrimary,
                  ),
                ),
                Text(
                  '${ach.xpValue} XP · ${meta.label}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: VCommuneColors.textMuted,
                  ),
                ),
                if (trailingText != null && trailingText!.isNotEmpty) ...[
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    trailingText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: VCommuneColors.textNormal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
