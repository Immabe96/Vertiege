import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/achievements.dart' as config;
import 'package:vertiege/ui/ui.dart';
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../state/achievement_provider.dart';
import '../../state/resident_provider.dart';
import '../../widgets/core/screen_loading.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_category_sheet.dart';
import '../../widgets/achievements/achievement_icon.dart';
import '../../widgets/core/sync_warning_banner.dart';

class AchievementsIndexScreen extends ConsumerWidget {
  const AchievementsIndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementProvider);
    final resident = ref.watch(residentProvider).resident;
    final totalXp = resident?.totalXp ?? 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifier = ref.read(achievementProvider.notifier);

    final verifiedCount = state.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .length;
    final pendingCount = state.userAchievements
        .where((a) => a.status == AchievementStatus.submitted)
        .length;
    final currentTier = config.getTierForXp(totalXp);
    final nextTierInfo = _computeNextTier(totalXp, currentTier);

    final recentVerified =
        state.userAchievements
            .where((a) => a.status == AchievementStatus.verified)
            .toList()
          ..sort(
            (a, b) => (b.verifiedAt ?? b.submittedAt ?? 0).compareTo(
              a.verifiedAt ?? a.submittedAt ?? 0,
            ),
          );

    final categoryEntries = achievementCategoryMeta.entries
        .where((e) => e.key != AchievementCategory.inApp)
        .toList();

    return VHubPage(
      title: 'Achievements',
      headerActions: [
        VHeaderAction(
          icon: const Icon(VIcons.plus),
          onPress: () => context.push('/achievements/submit'),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => notifier.loadAchievements(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            VSpacing.md,
            VSpacing.md,
            VSpacing.xxl,
          ),
          children: [
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: VSpacing.md),
                child: ScreenLoading.list(),
              ),
            _StatsHeroCard(
              verifiedCount: verifiedCount,
              pendingCount: pendingCount,
              availableCount: (config.achievementCatalogSize - verifiedCount)
                  .clamp(0, config.achievementCatalogSize),
              tierLabel: currentTier.label,
              isDark: isDark,
            ),
            if (state.error != null) ...[
              const SizedBox(height: VSpacing.sm),
              SyncWarningBanner(
                message: state.error!,
                onRetry: notifier.loadAchievements,
              ),
            ],
            if (nextTierInfo != null) ...[
              const SizedBox(height: VSpacing.md),
              _NextTierProgress(info: nextTierInfo, currentTier: currentTier),
            ],
            if (recentVerified.isNotEmpty) ...[
              const SizedBox(height: VSpacing.lg),
              Text(
                'Recently verified',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              ...recentVerified.take(5).map((ua) {
                final ach = config.achievements
                    .where((a) => a.id == ua.achievementId)
                    .firstOrNull;
                if (ach == null) return const SizedBox.shrink();
                return _RecentVerifiedRow(achievement: ach);
              }),
            ],
            const SizedBox(height: VSpacing.lg),
            Text(
              'Browse by category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.semiBold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = VSpacing.sm;
                final cellWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final entry in categoryEntries)
                      SizedBox(
                        width: cellWidth,
                        child: _CategoryGridCard(
                          meta: entry.value,
                          progress: notifier.getCategoryProgress(entry.key.name),
                          onTap: () => showAchievementCategorySheet(
                            context,
                            category: entry.key,
                          ),
                        ),
                      ),
                  ],
                );
              },
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

class _StatsHeroCard extends StatelessWidget {
  final int verifiedCount;
  final int pendingCount;
  final int availableCount;
  final String tierLabel;
  final bool isDark;

  const _StatsHeroCard({
    required this.verifiedCount,
    required this.pendingCount,
    required this.availableCount,
    required this.tierLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VCard(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.lg,
          vertical: VSpacing.md,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.sm,
                    vertical: VSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: VColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                    border: Border.all(
                      color: VColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    tierLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.warning,
                      fontWeight: VFontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    value: '$verifiedCount',
                    label: 'Verified',
                    color: VColors.success,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    value: '$pendingCount',
                    label: 'Pending',
                    color: VColors.secondary,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    value: '$availableCount',
                    label: 'Available',
                    color: VColors.brand,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: VFontWeight.semiBold,
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

    return VCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${info.xpRemaining} XP until ${info.nextTierName}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.sm),
              child: LinearProgressIndicator(
                value: info.progress,
                minHeight: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  VColors.brand,
                ),
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
                    color: VColors.brand,
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

class _RecentVerifiedRow extends StatelessWidget {
  final Achievement achievement;

  const _RecentVerifiedRow({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = metaForCategory(achievement.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: VColors.brandSoft(theme.brightness),
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            alignment: Alignment.center,
            child: AchievementBadgeAvatar(
              achievement: achievement,
              accentColor: VColors.success,
              size: 28,
              status: AchievementStatus.verified,
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
                Text(
                  meta.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final AchievementCategoryMeta meta;
  final ({int earned, int total, int xp}) progress;
  final VoidCallback onTap;

  const _CategoryGridCard({
    required this.meta,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark
          ? VColors.surfaceContainerDark
          : VColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(meta.icon, color: meta.color, size: VIconSize.lg),
              const SizedBox(height: VSpacing.sm),
              Text(
                meta.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
              const SizedBox(height: VSpacing.xxs),
              Text(
                '${progress.earned} earned',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
