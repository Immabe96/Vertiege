import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/achievements.dart' as config;
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../state/achievement_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/core/status_dot.dart';

class AchievementsIndexScreen extends ConsumerWidget {
  const AchievementsIndexScreen({super.key});

  static const _categoryMeta = <AchievementCategory, ({
    String label,
    IconData icon,
    Color color,
  })>{
    AchievementCategory.education: (label: 'Education', icon: Icons.school, color: AppColors.achievementEducation),
    AchievementCategory.career: (label: 'Career', icon: Icons.work, color: AppColors.achievementCareer),
    AchievementCategory.relationships: (label: 'Relationships', icon: Icons.favorite, color: AppColors.achievementRelationships),
    AchievementCategory.health: (label: 'Health', icon: Icons.fitness_center, color: AppColors.achievementHealth),
    AchievementCategory.skills: (label: 'Skills', icon: Icons.build, color: AppColors.achievementSkills),
    AchievementCategory.travel: (label: 'Travel', icon: Icons.flight, color: AppColors.achievementTravel),
    AchievementCategory.finance: (label: 'Finance', icon: Icons.savings, color: AppColors.achievementFinance),
    AchievementCategory.community: (label: 'Community', icon: Icons.volunteer_activism, color: AppColors.achievementCommunity),
    AchievementCategory.funny: (label: 'Funny', icon: Icons.emoji_emotions, color: AppColors.achievementFunny),
    AchievementCategory.creative: (label: 'Creative', icon: Icons.palette, color: AppColors.achievementCreative),
    AchievementCategory.profession: (label: 'Profession', icon: Icons.verified_user, color: AppColors.achievementProfession),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementProvider);
    final theme = Theme.of(context);

    final verifiedCount =
        state.userAchievements.where((a) => a.status == AchievementStatus.verified).length;
    final totalAchievements = config.achievements.length;

    final currentTier = config.getTierForXp(state.totalXp);
    final nextTierInfo = _computeNextTier(state.totalXp, currentTier);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(achievementProvider.notifier).loadAchievements(),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
          // ── Stats Row — glass panel ─────────────────────────
          GlassPanel(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  value: _AnimatedCount(target: state.totalXp),
                  label: 'Total XP',
                  color: AppColors.warning,
                ),
                _StatColumn(
                  value: Text('$verifiedCount', style: theme.textTheme.headlineLarge),
                  label: 'Earned',
                  color: AppColors.success,
                ),
                _StatColumn(
                  value: Text('$totalAchievements', style: theme.textTheme.headlineLarge),
                  label: 'Total',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          // ── Progress to Next Tier — glass card ───────────────
          if (nextTierInfo != null) ...[
            _NextTierProgress(info: nextTierInfo, currentTier: currentTier),
            const SizedBox(height: Spacing.lg),
          ],

          // ── Section Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Row(
              children: [
                // Gold bar
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text('Categories', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$verifiedCount of $totalAchievements earned',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),

          // ── Category Grid — bento glass tiles ───────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: Spacing.sm,
              crossAxisSpacing: Spacing.sm,
              childAspectRatio: 1.0,
            ),
            itemCount: _categoryMeta.length,
            itemBuilder: (context, index) {
              final entry = _categoryMeta.entries.elementAt(index);
              final cat = entry.key;
              final meta = entry.value;
              final progress = ref.read(achievementProvider.notifier).getCategoryProgress(cat.name);

              return _CategoryCard(
                label: meta.label,
                icon: meta.icon,
                color: meta.color,
                earned: progress.earned,
                total: progress.total,
                onTap: () => context.push('/achievements/${cat.name}'),
              );
            },
          ),

          const SizedBox(height: Spacing.lg),

          // ── Section Header: All Achievements ──────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text('All Achievements', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),

          // ── Individual Badges Grid ──────────────────────────────
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
    if (currentIdx >= tiers.length - 1) return null; // Already at max

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

// ─── Animated Count Widget ──────────────────────────────────────────

class _AnimatedCount extends StatelessWidget {
  final int target;

  const _AnimatedCount({required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          '$value',
          style: theme.textTheme.headlineLarge,
        );
      },
    );
  }
}

// ─── Stat Column ────────────────────────────────────────────────────

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
        const SizedBox(height: Spacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeights.bold,
              letterSpacing: LetterSpacing.micro,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Next Tier Progress Card — glass panel ──────────────────────────

class _NextTierProgress extends StatelessWidget {
  final _NextTierInfo info;
  final ResidentTier currentTier;

  const _NextTierProgress({required this.info, required this.currentTier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: IconSizes.md, color: AppColors.warning),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  '${info.xpRemaining} XP until ${info.nextTierName}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeights.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          AnimatedProgressBar(
            value: info.progress,
            color: AppColors.warning,
            height: 10,
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTier.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              Text(
                info.nextTierName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeights.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Category Card — bento glass tile ───────────────────────────────

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int earned;
  final int total;
  final VoidCallback onTap;

  const _CategoryCard({
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
    final fraction = total > 0 ? (earned / total).clamp(0.0, 1.0) : 0.0;
    final isComplete = earned >= total;

    return Material(
      color: AppColors.glassBackground,
      borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
            border: Border.all(
              color: isComplete
                  ? AppColors.success.withValues(alpha: 0.4)
                  : AppColors.glassBorder,
              width: isComplete ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: Spacing.xs + 2),
              // Category name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeights.bold,
                    height: LineHeight.button,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              // Progress fraction
              Text(
                '$earned/$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: FontSizes.caption - 1,
                  color: isComplete
                      ? AppColors.success
                      : AppColors.inkMuted,
                  fontWeight: isComplete ? FontWeights.bold : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              // Small progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs + 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 3,
                    color: isComplete ? AppColors.success : color,
                    backgroundColor: AppColors.surfaceOverlay,
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

// ─── Achievement Badge Grid ────────────────────────────────────────
// Displays individual achievement badges in a 2-column bento grid

class _AchievementBadgeGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final List<UserAchievement> userAchievements;
  final ResidentTier currentTier;

  const _AchievementBadgeGrid({
    required this.achievements,
    required this.userAchievements,
    required this.currentTier,
  });

  /// Minimum tier required for an achievement to be visible/unlocked.
  static int _minTierForAchievement(Achievement a) {
    if (a.xpValue >= 500) return 4;
    if (a.xpValue >= 200) return 3;
    if (a.xpValue >= 100) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = (screenWidth - (Spacing.md * 2) - Spacing.sm) / 2;

    final userMap = {
      for (final ua in userAchievements) ua.achievementId: ua,
    };

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
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

// ─── Individual Achievement Badge Card ─────────────────────────────

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
    final status = userAchievement?.status;
    final isVerified = status == AchievementStatus.verified;
    final isSubmitted = status == AchievementStatus.submitted;

    final iconData = _mapIcon(achievement.icon);
    final Color accentColor;
    final String statusLabel;

    if (isVerified) {
      accentColor = AppColors.success;
      statusLabel = 'Verified';
    } else if (isSubmitted) {
      accentColor = AppColors.warning;
      statusLabel = 'Pending';
    } else {
      accentColor = AppColors.tertiary;
      statusLabel = 'Available';
    }

    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.md),
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
                  color: accentColor.withValues(alpha: 0.12),
                ),
                child: Icon(iconData, size: 18, color: accentColor),
              ),
              const Spacer(),
              // Status dot
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
                style: TextStyle(
                  fontSize: FontSizes.labelSm - 1,
                  fontWeight: FontWeights.semiBold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            achievement.title,
            style: const TextStyle(
              fontSize: FontSizes.bodyMd,
              fontWeight: FontWeights.semiBold,
              color: AppColors.ink,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            achievement.description,
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              color: AppColors.inkSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '+${achievement.xpValue} XP',
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              fontWeight: FontWeights.semiBold,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Locked Achievement Card — blur overlay ─────────────────────────

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
    return SizedBox(
      width: tileWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
        child: Stack(
          children: [
            // Behind: ghosted tile
            Opacity(
              opacity: 0.5,
              child: GlassPanel(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.inkMuted.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 18,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    // Ghost text placeholder
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.inkMuted.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.inkMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 12,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.inkMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Blur overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: AppColors.canvas.withValues(alpha: 0.3),
                ),
              ),
            ),
            // Lock icon + label centered
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock,
                      size: IconSizes.lg,
                      color: AppColors.inkMuted,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Reach ${_tierLabel(requiredTier)} to unlock',
                      style: const TextStyle(
                        fontSize: FontSizes.labelSm - 1,
                        color: AppColors.inkMuted,
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
