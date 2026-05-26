import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/achievements.dart' as ach_config;
import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../achievements/achievement_icon.dart';

/// Grid of verified achievements for Identity trophy case and profile hubs.
class AchievementTrophyWall extends StatelessWidget {
  final List<UserAchievement> achievements;
  final int maxVisible;
  final VoidCallback? onViewAll;

  const AchievementTrophyWall({
    super.key,
    required this.achievements,
    this.maxVisible = 12,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final verified = achievements
        .where((a) => a.status == AchievementStatus.verified)
        .toList()
      ..sort((a, b) {
        final av = a.verifiedAt ?? a.submittedAt ?? 0;
        final bv = b.verifiedAt ?? b.submittedAt ?? 0;
        return bv.compareTo(av);
      });

    if (verified.isEmpty) {
      return Text(
        'No verified achievements yet—submit proof from the achievements hub.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark
              ? VColors.onSurfaceVariantDark
              : VColors.onSurfaceVariant,
        ),
      );
    }

    final visible = verified.take(maxVisible).toList();
    final overflow = verified.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${verified.length} verified',
              style: theme.textTheme.labelMedium?.copyWith(
                color: VColors.primary,
                fontWeight: VFontWeight.bold,
              ),
            ),
            const Spacer(),
            if (onViewAll != null || overflow > 0)
              TextButton(
                onPressed: onViewAll ?? () => context.push('/achievements'),
                child: Text(overflow > 0 ? 'View all ($overflow more)' : 'View all'),
              ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 3;
            const spacing = VSpacing.sm;
            final cellWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: visible.map((ua) {
                final def =
                    ach_config.achievementForId(ua.achievementId);
                if (def == null) return const SizedBox.shrink();
                return _TrophyCell(
                  width: cellWidth,
                  achievement: def,
                  userAchievement: ua,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TrophyCell extends StatelessWidget {
  final double width;
  final Achievement achievement;
  final UserAchievement userAchievement;

  const _TrophyCell({
    required this.width,
    required this.achievement,
    required this.userAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hidden = !userAchievement.isProfileVisible;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AchievementBadgeAvatar(
                achievement: achievement,
                accentColor: VColors.tertiary,
                size: VBadgeSize.avatar,
                showEarnedBadge: true,
              ),
              if (hidden)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: VColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.visibility_off,
                      size: 12,
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            achievement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: VFontWeight.semiBold,
              fontSize: VFontSize.labelSm,
            ),
          ),
          Text(
            '+${achievement.xpValue} XP',
            style: theme.textTheme.labelSmall?.copyWith(
              color: VColors.warning,
              fontSize: VFontSize.labelSm,
            ),
          ),
          if (achievement.category == AchievementCategory.inApp)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Auto',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: VColors.primary,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
