import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/achievements.dart' as config;
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../state/achievement_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/status_dot.dart';

class AchievementsIndexScreen extends ConsumerWidget {
  const AchievementsIndexScreen({super.key});

  static const _categoryMeta = <AchievementCategory, ({
    String label,
    IconData icon,
    Color color,
  })>{
    AchievementCategory.education: (label: 'Education', icon: Icons.school, color: Color(0xFF4A90D9)),
    AchievementCategory.career: (label: 'Career', icon: Icons.work, color: Color(0xFF7B61FF)),
    AchievementCategory.relationships: (label: 'Relationships', icon: Icons.favorite, color: Color(0xFFE8456B)),
    AchievementCategory.health: (label: 'Health', icon: Icons.fitness_center, color: Color(0xFF3ECF8E)),
    AchievementCategory.skills: (label: 'Skills', icon: Icons.build, color: Color(0xFFF0B232)),
    AchievementCategory.travel: (label: 'Travel', icon: Icons.flight, color: Color(0xFF1CB0F6)),
    AchievementCategory.finance: (label: 'Finance', icon: Icons.savings, color: Color(0xFF58CC02)),
    AchievementCategory.community: (label: 'Community', icon: Icons.volunteer_activism, color: Color(0xFFFF9600)),
    AchievementCategory.funny: (label: 'Funny', icon: Icons.emoji_emotions, color: Color(0xFFCE82FF)),
    AchievementCategory.creative: (label: 'Creative', icon: Icons.palette, color: Color(0xFFFF5764)),
    AchievementCategory.profession: (label: 'Profession', icon: Icons.verified_user, color: Color(0xFFD4A843)),
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
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          // ── Stats Row ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(
                value: _AnimatedCount(target: state.totalXp),
                label: 'Total XP',
                color: AppColors.streakOrange,
              ),
              _StatColumn(
                value: Text('$verifiedCount', style: theme.textTheme.headlineLarge),
                label: 'Earned',
                color: AppColors.emerald,
              ),
              _StatColumn(
                value: Text('$totalAchievements', style: theme.textTheme.headlineLarge),
                label: 'Total',
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // ── Progress to Next Tier ─────────────────────────────
          if (nextTierInfo != null) ...[
            _NextTierProgress(info: nextTierInfo, currentTier: currentTier),
            const SizedBox(height: Spacing.lg),
          ],

          // ── Section Header ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Row(
              children: [
                Text('Categories', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$verifiedCount of $totalAchievements earned',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // ── Category Grid ─────────────────────────────────────
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
        ],
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
            borderRadius: BorderRadius.circular(RadiusTokens.round),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: LetterSpacing.wide,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Next Tier Progress Card ────────────────────────────────────────

class _NextTierProgress extends StatelessWidget {
  final _NextTierInfo info;
  final ResidentTier currentTier;

  const _NextTierProgress({required this.info, required this.currentTier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusTokens.lg)),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: IconSizes.md, color: AppColors.streakOrange),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    '${info.xpRemaining} XP until ${info.nextTierName}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            AnimatedProgressBar(
              value: info.progress,
              color: AppColors.streakOrange,
              height: 10,
            ),
            const SizedBox(height: Spacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentTier.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  info.nextTierName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.streakOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Card ──────────────────────────────────────────────────

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
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(RadiusTokens.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
            border: Border.all(
              color: isComplete
                  ? AppColors.emerald.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant,
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
                    fontWeight: FontWeight.w600,
                    height: LineHeight.tight,
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
                      ? AppColors.emerald
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: isComplete ? FontWeight.w700 : FontWeight.w400,
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
                    color: isComplete ? AppColors.emerald : color,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
