import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/achievement.dart';
import '../../services/profile_achievements_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../achievements/achievement_icon.dart';
import 'achievement_trophy_wall.dart';

/// Public verified achievements on a resident profile (featured + trophy grid).
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
    final rest = entries.where((e) => !featured.contains(e)).toList();
    final wallAchievements = rest
        .map(
          (e) => UserAchievement(
            achievementId: e.achievement.id,
            status: AchievementStatus.verified,
            isProfileVisible: e.userAchievement.isProfileVisible,
            featuredOrder: e.featuredOrder,
          ),
        )
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
          _FeaturedRow(
            entries: featured,
            highlightAchievementId: highlightAchievementId,
          ),
        ],
        if (wallAchievements.isNotEmpty) ...[
          const SizedBox(height: VSpacing.md),
          if (featured.isNotEmpty)
            Text(
              'All verified',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: VFontWeight.semiBold,
              ),
            ),
          if (featured.isNotEmpty) const SizedBox(height: VSpacing.sm),
          AchievementTrophyWall(
            achievements: wallAchievements,
            maxVisible: compact ? 9 : 15,
          ),
        ],
      ],
    );
  }
}

class _FeaturedRow extends StatelessWidget {
  final List<PublicAchievementEntry> entries;
  final String? highlightAchievementId;

  const _FeaturedRow({
    required this.entries,
    this.highlightAchievementId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: VSpacing.sm,
      runSpacing: VSpacing.sm,
      children: entries.map((e) {
        final highlighted = highlightAchievementId != null &&
            e.achievement.id == highlightAchievementId;
        return InkWell(
          onTap: () => context.push(
            '/achievements/${e.achievement.category.name}',
          ),
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(VSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(VRadius.lg),
              border: Border.all(
                color: highlighted
                    ? VColors.tertiary
                    : VColors.primary.withValues(alpha: 0.25),
                width: highlighted ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                AchievementBadgeAvatar(
                  achievement: e.achievement,
                  accentColor: VColors.tertiary,
                  size: VBadgeSize.avatarCompact,
                  showEarnedBadge: true,
                ),
                const SizedBox(width: VSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.achievement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: VFontWeight.semiBold,
                        ),
                      ),
                      Text(
                        '+${e.achievement.xpValue} XP',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: VColors.warning,
                        ),
                      ),
                      if (e.story != null && e.story!.trim().isNotEmpty)
                        Text(
                          e.story!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
