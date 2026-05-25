import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/profile_achievements_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../achievements/achievement_icon.dart';

/// Grid of verified achievements on a resident's public profile.
class ProfileAchievementShowcase extends StatelessWidget {
  final List<PublicAchievementEntry> entries;
  final bool compact;
  final String? highlightAchievementId;

  const ProfileAchievementShowcase({
    super.key,
    required this.entries,
    this.compact = false,
    this.highlightAchievementId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (entries.isEmpty) return const SizedBox.shrink();

    final featured = entries
        .where((e) => e.featuredOrder != null && e.featuredOrder! <= 3)
        .take(3)
        .toList();
    final rest = entries
        .where((e) => !featured.contains(e))
        .take(compact ? 6 : 12)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, size: VIconSize.md, color: VColors.tertiary),
            const SizedBox(width: VSpacing.xs),
            Text(
              'Achievements',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.semiBold,
              ),
            ),
            const Spacer(),
            Text(
              '${entries.length} verified',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (featured.isNotEmpty) ...[
          const SizedBox(height: VSpacing.md),
          Text(
            'Featured',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: VFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          _AchievementRow(
            entries: featured,
            highlightAchievementId: highlightAchievementId,
          ),
        ],
        if (rest.isNotEmpty) ...[
          const SizedBox(height: VSpacing.md),
          if (featured.isNotEmpty)
            Text(
              'More',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: VFontWeight.semiBold,
              ),
            ),
          if (featured.isNotEmpty) const SizedBox(height: VSpacing.sm),
          _AchievementRow(
            entries: rest,
            highlightAchievementId: highlightAchievementId,
          ),
        ],
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final List<PublicAchievementEntry> entries;
  final String? highlightAchievementId;

  const _AchievementRow({
    required this.entries,
    this.highlightAchievementId,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: VSpacing.sm,
      runSpacing: VSpacing.sm,
      children: entries
          .map(
            (e) => _Chip(
              entry: e,
              highlighted: highlightAchievementId != null &&
                  e.achievement.id == highlightAchievementId,
            ),
          )
          .toList(),
    );
  }
}

class _Chip extends StatelessWidget {
  final PublicAchievementEntry entry;
  final bool highlighted;

  const _Chip({required this.entry, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push(
        '/achievements/${entry.achievement.category.name}',
      ),
      borderRadius: BorderRadius.circular(VRadius.lg),
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(VSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(VRadius.lg),
          border: Border.all(
            color: highlighted
                ? VColors.tertiary
                : VColors.primary.withValues(alpha: 0.2),
            width: highlighted ? 2 : 1,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: VColors.tertiary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AchievementBadgeAvatar(
              achievement: entry.achievement,
              accentColor: VColors.tertiary,
              size: VBadgeSize.avatarCompact,
            ),
            const SizedBox(width: VSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.achievement.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                  Text(
                    '+${entry.achievement.xpValue} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
