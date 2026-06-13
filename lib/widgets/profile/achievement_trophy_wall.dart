import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/achievements.dart' as ach_config;
import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../achievements/achievement_icon.dart';
import '../../ui/overlays/v_sheet.dart';

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
          color: theme.colorScheme.onSurfaceVariant,
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
                color: Theme.of(context).colorScheme.primary,
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
            const columns = 4;
            const spacing = VSpacing.xs;
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
      child: InkWell(
        onTap: () => showVSheet(
          context,
          _TrophyDetailSheet(
            achievement: achievement,
            userAchievement: userAchievement,
          ),
          maxSize: 0.55,
        ),
        borderRadius: BorderRadius.circular(VRadius.md),
        child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AchievementBadgeAvatar(
                achievement: achievement,
                accentColor: VColors.tertiary,
                size: VBadgeSize.avatarCompact,
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
                    child:  Icon(
                      Icons.visibility_off,
                      size: VIconSize.xs,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            achievement.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: VFontWeight.semiBold,
              fontSize: 10,
            ),
          ),
          Text(
            '+${achievement.xpValue}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: VColors.warning,
              fontSize: 10,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _TrophyDetailSheet extends StatelessWidget {
  final Achievement achievement;
  final UserAchievement userAchievement;

  const _TrophyDetailSheet({
    required this.achievement,
    required this.userAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.sm,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AchievementBadgeAvatar(
            achievement: achievement,
            accentColor: VColors.tertiary,
            size: VBadgeSize.avatarSheet,
            showEarnedBadge: true,
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            achievement.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            achievement.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            '+${achievement.xpValue} XP · Verified',
            style: theme.textTheme.labelMedium?.copyWith(
              color: VColors.warning,
              fontWeight: VFontWeight.bold,
            ),
          ),
          if (!userAchievement.isProfileVisible) ...[
            const SizedBox(height: VSpacing.sm),
            Text(
              'Hidden on your public profile',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
