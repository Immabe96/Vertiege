import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../forui/v_hub_page.dart';
import '../../state/challenge_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import '../../ui/icons/v_icons.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/v_feedback.dart';
import '../../models/season_cohort.dart';
import '../../services/season_cohort_service.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String? _worldId;
  String? _worldName;
  SeasonCohortSummary? _cohort;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialChallenges();
    });
  }

  Future<void> _loadInitialChallenges() async {
    var worldState = ref.read(worldProvider);
    if (worldState.worlds.isEmpty && !worldState.isLoading) {
      await ref.read(worldProvider.notifier).loadWorlds();
      worldState = ref.read(worldProvider);
    }

    final resident = ref.read(residentProvider).resident;
    final joinedWorldId = resident?.joinedWorldIds.where((id) {
      return worldState.worlds.containsKey(id);
    }).firstOrNull;

    if (!mounted) return;
    setState(() {
      _worldId = joinedWorldId;
      _worldName = joinedWorldId == null
          ? null
          : worldState.worlds[joinedWorldId]?.name;
      _initializing = false;
    });

    if (joinedWorldId != null) {
      final cohort = await SeasonCohortService.ensureMembership(joinedWorldId);
      await ref
          .read(challengeProvider.notifier)
          .loadChallengesForWorld(joinedWorldId);
      if (mounted) setState(() => _cohort = cohort);
    }
  }

  Future<void> _refresh() async {
    if (_worldId == null) {
      await _loadInitialChallenges();
      return;
    }
    final cohort = await SeasonCohortService.ensureMembership(_worldId!);
    await ref.read(challengeProvider.notifier).loadChallengesForWorld(_worldId!);
    if (mounted) setState(() => _cohort = cohort);
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(challengeProvider);
    return VHubPage(
      title: _worldName == null ? 'World Challenges' : '$_worldName Challenges',
      showBack: true,
      headerActions: [
        FHeaderAction(
          icon: const Icon(FIcons.rotateCw),
          onPress: _refresh,
        ),
      ],
      body: _initializing
          ? const ScreenLoading.list()
          : _worldId == null
          ? AppEmptyState(
              title: 'Join a world to see challenges',
              description:
                  'Challenges are scoped to worlds and seasons, not a permanent global board.',
              icon: Icons.emoji_events_outlined,
              actionLabel: 'Browse worlds',
              onAction: () => context.go('/explore'),
            )
          : challengeState.isLoading
          ? const ScreenLoading.list()
          : challengeState.loadError != null &&
                challengeState.activeChallenges.isEmpty &&
                challengeState.seasonChallenges.isEmpty
              ? AppErrorState(
                  message: challengeState.loadError!,
                  onRetry: _refresh,
                )
              : challengeState.activeChallenges.isEmpty &&
                    challengeState.seasonChallenges.isEmpty
              ? AppEmptyState(
                  title: 'No active challenges',
                  description:
                      'World and season cohort challenges appear as your realm grows.',
                  icon: Icons.emoji_events_outlined,
                  actionLabel: 'Refresh',
                  onAction: _refresh,
                )
              : ListView(
                  padding: const EdgeInsets.all(VSpacing.md),
                  children: [
                    const _ProgressionScopeNote(
                      title: 'World & season challenges',
                      body:
                          'World challenges are per-realm goals. Season cohort challenges are shared with everyone in your world\'s active season group — different from weekly Ascension Leagues.',
                    ),
                    if (_cohort != null) _CohortBanner(cohort: _cohort!),
                    if (challengeState.activeChallenges.isNotEmpty) ...[
                      const _SectionLabel(title: 'World'),
                      ...challengeState.activeChallenges.map((challenge) {
                        final progress =
                            challengeState.userProgress[challenge.id];
                        final isCompleted = challengeState.completedChallengeIds
                            .contains(challenge.id);
                        return _ChallengeCard(
                          challenge: challenge,
                          progress: progress,
                          isCompleted: isCompleted,
                        );
                      }),
                    ],
                    if (challengeState.seasonChallenges.isNotEmpty) ...[
                      const SizedBox(height: VSpacing.md),
                      const _SectionLabel(title: 'Season cohort'),
                      ...challengeState.seasonChallenges.map((challenge) {
                        final progress =
                            challengeState.userProgress[challenge.id];
                        final isCompleted = challengeState.completedChallengeIds
                            .contains(challenge.id);
                        return _ChallengeCard(
                          challenge: challenge,
                          progress: progress,
                          isCompleted: isCompleted,
                        );
                      }),
                    ],
                  ],
                ),
    );
  }
}

class _ProgressionScopeNote extends StatelessWidget {
  final String title;
  final String body;

  const _ProgressionScopeNote({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: VFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: VFontWeight.bold,
        ),
      ),
    );
  }
}

class _CohortBanner extends StatelessWidget {
  final SeasonCohortSummary cohort;

  const _CohortBanner({required this.cohort});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: VSpacing.md),
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, color: VColors.tertiary),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cohort.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
                Text(
                  '${cohort.memberCount} member${cohort.memberCount == 1 ? '' : 's'} this season'
                  '${cohort.matchBand != null ? ' · ${cohort.matchBand} band' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
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

class _ChallengeCard extends ConsumerWidget {
  final ChallengeData challenge;
  final ChallengeProgressData? progress;
  final bool isCompleted;

  const _ChallengeCard({
    required this.challenge,
    this.progress,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentValue = progress?.currentValue ?? 0;
    final targetValue = challenge.targetValue;
    final progressPercent = targetValue > 0
        ? (currentValue / targetValue).clamp(0.0, 1.0)
        : 0.0;
    final isCollective = challenge.type == 'collective';

    return Container(
      margin: const EdgeInsets.only(bottom: VSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isCompleted
              ? VColors.success.withValues(alpha: 0.3)
              : (isDark ? VColors.glassBorderDark : VColors.glassBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VSpacing.xs),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? VColors.success.withValues(alpha: 0.15)
                        : VColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.emoji_events_outlined,
                    size: VIconSize.md,
                    color: isCompleted ? VColors.success : VColors.primary,
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              challenge.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: VFontWeight.semiBold,
                              ),
                            ),
                          ),
                          if (isCollective)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: VSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: VColors.tertiary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(VRadius.pill),
                              ),
                              child: Text(
                                'World goal',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: VColors.tertiary,
                                  fontWeight: VFontWeight.semiBold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        challenge.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.pill),
              child: LinearProgressIndicator(
                value: progressPercent,
                minHeight: 8,
                backgroundColor: isDark
                    ? VColors.surfaceContainerHighDark
                    : VColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? VColors.success : VColors.primary,
                ),
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCollective
                      ? 'World progress $currentValue / $targetValue'
                      : '$currentValue / $targetValue',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: VIconSize.xs,
                      color: VColors.secondary,
                    ),
                    const SizedBox(width: VSpacing.xxs),
                    Text(
                      '+${challenge.xpReward} XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: VColors.secondary,
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (challenge.cosmeticReward != null) ...[
              const SizedBox(height: VSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.palette,
                    size: VIconSize.xs,
                    color: VColors.tertiary,
                  ),
                  const SizedBox(width: VSpacing.xxs),
                  Text(
                    'Reward: ${challenge.cosmeticReward}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.tertiary,
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                ],
              ),
            ],
            if (isCompleted) ...[
              const SizedBox(height: VSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isCompleted
                      ? () {
                          Haptics.light();
                          ref
                              .read(challengeProvider.notifier)
                              .claimReward(challenge.id);
                          VFeedback.showMessage(
                            context,
                            'Reward claimed!',
                          );
                        }
                      : null,
                  icon: const Icon(VIcons.gavel, size: VIconSize.md),
                  label: const Text('Claim Reward'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
