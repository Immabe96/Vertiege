import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../models/achievement.dart';
import '../../services/ai_verification_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import 'achievement_icon.dart';

/// Compact achievement row (Forui tile style) for category lists.
class AchievementListTile extends StatelessWidget {
  final Achievement achievement;
  final AchievementStatus status;
  final VoidCallback? onPress;
  final double? aiConfidence;
  final String? aiNotes;

  const AchievementListTile({
    super.key,
    required this.achievement,
    required this.status,
    this.onPress,
    this.aiConfidence,
    this.aiNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = statusColor(status);
    final canOpen = status != AchievementStatus.verified;

    return FTile(
      enabled: canOpen,
      onPress: canOpen ? onPress : null,
      prefix: AchievementBadgeAvatar(
        achievement: achievement,
        accentColor: accent,
      ),
      title: Text(
        achievement.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: VFontWeight.semiBold,
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
              if (AiVerificationService.autoVerificationEnabled &&
                  aiConfidence != null &&
                  status == AchievementStatus.submitted) ...[
                const SizedBox(width: VSpacing.sm),
                Text(
                  'Check ${(aiConfidence! * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (aiNotes != null &&
              aiNotes!.isNotEmpty &&
              status == AchievementStatus.submitted)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                aiNotes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: VFontSize.labelSm,
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
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
