import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/season.dart';
import '../services/season_service.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../utils/world_assets.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/core/shimmer.dart';

class SeasonScreen extends ConsumerStatefulWidget {
  const SeasonScreen({super.key});

  @override
  ConsumerState<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends ConsumerState<SeasonScreen> {
  @override
  Widget build(BuildContext context) {
    final worldState = ref.watch(worldProvider);
    final allWorlds = worldState.worlds.values.toList();
    final season = SeasonService.getCurrentSeason(worlds: allWorlds);
    final rankings = season.scores;
    final isLoaded = !worldState.isLoading;

    // User's worlds (mocked for now — filter by sovereignId of current resident)
    final resident = ref.read(residentProvider).resident;
    final myWorlds = resident != null
        ? allWorlds.where((w) => w.sovereignId == resident.id).toList()
        : <dynamic>[];
    final myRankedWorlds = rankings
        .where((s) => myWorlds.any((w) => w.id == s.worldId))
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Sovereign Seasons',
          style: GoogleFonts.spaceGrotesk(
            fontSize: FontSizes.bodyLg,
            fontWeight: FontWeights.semiBold,
            color: AppColors.tertiary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: isLoaded
          ? CustomScrollView(
              slivers: [
                // ── Hero section ──────────────────────────────
                SliverToBoxAdapter(
                  child: _SeasonHero(season: season),
                ),

                // ── Progress bar ──────────────────────────────
                SliverToBoxAdapter(
                  child: _SeasonProgress(season: season),
                ),

                // ── Countdown ─────────────────────────────────
                SliverToBoxAdapter(
                  child: _CountdownBanner(season: season),
                ),

                // ── Podium (top 3) ────────────────────────────
                if (rankings.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _PodiumSection(rankings: rankings),
                  ),

                // ── Full rankings header ──────────────────────
                if (rankings.length > 3)
                  SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Full Rankings'),
                  ),

                // ── Rankings list (rest of top 10) ────────────
                if (rankings.length > 3)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final score = rankings[index + 3];
                        return _RankingRow(
                          score: score,
                          index: index + 3,
                        );
                      },
                      childCount: rankings.length - 3,
                    ),
                  ),

                // ── My Worlds section ─────────────────────────
                if (myRankedWorlds.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Your Worlds'),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final score = myRankedWorlds[index];
                        return _RankingRow(
                          score: score,
                          index: index,
                        );
                      },
                      childCount: myRankedWorlds.length,
                    ),
                  ),
                ],

                // ── Bottom padding ────────────────────────────
                const SliverToBoxAdapter(
                  child: SizedBox(height: Spacing.section),
                ),
              ],
            )
          : _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md, Spacing.sm, Spacing.md, Spacing.sm),
      itemCount: 6,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm + 4),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(RadiusTokens.xl),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: const Pulse(borderRadius: 0),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Hero Section — season name, gold glow background
// ────────────────────────────────────────────────────────────────

class _SeasonHero extends StatelessWidget {
  final Season season;

  const _SeasonHero({required this.season});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl, Spacing.section + Spacing.xxl, Spacing.xl, Spacing.xl),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            AppColors.tertiary.withValues(alpha: 0.08),
            AppColors.tertiary.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Sovereign Seasons label
          FadeIn(
            delayMs: 60,
            child: Text(
              'SOVEREIGN SEASONS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: FontSizes.labelSm,
                fontWeight: FontWeights.bold,
                letterSpacing: LetterSpacing.label,
                color: AppColors.tertiary.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Season name
          FadeIn(
            delayMs: 120,
            child: Text(
              season.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: FontSizes.displayXl,
                fontWeight: FontWeights.bold,
                height: LineHeight.display,
                letterSpacing: LetterSpacing.display,
                color: AppColors.tertiary,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          FadeIn(
            delayMs: 180,
            child: Text(
              'Worlds compete for dominance in 4-week seasonal competitions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: FontSizes.bodyMd,
                color: AppColors.inkSecondary,
                height: LineHeight.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Season Progress Bar
// ────────────────────────────────────────────────────────────────

class _SeasonProgress extends StatelessWidget {
  final Season season;

  const _SeasonProgress({required this.season});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week ${season.currentWeek} of 4',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.bodyMd,
                  fontWeight: FontWeights.semiBold,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${(season.progress * 100).round()}%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.bold,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
            child: LinearProgressIndicator(
              value: season.progress,
              minHeight: 6,
              backgroundColor: AppColors.glassBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Countdown Banner
// ────────────────────────────────────────────────────────────────

class _CountdownBanner extends StatelessWidget {
  final Season season;

  const _CountdownBanner({required this.season});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg, vertical: Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
          border: Border.all(
            color: AppColors.tertiary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_bottom,
              size: IconSizes.md,
              color: AppColors.tertiary,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              '${season.daysRemaining} days remaining in this season',
              style: TextStyle(
                fontSize: FontSizes.bodyMd,
                fontWeight: FontWeights.semiBold,
                color: AppColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Podium Section — gold / silver / bronze
// ────────────────────────────────────────────────────────────────

class _PodiumSection extends StatelessWidget {
  final List<SeasonWorldScore> rankings;

  const _PodiumSection({required this.rankings});

  @override
  Widget build(BuildContext context) {
    final top3 = rankings.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();

    // Arrange: 2nd (silver) / 1st (gold) / 3rd (bronze)
    final podiumOrder = <SeasonWorldScore>[];
    if (top3.length > 1) podiumOrder.add(top3[1]); // silver (2nd)
    podiumOrder.add(top3[0]); // gold (1st) — center, tallest
    if (top3.length > 2) podiumOrder.add(top3[2]); // bronze (3rd)

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md, Spacing.xl, Spacing.md, Spacing.md),
      child: Column(
        children: [
          _SectionHeader(title: 'Leaderboard'),
          const SizedBox(height: Spacing.md),
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
                  height: isGold ? 220.0 : isSilver ? 180.0 : 150.0,
                  medalColor:
                      isGold ? AppColors.tertiary : isSilver ? AppColors.silver : AppColors.bronze,
                  medalIcon:
                      isGold ? Icons.emoji_events : isSilver ? Icons.workspace_premium : Icons.military_tech,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Podium Card — medal-colored GlassPanel
// ────────────────────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      child: GestureDetector(
        onTap: () => context.push('/explore/${score.worldId}'),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(RadiusTokens.xl),
            border: Border.all(
              color: medalColor.withValues(alpha: 0.3),
            ),
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
              // Medal rank number
              Text(
                '#${score.rank}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.headlineLg,
                  fontWeight: FontWeights.bold,
                  color: medalColor,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              // Medal icon
              Icon(medalIcon, size: IconSizes.xl, color: medalColor),
              const SizedBox(height: Spacing.sm),
              // World name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                child: Text(
                  score.worldName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: FontSizes.bodyMd,
                    fontWeight: FontWeights.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xs),
              // Composite score
              Text(
                '${score.compositeScore} pts',
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.semiBold,
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Section Header
// ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md, Spacing.sm + 4, Spacing.md, Spacing.xs),
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
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: FontSizes.headlineLg,
                fontWeight: FontWeights.semiBold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Ranking Row — GlassPanel, numbered, tappable
// ────────────────────────────────────────────────────────────────

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
    if (score.trend > 0) return AppColors.success;
    if (score.trend < 0) return AppColors.error;
    return AppColors.inkMuted;
  }

  @override
  Widget build(BuildContext context) {
    final worldIcon = WorldAssets.iconForWorld(score.worldId);
    final worldAccent = WorldAssets.accentForWorld(score.worldId);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md, vertical: Spacing.xs),
      child: GestureDetector(
        onTap: () => context.push('/explore/${score.worldId}'),
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg, vertical: Spacing.md),
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
          child: Row(
            children: [
              // Rank number
              SizedBox(
                width: 36,
                child: Text(
                  '#${score.rank}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: FontSizes.headlineMd,
                    fontWeight: FontWeights.bold,
                    color: score.rank <= 3 ? AppColors.tertiary : AppColors.inkMuted,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              // World icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: worldAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  border: Border.all(
                    color: worldAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(worldIcon, size: IconSizes.md, color: worldAccent),
              ),
              const SizedBox(width: Spacing.md),
              // World name + sub-label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.worldName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FontSizes.bodyMd,
                        fontWeight: FontWeights.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Activity: ${score.activityScore}  |  Growth: +${score.memberGrowth}  |  Achievements: ${score.achievementCount}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Composite score + trend
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.compositeScore}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: FontSizes.bodyLg,
                      fontWeight: FontWeights.bold,
                      color: AppColors.tertiary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_trendIcon(), size: IconSizes.xs, color: _trendColor()),
                      const SizedBox(width: 2),
                      Text(
                        'pts',
                        style: TextStyle(
                          fontSize: FontSizes.labelSm,
                          color: AppColors.inkMuted,
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
