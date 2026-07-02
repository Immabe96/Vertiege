import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vertiege/ui/ui.dart';
import '../../state/league_provider.dart';
import '../../state/resident_provider.dart';
import '../../services/league_service.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/screen_loading.dart';
import '../../utils/calm_ranking.dart';
import '../../widgets/progression/prestige_noir_ui.dart';

class LeagueScreen extends ConsumerStatefulWidget {
  final bool embedInHub;

  const LeagueScreen({super.key, this.embedInHub = false});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leagueProvider.notifier).loadLeague();
    });
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdown();
    });
  }

  void _updateCountdown() {
    final season = ref.read(leagueProvider).currentSeason;
    if (season != null) {
      final diff = season.endDate.difference(DateTime.now());
      setState(() {
        _timeRemaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final leagueState = ref.watch(leagueProvider);

    final body = leagueState.isLoading
        ? const ScreenLoading.list()
        : leagueState.error != null
        ? AppErrorState(
            message: leagueState.error,
            onRetry: () => ref.read(leagueProvider.notifier).loadLeague(),
          )
        : RefreshIndicator(
            onRefresh: () async {
              await ref.read(leagueProvider.notifier).loadLeague();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.lg),
                    child: Column(
                      children: [
                        _buildRankHero(leagueState),
                        const SizedBox(height: VSpacing.md),
                        _buildSeasonInfo(leagueState),
                        const SizedBox(height: VSpacing.md),
                        _buildPromotionInfo(),
                      ],
                    ),
                  ),
                ),
                if (!leagueState.isLoading && leagueState.standings.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.lg),
                      child: AppEmptyState(
                        title: 'No standings yet',
                        description:
                            'Earn XP this week to appear in your league cohort.',
                        icon: Icons.leaderboard_outlined,
                        actionLabel: 'Refresh',
                        onAction: () =>
                            ref.read(leagueProvider.notifier).loadLeague(),
                      ),
                    ),
                  )
                else ...[
                  const SliverToBoxAdapter(
                    child: PrestigeSectionLabel(
                      'Standings',
                      padding: EdgeInsets.fromLTRB(
                        VSpacing.lg,
                        0,
                        VSpacing.lg,
                        VSpacing.sm,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
                    sliver: _buildStandingsList(leagueState),
                  ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.lg),
                    child: _buildRewardsSection(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: VSpacing.xxl)),
              ],
            ),
          );

    if (widget.embedInHub) return body;

    return VHubPage(
      title: 'League',
      showBack: true,
      headerActions: [
        VHeaderAction(
          icon: const Icon(VIcons.rotateCw),
          onPress: () => ref.read(leagueProvider.notifier).loadLeague(),
        ),
      ],
      body: body,
    );
  }

  String _leagueRankLabel(WidgetRef ref, UserLeagueInfo userLeague) {
    final lowPressure =
        ref.read(residentProvider).resident?.leaderboardOptOut == true;
    if (lowPressure) return 'Rankings hidden';
    final leagueState = ref.read(leagueProvider);
    final calm = CalmRanking.leagueBandLabel(
      rank: userLeague.rank,
      cohortSize: leagueState.standings.length,
    );
    return calm ?? 'Building momentum in your league';
  }

  String _standingRankLabel(int rank, int cohortSize, bool lowPressure) {
    if (lowPressure) return '—';
    if (rank <= 3) return '$rank';
    return CalmRanking.leagueBandLabel(rank: rank, cohortSize: cohortSize) ??
        '$rank';
  }

  String _formatTier(String tier) {
    if (tier.isEmpty) return 'Bronze';
    return tier[0].toUpperCase() + tier.substring(1).toLowerCase();
  }

  Widget _buildRankHero(LeagueState state) {
    final userLeague = state.userLeague;
    if (userLeague == null) return const SizedBox.shrink();

    final tierColor = LeagueService.getTierColor(userLeague.tier);
    final rankLabel = _leagueRankLabel(ref, userLeague);

    return VPrestigeCard(
      padding: const EdgeInsets.all(VSpacing.lg),
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [PrestigeNoir.surfaceRaised, Color(0xFF1A1E24)],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VColors.brand.withValues(alpha: 0.30),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [VColors.brand, VColors.brandLight],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${userLeague.rank}',
                      style: const TextStyle(
                        fontSize: VFontSize.headlineMd,
                        fontWeight: VFontWeight.extraBold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: VSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTier(userLeague.tier),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: VFontWeight.extraBold,
                            color: tierColor,
                            letterSpacing: -0.02 * 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rankLabel,
                          style: const TextStyle(
                            fontSize: VFontSize.labelMd,
                            color: PrestigeNoir.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    value: '${userLeague.weeklyXp}',
                    label: 'Points',
                    color: PrestigeNoir.foreground,
                  ),
                  _StatItem(
                    value: '${userLeague.rank}',
                    label: 'Rank',
                    color: VColors.brand,
                  ),
                  _StatItem(
                    value: '${state.standings.length}',
                    label: 'Cohort',
                    color: PrestigeNoir.foreground,
                  ),
                  _StatItem(
                    value: '${LeagueService.promotionCount}',
                    label: 'Promote',
                    color: VColors.success,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonInfo(LeagueState state) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seasonLabel = state.currentSeason != null
        ? 'Weekly league'
        : 'League season';

    return VPrestigeCard(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, size: 20, color: VColors.warning),
          const SizedBox(width: VSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seasonLabel,
                  style: const TextStyle(
                    fontSize: VFontSize.bodyMd,
                    fontWeight: VFontWeight.semiBold,
                    color: PrestigeNoir.foreground,
                  ),
                ),
                Text(
                  '$days days · ${hours}h ${minutes}m remaining',
                  style: const TextStyle(
                    fontSize: VFontSize.labelMd,
                    color: VColors.warning,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+2,500',
                style: TextStyle(
                  fontSize: VFontSize.bodyLg,
                  fontWeight: VFontWeight.bold,
                  color: VColors.brand,
                ),
              ),
              Text(
                'Season reward',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: PrestigeNoir.mutedDim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionInfo() {
    return VPrestigeCard(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.lg,
        vertical: VSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              const Icon(VIcons.chevronUp, size: VIconSize.sm, color: VColors.success),
              const SizedBox(width: VSpacing.xs),
              Text(
                'Top ${LeagueService.promotionCount} promoted',
                style: const TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: VColors.success,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(VIcons.chevronRight, size: VIconSize.sm, color: VColors.error),
              const SizedBox(width: VSpacing.xs),
              Text(
                'Bottom ${LeagueService.demotionCount} demoted',
                style: const TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: VColors.error,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsList(LeagueState state) {
    final standings = state.standings;
    final residentId = ref.read(residentProvider).resident?.id;
    final lowPressure =
        ref.read(residentProvider).resident?.leaderboardOptOut == true;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index >= standings.length) return const SizedBox.shrink();
        final participant = standings[index];
        final rank = index + 1;
        final isCurrentUser = participant.userId == residentId;
        final isTop3 = rank <= 3;
        final isDemotionZone =
            rank > (standings.length - LeagueService.demotionCount);

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildStandingRow(
            participant: participant,
            rank: rank,
            rankLabel: _standingRankLabel(rank, standings.length, lowPressure),
            isCurrentUser: isCurrentUser,
            isTop3: isTop3,
            isDemotionZone: isDemotionZone,
          ),
        );
      }, childCount: standings.length),
    );
  }

  Widget _buildStandingRow({
    required LeagueParticipant participant,
    required int rank,
    required String rankLabel,
    required bool isCurrentUser,
    required bool isTop3,
    required bool isDemotionZone,
  }) {
    final posColor = isCurrentUser || isTop3
        ? VColors.brand
        : PrestigeNoir.muted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCurrentUser ? PrestigeNoir.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: isCurrentUser
            ? Border.all(color: VColors.brand.withValues(alpha: 0.30))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                rankLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: VFontSize.bodyMd,
                  fontWeight: VFontWeight.bold,
                  color: posColor,
                ),
              ),
            ),
            const SizedBox(width: VSpacing.sm),
            VAvatar(
              imageUrl: participant.avatarUrl.isNotEmpty
                  ? participant.avatarUrl
                  : null,
              fallbackSeed: participant.name,
              size: 32,
            ),
            const SizedBox(width: VSpacing.sm),
            Expanded(
              child: Text(
                participant.name,
                style: TextStyle(
                  fontSize: VFontSize.labelMd,
                  fontWeight: isCurrentUser
                      ? VFontWeight.semiBold
                      : VFontWeight.regular,
                  color: PrestigeNoir.foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: VSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: PrestigeNoir.surfaceRaised,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PrestigeNoir.borderLight),
              ),
              child: Text(
                _formatTier(participant.leagueTier),
                style: const TextStyle(
                  fontSize: 10,
                  color: PrestigeNoir.mutedDim,
                ),
              ),
            ),
            const SizedBox(width: VSpacing.sm),
            Text(
              '${participant.weeklyXp}',
              style: TextStyle(
                fontSize: VFontSize.labelMd,
                fontWeight: VFontWeight.bold,
                color: isCurrentUser ? VColors.brand : PrestigeNoir.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (isDemotionZone && !isCurrentUser) ...[
              const SizedBox(width: VSpacing.xs),
              const Icon(
                Icons.arrow_downward,
                size: VIconSize.denseSm,
                color: VColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrestigeSectionLabel(
          'Top 10 season rewards',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: VSpacing.sm),
        const Row(
          children: [
            Expanded(
              child: _RewardCard(
                icon: '👑',
                name: 'Apex Crown',
                desc: '#1 · Exclusive title',
              ),
            ),
            SizedBox(width: VSpacing.sm),
            Expanded(
              child: _RewardCard(
                icon: '💎',
                name: 'Diamond Pack',
                desc: '#2-3 · 500 coins',
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        const Row(
          children: [
            Expanded(
              child: _RewardCard(
                icon: '⚡',
                name: 'Elite Boost',
                desc: '#4-10 · 2× XP 3 days',
              ),
            ),
            SizedBox(width: VSpacing.sm),
            Expanded(
              child: _RewardCard(
                icon: '🎖️',
                name: 'Participation',
                desc: 'All · Season badge',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: VFontWeight.extraBold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: PrestigeNoir.mutedDim,
            letterSpacing: 0.05 * 10,
          ),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String icon;
  final String name;
  final String desc;

  const _RewardCard({
    required this.icon,
    required this.name,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return VPrestigeCard(
      padding: const EdgeInsets.all(VSpacing.md),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: VFontSize.labelMd,
              fontWeight: VFontWeight.semiBold,
              color: PrestigeNoir.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: PrestigeNoir.mutedDim,
            ),
          ),
        ],
      ),
    );
  }
}
