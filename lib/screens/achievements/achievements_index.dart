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
      showBack: true,
      headerActions: [
        VHeaderAction(
          icon: Icon(VIcons.plus),
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
              totalXp: totalXp,
              verifiedCount: verifiedCount,
              pendingCount: pendingCount,
              tierLabel: currentTier.label,
              catalogSize: config.achievementCatalogSize,
              isDark: isDark,
            ),
            if (state.error != null) ...[
              const SizedBox(height: VSpacing.sm),
              SyncWarningBanner(
                message: state.error!,
                onRetry: () => notifier.loadAchievements(),
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
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentVerified.take(8).length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: VSpacing.sm),
                  itemBuilder: (context, index) {
                    final ua = recentVerified[index];
                    final ach = config.achievements
                        .where((a) => a.id == ua.achievementId)
                        .firstOrNull;
                    if (ach == null) return const SizedBox.shrink();
                    return _RecentVerifiedChip(achievement: ach);
                  },
                ),
              ),
            ],
            const SizedBox(height: VSpacing.lg),
            VSectionList(
              title: 'Browse by category',
              children: [
                for (final entry in categoryEntries)
                  VAchievementCategoryTile(
                    category: entry.key,
                    meta: entry.value,
                    progress: notifier.getCategoryProgress(entry.key.name),
                    onTap: () =>
                        context.push('/achievements/${entry.key.name}'),
                  ),
              ],
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
  final int totalXp;
  final int verifiedCount;
  final int pendingCount;
  final String tierLabel;
  final int catalogSize;
  final bool isDark;

  const _StatsHeroCard({
    required this.totalXp,
    required this.verifiedCount,
    required this.pendingCount,
    required this.tierLabel,
    required this.catalogSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VSurfaceCard(
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
                Text(
                  '$catalogSize achievements',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    value: '$totalXp',
                    label: 'Total XP',
                    color: VColors.warning,
                  ),
                ),
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

    return VSurfaceCard(
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
                minHeight: 8,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  VColors.warning,
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

class _RecentVerifiedChip extends StatelessWidget {
  final Achievement achievement;

  const _RecentVerifiedChip({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: 88,
      child: VSurfaceCard(
          padding: const EdgeInsets.all(VSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AchievementBadgeAvatar(
                achievement: achievement,
                accentColor: VColors.success,
                size: VBadgeSize.avatarCompact,
                status: AchievementStatus.verified,
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                achievement.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: VFontSize.labelSm,
                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                ),
              ),
            ],
          ),
      ),
    );
  }
}
