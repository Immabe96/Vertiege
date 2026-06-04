import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../forui/v_hub_page.dart';
import '../../state/league_provider.dart';
import '../../state/resident_provider.dart';
import '../../services/league_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/media/v_avatar.dart';
import '../../ui/icons/v_icons.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/screen_loading.dart';
import '../../utils/calm_ranking.dart';

class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return VHubPage(
      title: 'Ascension Leagues',
      showBack: true,
      headerActions: [
        FHeaderAction(
          icon: const Icon(FIcons.rotateCw),
          onPress: () => ref.read(leagueProvider.notifier).loadLeague(),
        ),
      ],
      body: leagueState.isLoading
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
                          padding: const EdgeInsets.all(VSpacing.md),
                          child: Column(
                            children: [
                              _buildLeagueHeader(leagueState, isDark),
                              const SizedBox(height: VSpacing.md),
                              _buildCountdown(isDark),
                              const SizedBox(height: VSpacing.md),
                              _buildPromotionInfo(isDark),
                            ],
                          ),
                        ),
                      ),
                      if (!leagueState.isLoading && leagueState.standings.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(VSpacing.md),
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
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VSpacing.md,
                          ),
                          sliver: _buildStandingsList(leagueState, isDark),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: VSpacing.xxl),
                      ),
                    ],
                  ),
                ),
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
    if (calm != null) return calm;
    return userLeague.rank > 0 ? 'Rank #${userLeague.rank}' : 'Unranked';
  }

  Widget _buildLeagueHeader(LeagueState state, bool isDark) {
    final userLeague = state.userLeague;
    if (userLeague == null) {
      return const SizedBox.shrink();
    }

    final tierColor = LeagueService.getTierColor(userLeague.tier);
    final tierIcon = LeagueService.getTierIcon(userLeague.tier);

    return _Card(
      useBlur: false,
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        children: [
          Icon(tierIcon, size: 48, color: tierColor),
          const SizedBox(height: VSpacing.sm),
          Text(
            userLeague.tier.toUpperCase(),
            style: TextStyle(
              fontSize: VFontSize.headlineLg,
              fontWeight: VFontWeight.bold,
              color: tierColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _leagueRankLabel(ref, userLeague),
                style: TextStyle(
                  fontSize: VFontSize.bodyLg,
                  fontWeight: VFontWeight.semiBold,
                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                ),
              ),
              const SizedBox(width: VSpacing.lg),
              Text(
                '${userLeague.weeklyXp} XP',
                style: TextStyle(
                  fontSize: VFontSize.bodyLg,
                  fontWeight: VFontWeight.semiBold,
                  color: VColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(bool isDark) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;

    return _Card(
      useBlur: false,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.lg,
        vertical: VSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, size: 20, color: VColors.tertiary),
          const SizedBox(width: VSpacing.sm),
          Text(
            'Reset in ',
            style: TextStyle(
              fontSize: VFontSize.labelMd,
              color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
            ),
          ),
          Text(
            '${days}d ${hours}h ${minutes}m',
            style: const TextStyle(
              fontSize: VFontSize.labelMd,
              fontWeight: VFontWeight.bold,
              color: VColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionInfo(bool isDark) {
    return _Card(
      useBlur: false,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.lg,
        vertical: VSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              const Icon(VIcons.chevronUp, size: 16, color: VColors.success),
              const SizedBox(width: VSpacing.xs),
              Text(
                'Top ${LeagueService.promotionCount} promoted',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: VColors.success,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(VIcons.chevronRight, size: 16, color: VColors.error),
              const SizedBox(width: VSpacing.xs),
              Text(
                'Bottom ${LeagueService.demotionCount} demoted',
                style: TextStyle(
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

  Widget _buildStandingsList(LeagueState state, bool isDark) {
    final standings = state.standings;
    final residentId = ref.read(residentProvider).resident?.id;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= standings.length) return const SizedBox.shrink();
          final participant = standings[index];
          final rank = index + 1;
          final isCurrentUser = participant.userId == residentId;
          final isTop3 = rank <= 3;
          final isPromotionZone = rank <= LeagueService.promotionCount;
          final isDemotionZone = rank > (standings.length - LeagueService.demotionCount);

          return Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.xs),
            child: _buildStandingRow(
              participant: participant,
              rank: rank,
              isCurrentUser: isCurrentUser,
              isTop3: isTop3,
              isPromotionZone: isPromotionZone,
              isDemotionZone: isDemotionZone,
              isDark: isDark,
            ),
          );
        },
        childCount: standings.length,
      ),
    );
  }

  Widget _buildStandingRow({
    required LeagueParticipant participant,
    required int rank,
    required bool isCurrentUser,
    required bool isTop3,
    required bool isPromotionZone,
    required bool isDemotionZone,
    required bool isDark,
  }) {
    Color? rowBackground;
    if (isCurrentUser) {
      rowBackground = VColors.primary.withValues(alpha: 0.15);
    } else if (isTop3) {
      switch (rank) {
        case 1:
          rowBackground = const Color(0xFFFFD700).withValues(alpha: 0.15);
          break;
        case 2:
          rowBackground = const Color(0xFFC0C0C0).withValues(alpha: 0.15);
          break;
        case 3:
          rowBackground = const Color(0xFFCD7F32).withValues(alpha: 0.15);
          break;
      }
    }

    Color rankColor;
    if (isTop3) {
      switch (rank) {
        case 1:
          rankColor = const Color(0xFFFFD700);
          break;
        case 2:
          rankColor = const Color(0xFFC0C0C0);
          break;
        case 3:
          rankColor = const Color(0xFFCD7F32);
          break;
        default:
          rankColor = isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;
      }
    } else {
      rankColor = isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;
    }

    return Container(
      decoration: BoxDecoration(
        color: rowBackground,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: isCurrentUser
            ? Border.all(color: VColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: VFontSize.bodyMd,
                fontWeight: VFontWeight.bold,
                color: rankColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          VAvatar(
            imageUrl: participant.avatarUrl.isNotEmpty ? participant.avatarUrl : null,
            fallbackSeed: participant.name,
            size: 32,
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Text(
              participant.name,
              style: TextStyle(
                fontSize: VFontSize.bodyMd,
                fontWeight: isCurrentUser ? VFontWeight.semiBold : VFontWeight.regular,
                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Text(
            '${participant.weeklyXp} XP',
            style: TextStyle(
              fontSize: VFontSize.labelMd,
              fontWeight: VFontWeight.semiBold,
              color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
            ),
          ),
          if (isDemotionZone && !isCurrentUser) ...[
            const SizedBox(width: VSpacing.xs),
            const Icon(Icons.arrow_downward, size: 14, color: VColors.error),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool useBlur;

  const _Card({required this.child, this.padding, this.useBlur = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}
