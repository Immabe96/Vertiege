import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import '../../state/challenge_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/screen_loading.dart';
import '../../models/season_cohort.dart';
import '../../services/season_cohort_service.dart';
import '../../widgets/progression/prestige_noir_ui.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  final bool embedInHub;

  const ChallengesScreen({super.key, this.embedInHub = false});

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
    await ref
        .read(challengeProvider.notifier)
        .loadChallengesForWorld(_worldId!);
    if (mounted) setState(() => _cohort = cohort);
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(challengeProvider);
    final body = _initializing
        ? const ScreenLoading.list()
        : _worldId == null
        ? AppEmptyState(
            title: 'Join a world to see challenges',
            description:
                'Challenges are scoped to worlds and seasons, not a permanent global board.',
            icon: Icons.emoji_events_outlined,
            actionLabel: 'Browse worlds',
            onAction: () => context.go('/worlds'),
          )
        : challengeState.isLoading
        ? const ScreenLoading.list()
        : challengeState.loadError != null &&
              challengeState.activeChallenges.isEmpty &&
              challengeState.seasonChallenges.isEmpty
        ? AppErrorState(message: challengeState.loadError!, onRetry: _refresh)
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
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: _ProgressionScopeNote(
                    title: 'World & season challenges',
                    body:
                        'World challenges are per-realm goals. Season cohort challenges are shared with everyone in your world\'s active season group — different from weekly Ascension Leagues.',
                  ),
                ),
                if (_cohort != null)
                  SliverToBoxAdapter(
                    child: _CohortBanner(cohort: _cohort!),
                  ),
                if (challengeState.activeChallenges.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: PrestigeSectionLabel(
                      'World',
                      padding: EdgeInsets.only(bottom: VSpacing.sm),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: challengeState.activeChallenges.length,
                    itemBuilder: (context, index) {
                      final challenge =
                          challengeState.activeChallenges[index];
                      final progress =
                          challengeState.userProgress[challenge.id];
                      final isCompleted =
                          challengeState.completedChallengeIds
                              .contains(challenge.id);
                      return _ChallengeCard(
                        challenge: challenge,
                        progress: progress,
                        isCompleted: isCompleted,
                      );
                    },
                  ),
                ],
                if (challengeState.seasonChallenges.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: PrestigeSectionLabel(
                      'Season cohort',
                      padding: EdgeInsets.only(
                        top: VSpacing.md,
                        bottom: VSpacing.sm,
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: challengeState.seasonChallenges.length,
                    itemBuilder: (context, index) {
                      final challenge =
                          challengeState.seasonChallenges[index];
                      final progress =
                          challengeState.userProgress[challenge.id];
                      final isCompleted =
                          challengeState.completedChallengeIds
                              .contains(challenge.id);
                      return _ChallengeCard(
                        challenge: challenge,
                        progress: progress,
                        isCompleted: isCompleted,
                      );
                    },
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: VSpacing.lg)),
              ],
            ),
          );

    if (widget.embedInHub) return body;

    return VHubPage(
      title: _worldName == null ? 'World Challenges' : '$_worldName Challenges',
      showBack: true,
      headerActions: [
        VHeaderAction(icon: const Icon(VIcons.rotateCw), onPress: _refresh),
      ],
      body: body,
    );
  }
}

class _ProgressionScopeNote extends StatelessWidget {
  final String title;
  final String body;

  const _ProgressionScopeNote({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.md, top: VSpacing.sm),
      child: VPrestigeCard(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: VFontSize.bodyMd,
                fontWeight: VFontWeight.semiBold,
                color: PrestigeNoir.foreground,
              ),
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              body,
              style: const TextStyle(
                fontSize: VFontSize.labelMd,
                color: PrestigeNoir.muted,
                height: 1.35,
              ),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.md),
      child: VPrestigeCard(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Row(
          children: [
            const Icon(Icons.groups_outlined, color: VColors.brand),
            const SizedBox(width: VSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cohort.displayName,
                    style: const TextStyle(
                      fontSize: VFontSize.bodyMd,
                      fontWeight: VFontWeight.semiBold,
                      color: PrestigeNoir.foreground,
                    ),
                  ),
                  Text(
                    '${cohort.memberCount} member${cohort.memberCount == 1 ? '' : 's'} this season'
                    '${cohort.matchBand != null ? ' · ${cohort.matchBand} band' : ''}',
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
    final currentValue = progress?.currentValue ?? 0;
    final targetValue = challenge.targetValue;
    final progressPercent = targetValue > 0
        ? (currentValue / targetValue).clamp(0.0, 1.0)
        : 0.0;
    final isCollective = challenge.type == 'collective';
    final fillColor = isCompleted
        ? VColors.success
        : progressPercent > 0.5
        ? VColors.brand
        : VColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.sm),
      child: VPrestigeCard(
        padding: const EdgeInsets.all(VSpacing.lg),
        borderColor: isCompleted
            ? VColors.success.withValues(alpha: 0.5)
            : PrestigeNoir.borderLight,
        backgroundColor: isCompleted
            ? Color.alphaBlend(
                VColors.success.withValues(alpha: 0.06),
                PrestigeNoir.surfaceRaised,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 40,
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.emoji_events_outlined,
                    size: 28,
                    color: isCompleted ? VColors.success : VColors.brand,
                  ),
                ),
                const SizedBox(width: VSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              challenge.title,
                              style: const TextStyle(
                                fontSize: VFontSize.bodyLg,
                                fontWeight: VFontWeight.bold,
                                color: PrestigeNoir.foreground,
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
                                color: VColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(VRadius.pill),
                              ),
                              child: const Text(
                                'World goal',
                                style: TextStyle(
                                  fontSize: VFontSize.labelSm,
                                  color: VColors.warning,
                                  fontWeight: VFontWeight.semiBold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        challenge.description,
                        style: const TextStyle(
                          fontSize: VFontSize.labelMd,
                          color: PrestigeNoir.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: VSpacing.sm),
                      Row(
                        children: [
                          Text(
                            '+${challenge.xpReward} XP',
                            style: const TextStyle(
                              fontSize: VFontSize.bodyMd,
                              fontWeight: VFontWeight.bold,
                              color: VColors.brand,
                            ),
                          ),
                          const SizedBox(width: VSpacing.sm),
                          Expanded(
                            child: PrestigeXpBar(
                              value: progressPercent,
                              fillColor: fillColor,
                            ),
                          ),
                          const SizedBox(width: VSpacing.sm),
                          Text(
                            isCollective
                                ? '$currentValue / $targetValue'
                                : '$currentValue/$targetValue',
                            style: const TextStyle(
                              fontSize: VFontSize.labelSm,
                              color: PrestigeNoir.muted,
                            ),
                          ),
                        ],
                      ),
                      if (challenge.cosmeticReward != null) ...[
                        const SizedBox(height: VSpacing.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.palette,
                              size: VIconSize.xs,
                              color: VColors.warning,
                            ),
                            const SizedBox(width: VSpacing.xxs),
                            Text(
                              'Reward: ${challenge.cosmeticReward}',
                              style: const TextStyle(
                                fontSize: VFontSize.labelSm,
                                color: VColors.warning,
                                fontWeight: VFontWeight.semiBold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isCompleted) ...[
              const SizedBox(height: VSpacing.md),
              SizedBox(
                width: double.infinity,
                child: VButton(
                  label: 'Claim reward',
                  onPressed: () {
                    Haptics.light();
                    ref
                        .read(challengeProvider.notifier)
                        .claimReward(challenge.id);
                    VFeedback.showMessage(context, 'Reward claimed!');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
