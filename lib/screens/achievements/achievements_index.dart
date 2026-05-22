import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../forui/v_hub_page.dart';
import '../../config/achievements.dart' as config;
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_assets.dart';

class AchievementsIndexScreen extends ConsumerWidget {
  const AchievementsIndexScreen({super.key});

  static const _categoryMeta =
      <AchievementCategory, ({String label, IconData icon, Color color})>{
    AchievementCategory.education: (
      label: 'Education',
      icon: Icons.school,
      color: VColors.achievementEducation,
    ),
    AchievementCategory.career: (
      label: 'Career',
      icon: Icons.work,
      color: VColors.achievementCareer,
    ),
    AchievementCategory.relationships: (
      label: 'Relationships',
      icon: Icons.favorite,
      color: VColors.achievementSocial,
    ),
    AchievementCategory.health: (
      label: 'Health',
      icon: Icons.fitness_center,
      color: VColors.achievementHealth,
    ),
    AchievementCategory.skills: (
      label: 'Skills',
      icon: Icons.build,
      color: VColors.achievementCreative,
    ),
    AchievementCategory.travel: (
      label: 'Travel',
      icon: Icons.flight,
      color: VColors.achievementAdventure,
    ),
    AchievementCategory.finance: (
      label: 'Finance',
      icon: Icons.savings,
      color: VColors.achievementFinance,
    ),
    AchievementCategory.community: (
      label: 'Community',
      icon: Icons.volunteer_activism,
      color: VColors.achievementLeadership,
    ),
    AchievementCategory.funny: (
      label: 'Funny',
      icon: Icons.emoji_emotions,
      color: VColors.tertiary,
    ),
    AchievementCategory.creative: (
      label: 'Creative',
      icon: Icons.palette,
      color: VColors.achievementCreative,
    ),
    AchievementCategory.profession: (
      label: 'Profession',
      icon: Icons.verified_user,
      color: VColors.primary,
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final verifiedCount = state.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .length;
    final totalAchievements = config.achievements.length;

    final currentTier = config.getTierForXp(state.totalXp);
    final nextTierInfo = _computeNextTier(state.totalXp, currentTier);

    return VHubPage(
      title: 'Achievements',
      showBack: true,
      headerActions: [
        FHeaderAction(
          icon: const Icon(FIcons.plus),
          onPress: () => context.push('/achievements/submit'),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(achievementProvider.notifier).loadAchievements(),
        child: ListView(
          padding: const EdgeInsets.all(VSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.lg,
                vertical: VSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? VColors.surfaceContainerDark
                    : VColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(VRadius.xl),
                border: Border.all(
                  color: isDark
                      ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                      : VColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatColumn(
                    value: _AnimatedCount(target: state.totalXp),
                    label: 'Total XP',
                    color: VColors.warning,
                  ),
                  _StatColumn(
                    value: Text(
                      '$verifiedCount',
                      style: theme.textTheme.headlineLarge,
                    ),
                    label: 'Earned',
                    color: VColors.success,
                  ),
                  _StatColumn(
                    value: Text(
                      '$totalAchievements',
                      style: theme.textTheme.headlineLarge,
                    ),
                    label: 'Total',
                    color: VColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.md),

            if (nextTierInfo != null) ...[
              _NextTierProgress(
                info: nextTierInfo,
                currentTier: currentTier,
              ),
              const SizedBox(height: VSpacing.lg),
            ],

            Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: VColors.tertiary,
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Text(
                    'Categories',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$verifiedCount / $totalAchievements verified',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.sm),
              child: Text(
                'Tap a category to browse and submit photo proof.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: VSpacing.sm),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: VSpacing.sm,
                crossAxisSpacing: VSpacing.sm,
              ),
              itemCount: _categoryMeta.length,
              itemBuilder: (context, index) {
                final entry = _categoryMeta.entries.elementAt(index);
                final cat = entry.key;
                final meta = entry.value;
                final progress = ref
                    .read(achievementProvider.notifier)
                    .getCategoryProgress(cat.name);

                return _CategoryCard(
                  categoryName: cat.name,
                  label: meta.label,
                  icon: meta.icon,
                  color: meta.color,
                  earned: progress.earned,
                  total: progress.total,
                  onTap: () => context.push('/achievements/${cat.name}'),
                );
              },
            ),

            const SizedBox(height: VSpacing.lg),

            Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: VColors.tertiary,
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Text(
                    'All Achievements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.sm),

            _AchievementBadgeGrid(
              achievements: config.achievements.take(15).toList(),
              userAchievements: state.userAchievements,
              currentTier: currentTier,
            ),
          ],
        ),
      ),
    );
  }

  _NextTierInfo? _computeNextTier(int totalXp, ResidentTier currentTier) {
    final tiers = [
      (tier: ResidentTier.hustlers, required: 0),
      (tier: ResidentTier.highRollers, required: 500),
      (tier: ResidentTier.elite, required: 2000),
      (tier: ResidentTier.oldMoney, required: 10000),
      (tier: ResidentTier.apex, required: 50000),
    ];

    final currentIdx = currentTier.value - 1;
    if (currentIdx >= tiers.length - 1) return null;

    final next = tiers[currentIdx + 1];
    return _NextTierInfo(
      xpNeeded: next.required,
      nextTierName: next.tier.label,
      progress: totalXp >= next.required
          ? 1.0
          : next.required > 0
          ? totalXp / next.required
          : 1.0,
      xpRemaining: (next.required - totalXp).clamp(0, 999999),
    );
  }
}

class _NextTierInfo {
  final int xpNeeded;
  final String nextTierName;
  final double progress;
  final int xpRemaining;

  const _NextTierInfo({
    required this.xpNeeded,
    required this.nextTierName,
    required this.progress,
    required this.xpRemaining,
  });
}

class _AnimatedCount extends StatelessWidget {
  final int target;

  const _AnimatedCount({required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: const Duration(milliseconds: 1200),
      curve: VAnimation.emphasized,
      builder: (context, value, _) {
        return Text('$value', style: theme.textTheme.headlineLarge);
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  final Widget value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        value,
        const SizedBox(height: VSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(VRadius.pill),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: VFontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _NextTierProgress extends StatelessWidget {
  final _NextTierInfo info;
  final ResidentTier currentTier;

  const _NextTierProgress({required this.info, required this.currentTier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.xl),
        border: Border.all(
          color: isDark
              ? VColors.outlineVariantDark.withValues(alpha: 0.2)
              : VColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                size: VIconSize.md,
                color: VColors.warning,
              ),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Text(
                  '${info.xpRemaining} XP until ${info.nextTierName}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.sm),
            child: LinearProgressIndicator(
              value: info.progress,
              minHeight: 10,
              valueColor: const AlwaysStoppedAnimation<Color>(VColors.warning),
              backgroundColor: isDark
                  ? VColors.surfaceContainerHighDark
                  : VColors.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTier.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
              Text(
                info.nextTierName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: VColors.warning,
                  fontWeight: VFontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String categoryName;
  final String label;
  final IconData icon;
  final Color color;
  final int earned;
  final int total;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.categoryName,
    required this.label,
    required this.icon,
    required this.color,
    required this.earned,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fraction = total > 0 ? (earned / total).clamp(0.0, 1.0) : 0.0;
    final isComplete = earned >= total;
    final imagePath = WorldAssets.achievementCategoryImage(categoryName);

    return Material(
      color: isDark
          ? VColors.surfaceContainerDark
          : VColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VRadius.xl),
            border: Border.all(
              color: isComplete
                  ? VColors.success.withValues(alpha: 0.4)
                  : (isDark
                      ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                      : VColors.outlineVariant.withValues(alpha: 0.3)),
              width: isComplete ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: imagePath == null
                    ? Icon(icon, size: 21, color: color)
                    : ClipOval(
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          cacheWidth: 96,
                          errorBuilder: (_, _, _) =>
                              Icon(icon, size: 21, color: color),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.xs),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: VFontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$earned/$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: VFontSize.labelSm,
                  color: isComplete ? VColors.success : (isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant),
                  fontWeight: isComplete ? VFontWeight.bold : VFontWeight.regular,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(VRadius.sm),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? VColors.success : color,
                    ),
                    backgroundColor: isDark
                        ? VColors.surfaceContainerHighDark
                        : VColors.surfaceContainerHigh,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementBadgeGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final List<UserAchievement> userAchievements;
  final ResidentTier currentTier;

  const _AchievementBadgeGrid({
    required this.achievements,
    required this.userAchievements,
    required this.currentTier,
  });

  static int _minTierForAchievement(Achievement a) {
    if (a.xpValue >= 500) return 4;
    if (a.xpValue >= 200) return 3;
    if (a.xpValue >= 100) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = (screenWidth - (VSpacing.md * 2) - VSpacing.sm) / 2;

    final userMap = {for (final ua in userAchievements) ua.achievementId: ua};

    return Wrap(
      spacing: VSpacing.sm,
      runSpacing: VSpacing.sm,
      children: achievements.map((achievement) {
        final userAchievement = userMap[achievement.id];
        final requiredTier = _minTierForAchievement(achievement);
        final isLocked = currentTier.value < requiredTier;

        if (isLocked) {
          return _LockedAchievementCard(
            achievement: achievement,
            requiredTier: requiredTier,
            tileWidth: tileWidth,
          );
        }

        return SizedBox(
          width: tileWidth,
          child: _AchievementBadgeCard(
            achievement: achievement,
            userAchievement: userAchievement,
          ),
        );
      }).toList(),
    );
  }
}

class _AchievementBadgeCard extends StatelessWidget {
  final Achievement achievement;
  final UserAchievement? userAchievement;

  const _AchievementBadgeCard({
    required this.achievement,
    this.userAchievement,
  });

  IconData _mapIcon(String iconName) {
    return switch (iconName) {
      'school' => Icons.school,
      'translate' => Icons.translate,
      'verified' => Icons.verified,
      'work' => Icons.work,
      'trending_up' => Icons.trending_up,
      'swap_horiz' => Icons.swap_horiz,
      'store' => Icons.store,
      'corporate_fare' => Icons.corporate_fare,
      'payments' => Icons.payments,
      'home_work' => Icons.home_work,
      'beach_access' => Icons.beach_access,
      'favorite' => Icons.favorite,
      'ring_volume' => Icons.ring_volume,
      'home' => Icons.home,
      'child_care' => Icons.child_care,
      'people' => Icons.people,
      'directions_run' => Icons.directions_run,
      'monitor_weight' => Icons.monitor_weight,
      'fitness_center' => Icons.fitness_center,
      'pool' => Icons.pool,
      'directions_bike' => Icons.directions_bike,
      'block' => Icons.block,
      'self_improvement' => Icons.self_improvement,
      'code' => Icons.code,
      'music_note' => Icons.music_note,
      'restaurant' => Icons.restaurant,
      'directions_car' => Icons.directions_car,
      'surfing' => Icons.surfing,
      'mic' => Icons.mic,
      'construction' => Icons.construction,
      'flight' => Icons.flight,
      'flight_takeoff' => Icons.flight_takeoff,
      'public' => Icons.public,
      'language' => Icons.language,
      'star' => Icons.star,
      'savings' => Icons.savings,
      'shield' => Icons.shield,
      'check_circle' => Icons.check_circle,
      'volunteer_activism' => Icons.volunteer_activism,
      'bloodtype' => Icons.bloodtype,
      'diversity_3' => Icons.diversity_3,
      'forest' => Icons.forest,
      'event' => Icons.event,
      'nightlight' => Icons.nightlight,
      'groups' => Icons.groups,
      'local_pizza' => Icons.local_pizza,
      'toys' => Icons.toys,
      'pets' => Icons.pets,
      'phone_in_talk' => Icons.phone_in_talk,
      'tv' => Icons.tv,
      'question_mark' => Icons.question_mark,
      'chair' => Icons.chair,
      'menu_book' => Icons.menu_book,
      'palette' => Icons.palette,
      'lyrics' => Icons.lyrics,
      'play_circle' => Icons.play_circle,
      'theater_comedy' => Icons.theater_comedy,
      'edit_note' => Icons.edit_note,
      'record_voice_over' => Icons.record_voice_over,
      'history_edu' => Icons.history_edu,
      'auto_stories' => Icons.auto_stories,
      'explore' => Icons.explore,
      'hiking' => Icons.hiking,
      'terrain' => Icons.terrain,
      'calendar_view_week' => Icons.calendar_view_week,
      'calendar_month' => Icons.calendar_month,
      'wb_sunny' => Icons.wb_sunny,
      'local_hospital' => Icons.local_hospital,
      'engineering' => Icons.engineering,
      'gavel' => Icons.gavel,
      'account_balance' => Icons.account_balance,
      'brush' => Icons.brush,
      _ => Icons.star,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = userAchievement?.status;
    final isVerified = status == AchievementStatus.verified;
    final isSubmitted = status == AchievementStatus.submitted;

    final iconData = _mapIcon(achievement.icon);
    final Color accentColor;
    final String statusLabel;

    if (isVerified) {
      accentColor = VColors.success;
      statusLabel = 'Verified';
    } else if (isSubmitted) {
      accentColor = VColors.warning;
      statusLabel = 'Pending';
    } else {
      accentColor = VColors.tertiary;
      statusLabel = 'Available';
    }

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.xl),
        border: Border.all(
          color: isDark
              ? VColors.outlineVariantDark.withValues(alpha: 0.2)
              : VColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.15),
                ),
                child: Icon(iconData, size: 18, color: accentColor),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  boxShadow: isVerified || isSubmitted
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            achievement.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.semiBold,
              color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            achievement.description,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '+${achievement.xpValue} XP',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: VFontWeight.semiBold,
              color: VColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedAchievementCard extends StatelessWidget {
  final Achievement achievement;
  final int requiredTier;
  final double tileWidth;

  const _LockedAchievementCard({
    required this.achievement,
    required this.requiredTier,
    required this.tileWidth,
  });

  String _tierLabel(int tier) {
    return switch (tier) {
      1 => 'Hustler',
      2 => 'High Roller',
      3 => 'Elite',
      4 => 'Old Money',
      5 => 'Apex',
      _ => 'Tier $tier',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: tileWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VRadius.xl),
        child: Stack(
          children: [
            Opacity(
              opacity: 0.5,
              child: Container(
                padding: const EdgeInsets.all(VSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? VColors.surfaceContainerDark
                      : VColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(VRadius.xl),
                  border: Border.all(
                    color: isDark
                        ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                        : VColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant)
                            .withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 18,
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: VSpacing.sm),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: (isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(VRadius.sm),
                      ),
                    ),
                    const SizedBox(height: VSpacing.xs),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: (isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(VRadius.sm),
                      ),
                    ),
                    const SizedBox(height: VSpacing.md),
                    Container(
                      height: 12,
                      width: 50,
                      decoration: BoxDecoration(
                        color: (isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(VRadius.sm),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: (isDark
                        ? VColors.surfaceDark
                        : VColors.surface)
                    .withValues(alpha: 0.6),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      size: VIconSize.lg,
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: VSpacing.xs),
                    Text(
                      'Reach ${_tierLabel(requiredTier)} to unlock',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: VFontSize.labelSm,
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
