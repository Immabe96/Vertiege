import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/core/v_surface_card.dart';
import '../router/world_navigation.dart';
import 'package:vertiege/ui/ui.dart';
import '../models/season.dart';
import '../models/season_cohort.dart';
import '../services/season_cohort_service.dart';
import '../services/season_service.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../utils/world_assets.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/shimmer.dart';

class SeasonScreen extends ConsumerStatefulWidget {
  final bool embedInHub;

  const SeasonScreen({super.key, this.embedInHub = false});

  @override
  ConsumerState<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends ConsumerState<SeasonScreen> {
  SeasonCohortSummary? _cohort;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCohort());
  }

  Future<void> _loadCohort() async {
    final resident = ref.read(residentProvider).resident;
    final worldId = resident?.joinedWorldIds.firstOrNull;
    if (worldId == null) return;
    final cohort = await SeasonCohortService.getSummary(worldId);
    if (cohort == null) {
      final ensured = await SeasonCohortService.ensureMembership(worldId);
      if (mounted) setState(() => _cohort = ensured);
      return;
    }
    if (mounted) setState(() => _cohort = cohort);
  }

  @override
  Widget build(BuildContext context) {
    final worldState = ref.watch(worldProvider);
    final allWorlds = worldState.worlds.values.toList();
    final season = SeasonService.getCurrentSeason(worlds: allWorlds);
    final rankings = season.scores;
    final isLoaded = !worldState.isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resident = ref.watch(residentProvider).resident;
    final lowPressure = resident?.leaderboardOptOut ?? false;
    final myWorlds = resident != null
        ? allWorlds
              .where(
                (w) =>
                    w.sovereignId == resident.id ||
                    resident.joinedWorldIds.contains(w.id),
              )
              .toList()
        : <dynamic>[];
    final myRankedWorlds = rankings
        .where((s) => myWorlds.any((w) => w.id == s.worldId))
        .toList();

    final unclaimed = SeasonService.unclaimedWorlds(allWorlds);
    final growing = SeasonService.growingWorldCount(allWorlds);

    final body = isLoaded
        ? CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VSpacing.md,
                    VSpacing.md,
                    VSpacing.md,
                    0,
                  ),
                  child: Text(
                    'Season ranks worlds by growth — not the same as weekly Ascension Leagues (personal XP ladders).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SeasonHero(
                  season: season,
                  unclaimedCount: unclaimed.length,
                  growingCount: growing,
                ),
              ),
              if (lowPressure)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      VSpacing.md,
                      0,
                      VSpacing.md,
                      VSpacing.sm,
                    ),
                    child: _LowPressureNote(),
                  ),
                ),
              if (_cohort != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VSpacing.md,
                      0,
                      VSpacing.md,
                      VSpacing.sm,
                    ),
                    child: _SeasonCohortCard(cohort: _cohort!),
                  ),
                ),
              if (season.pillars.isNotEmpty)
                SliverToBoxAdapter(
                  child: _SeasonGuideExpansion(season: season),
                ),
              SliverToBoxAdapter(child: _SeasonProgress(season: season)),
              SliverToBoxAdapter(child: _CountdownBanner(season: season)),
              if (rankings.isNotEmpty)
                SliverToBoxAdapter(child: _PodiumSection(rankings: rankings)),
              if (rankings.length > 3)
                SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Full Rankings'),
                ),
              if (rankings.length > 3)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final score = rankings[index + 3];
                    return _RankingRow(score: score, index: index + 3);
                  }, childCount: rankings.length - 3),
                ),
              if (myRankedWorlds.isNotEmpty) ...[
                SliverToBoxAdapter(child: _SectionHeader(title: 'Your Worlds')),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final score = myRankedWorlds[index];
                    return _RankingRow(score: score, index: index);
                  }, childCount: myRankedWorlds.length),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: VSpacing.xxl)),
            ],
          )
        : _buildLoading(isDark);

    if (widget.embedInHub) return body;

    return VHubPage(title: 'Season 1', showBack: true, body: body);
  }

  Widget _buildLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        VSpacing.sm,
      ),
      itemCount: 6,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark
                ? VColors.surfaceContainerDark
                : VColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(VRadius.xl),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: const Pulse(borderRadius: 0),
        ),
      ),
    );
  }
}

class _SeasonCohortCard extends StatelessWidget {
  final SeasonCohortSummary cohort;

  const _SeasonCohortCard({required this.cohort});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VSurfaceCard(
      padding: const EdgeInsets.all(VSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, color: VColors.tertiary),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your cohort',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  cohort.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
                Text(
                  '${cohort.memberCount} members competing in season challenges'
                  '${cohort.matchBand != null ? ' · ${cohort.matchBand} band' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LowPressureNote extends StatelessWidget {
  const _LowPressureNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.self_improvement, size: VIconSize.base, color: VColors.tertiary),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Text(
              'Low-pressure mode is on — rankings are hidden for you.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () => context.push('/settings'),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}

class _SeasonGuideExpansion extends StatelessWidget {
  final Season season;

  const _SeasonGuideExpansion({required this.season});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        0,
        VSpacing.md,
        VSpacing.md,
      ),
      child: VSurfaceCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            title: const Text('How this season works'),
            subtitle: Text(
              'World growth leaderboard — not a weekly XP grind league.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            initiallyExpanded: false,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.md,
                  0,
                  VSpacing.md,
                  VSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(season.narrative, style: theme.textTheme.bodySmall),
                    const SizedBox(height: VSpacing.sm),
                    Text(
                      'Score blends activity (×2), member growth (×10), and prestige (×5). '
                      'Growth is earned in worlds — not bought.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: VSpacing.sm),
                    for (final pillar in season.pillars)
                      Padding(
                        padding: const EdgeInsets.only(bottom: VSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.bolt,
                              size: VIconSize.sm,
                              color: VColors.tertiary,
                            ),
                            const SizedBox(width: VSpacing.xs),
                            Expanded(
                              child: Text(
                                pillar,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonHero extends StatelessWidget {
  final Season season;
  final int unclaimedCount;
  final int growingCount;

  const _SeasonHero({
    required this.season,
    required this.unclaimedCount,
    required this.growingCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        VSpacing.xl,
        VSpacing.lg,
        VSpacing.xl,
        VSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            VColors.tertiary.withValues(alpha: 0.08),
            VColors.tertiary.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          FadeIn(
            delayMs: 60,
            child: Text(
              'SEASON 1',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: VFontWeight.bold,
                letterSpacing: 1.5,
                color: VColors.tertiary.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          FadeIn(
            delayMs: 120,
            child: Text(
              'THE BIG BANG',
              textAlign: TextAlign.center,
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: VFontWeight.bold,
                color: VColors.tertiary,
              ),
            ),
          ),
          const SizedBox(height: VSpacing.md),
          FadeIn(
            delayMs: 180,
            child: Text(
              season.tagline,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          FadeIn(
            delayMs: 240,
            child: Text(
              '$unclaimedCount realms awaiting sovereigns · $growingCount worlds growing',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: VColors.tertiary,
              ),
            ),
          ),
          if (season.narrative.isNotEmpty) ...[
            const SizedBox(height: VSpacing.md),
            FadeIn(
              delayMs: 300,
              child: Text(
                season.narrative,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeasonProgress extends StatelessWidget {
  final Season season;

  const _SeasonProgress({required this.season});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.xl,
        vertical: VSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week ${season.currentWeek} of 4',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${(season.progress * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: VFontWeight.bold,
                  color: VColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.sm),
            child: LinearProgressIndicator(
              value: season.progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? VColors.surfaceContainerHighDark
                  : VColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(VColors.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  final Season season;

  const _CountdownBanner({required this.season});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.lg,
          vertical: VSpacing.md,
        ),
        decoration: BoxDecoration(
          color: VColors.tertiary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(VRadius.xl),
          border: Border.all(color: VColors.tertiary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_bottom,
              size: VIconSize.md,
              color: VColors.tertiary,
            ),
            const SizedBox(width: VSpacing.sm),
            Text(
              '${season.daysRemaining} days remaining in this season',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: VFontWeight.semiBold,
                color: VColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumSection extends StatelessWidget {
  final List<SeasonWorldScore> rankings;

  const _PodiumSection({required this.rankings});

  @override
  Widget build(BuildContext context) {
    final top3 = rankings.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();

    final podiumOrder = <SeasonWorldScore>[];
    if (top3.length > 1) podiumOrder.add(top3[1]);
    podiumOrder.add(top3[0]);
    if (top3.length > 2) podiumOrder.add(top3[2]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.xl,
        VSpacing.md,
        VSpacing.md,
      ),
      child: Column(
        children: [
          _SectionHeader(title: 'Leaderboard'),
          const SizedBox(height: VSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: podiumOrder.asMap().entries.map((entry) {
              final score = entry.value;
              final isGold = score.rank == 1;
              final isSilver = score.rank == 2;
              return Expanded(
                child: _PodiumCard(
                  score: score,
                  height: isGold
                      ? 220.0
                      : isSilver
                      ? 180.0
                      : 150.0,
                  medalColor: isGold
                      ? VColors.tertiary
                      : isSilver
                      ? VColors.secondary
                      : VColors.warning,
                  medalIcon: isGold
                      ? Icons.emoji_events
                      : isSilver
                      ? Icons.workspace_premium
                      : Icons.military_tech,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final SeasonWorldScore score;
  final double height;
  final Color medalColor;
  final IconData medalIcon;

  const _PodiumCard({
    required this.score,
    required this.height,
    required this.medalColor,
    required this.medalIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.xs),
      child: GestureDetector(
        onTap: () => context.push(exploreWorldPath(score.worldId)),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isDark
                ? VColors.surfaceContainerDark
                : VColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(VRadius.xl),
            border: Border.all(color: medalColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${score.rank}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                  color: medalColor,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              Icon(medalIcon, size: VIconSize.xl, color: medalColor),
              const SizedBox(height: VSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.sm),
                child: Text(
                  score.worldName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                '${score.compositeScore} pts',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        12,
        VSpacing.md,
        VSpacing.xs,
      ),
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
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: VFontWeight.semiBold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final SeasonWorldScore score;
  final int index;

  const _RankingRow({required this.score, required this.index});

  IconData _trendIcon() {
    if (score.trend > 0) return Icons.trending_up;
    if (score.trend < 0) return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color _trendColor() {
    if (score.trend > 0) return VColors.success;
    if (score.trend < 0) return VColors.error;
    return VColors.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final worldIcon = WorldAssets.iconForWorld(score.worldId);
    final worldAccent = WorldAssets.accentForWorld(score.worldId);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.xs,
      ),
      child: GestureDetector(
        onTap: () => context.push(exploreWorldPath(score.worldId)),
        child: Container(
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
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '#${score.rank}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: score.rank <= 3
                        ? VColors.tertiary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: VSpacing.md),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: worldAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VRadius.lg),
                  border: Border.all(color: worldAccent.withValues(alpha: 0.2)),
                ),
                child: Icon(worldIcon, size: VIconSize.md, color: worldAccent),
              ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.worldName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: VFontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Activity: ${score.activityScore}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.compositeScore}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: VFontWeight.bold,
                      color: VColors.tertiary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _trendIcon(),
                        size: VIconSize.xs,
                        color: _trendColor(),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'pts',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
