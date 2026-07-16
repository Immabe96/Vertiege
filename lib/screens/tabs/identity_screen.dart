import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../services/subscription_service.dart';
import '../../services/world_service.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../state/achievement_provider.dart';
import '../../state/post_provider.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import '../../widgets/profile/cosmetic_avatar.dart';
import '../../widgets/profile/luminary_nameplate.dart';
import '../../widgets/profile/edit_profile_sheet.dart';
import '../../widgets/shared/progress_bar.dart';
import '../../widgets/profile/completion_hint.dart';
import '../../widgets/profile/subscription_badge.dart';
import '../../utils/presence_utils.dart';
import '../../widgets/core/status_dot.dart';
import '../../services/resident_status_service.dart';
import '../../widgets/profile/status_picker.dart';
import '../../utils/profile_share.dart';
import '../../router/world_navigation.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/sync_warning_banner.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/core/tier_up_dialog.dart';
import '../../widgets/shared/profession_icon.dart';
import '../../widgets/shared/tier_icon.dart';
import '../../widgets/identity/joined_worlds_row.dart';
import '../../widgets/identity/allies_preview_row.dart';
import '../../config/onboarding_funnel.dart';
import '../../services/onboarding_funnel_prefs.dart';
import '../../services/onboarding_funnel_sync.dart';
import '../../config/identity_verification.dart';
import '../../widgets/identity/identity_verification_card.dart';
import '../../widgets/identity/streak_stats_row.dart';
import '../../widgets/onboarding/first_steps_card.dart';
import '../../widgets/profile/achievement_trophy_wall.dart';
import '../../config/progression_access.dart';
import '../../config/progression_glossary.dart';
import '../../config/achievements.dart';
import '../../widgets/core/progression_help_button.dart';

/// Refreshes honour-wall data (resident, achievements, posts).
///
/// [onAfterLoad] runs after provider reloads (e.g. high-prestige worlds).
Future<void> refreshHonourWallData(
  WidgetRef ref,
  BuildContext context, {
  Future<void> Function()? onAfterLoad,
}) async {
  Haptics.light();
  try {
    await ref.read(residentProvider.notifier).loadResident();
    await ref.read(achievementProvider.notifier).loadAchievements();
    await ref.read(postProvider.notifier).loadPosts();
    await onAfterLoad?.call();
    if (!context.mounted) return;
    VFeedback.showMessage(context, 'Honour wall refreshed');
  } catch (_) {
    if (!context.mounted) return;
    VFeedback.showMessage(context, 'Refresh failed');
  }
}

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key, this.embedded = false});

  /// When true, omit [VHubPage] chrome — parent (e.g. [YouScreen]) owns the header.
  final bool embedded;

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen> {
  final _scrollController = ScrollController();
  bool _handledRouteTab = false;
  int _previousXp = 0;
  SubscriptionTier _subscriptionTier = SubscriptionTier.resident;
  List<Map<String, dynamic>> _highPrestigeWorlds = [];
  bool _funnelDismissed = true;
  bool _funnelOpenedWorld = false;
  bool _funnelOpenedNexus = false;
  bool _tierPerksExpanded = false;
  bool _progressionExpanded = true;
  static const double _avatarRadius = 48;

  Widget _wrapShell({
    required Widget body,
    List<Widget> headerActions = const [],
  }) {
    if (widget.embedded) return body;
    return VHubPage(
      title: 'Wall of Honour',
      headerActions: headerActions,
      body: body,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSubscriptionTier();
    _loadHighPrestigeWorlds();
    _loadFunnelPrefs();
  }

  Future<void> _loadFunnelPrefs() async {
    final dismissed = await OnboardingFunnelPrefs.isDismissed();
    final openedWorld = await OnboardingFunnelPrefs.hasOpenedWorld();
    final openedNexus = await OnboardingFunnelPrefs.hasOpenedNexus();
    if (!mounted) return;
    setState(() {
      _funnelDismissed = dismissed;
      _funnelOpenedWorld = openedWorld;
      _funnelOpenedNexus = openedNexus;
    });
  }

  Future<void> _loadSubscriptionTier() async {
    try {
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        final tier = await SubscriptionService.getTier(resident.id);
        if (mounted) {
          setState(() => _subscriptionTier = tier);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadHighPrestigeWorlds() async {
    try {
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        final worlds = await WorldService.getHighPrestigeWorlds(resident.id);
        if (mounted) {
          setState(() => _highPrestigeWorlds = worlds);
        }
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledRouteTab) return;
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tab == 'allies') {
      _handledRouteTab = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/allies');
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showEditProfileSheet(Resident resident) {
    showEditProfileSheet(
      context,
      resident,
      onSave: ({name, bio, avatarPath, profession}) {
        ref
            .read(residentProvider.notifier)
            .updateProfile(
              name: name,
              bio: bio,
              avatarPath: avatarPath,
              profession: profession,
            );
      },
    );
  }

  Future<void> _editStatus(Resident resident) async {
    final current = ResidentStatus(
      presence: ResidentStatusService.presenceFromStorage(
        resident.presenceMode,
      ),
      customStatus: resident.customStatus,
    );
    final updated = await showStatusPicker(context, current: current);
    if (updated == null || !mounted) return;
    await ResidentStatusService.upsertStatus(updated);
    await ref
        .read(residentProvider.notifier)
        .updateResidentStatus(
          presenceMode: ResidentStatusService.presenceModeStorage(
            updated.presence,
          ),
          customStatus: updated.customStatus,
        );
  }

  Widget _buildYouProfileCard(
    BuildContext context,
    Resident resident,
    int currentXp,
    int tierValue,
  ) {
    final presence = presenceFromStatusFields(
      presenceMode: resident.presenceMode,
      lastSeenRaw: resident.lastSeenAt,
    );
    final statusLabel = switch (presence) {
      Presence.online => 'Online',
      Presence.idle => 'Away',
      Presence.dnd => 'Do not disturb',
      Presence.offline => 'Offline',
    };
    final statusText = resident.customStatus?.trim().isNotEmpty == true
        ? resident.customStatus!.trim()
        : statusLabel;

    return Material(
      color: PrestigeNoir.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.bento),
        side: const BorderSide(color: PrestigeNoir.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEditProfileSheet(resident),
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CosmeticAvatar(
                    totalXp: currentXp,
                    size: 56,
                    imageUrl: resident.avatarUrl,
                    seed: resident.id,
                  ),
                  const SizedBox(width: VSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: LuminaryNameplate(
                                name: resident.name,
                                tier: tierValue,
                                title: resident.title,
                              ),
                            ),
                            if (IdentityVerification.isVerified(resident)) ...[
                              const SizedBox(width: VSpacing.xs),
                              const Tooltip(
                                message: 'Verified resident',
                                child: Icon(
                                  VIcons.badgeCheck,
                                  size: VIconSize.md,
                                  color: VColors.brand,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: VSpacing.xxs),
                        Text(
                          resident.tier.label,
                          style: const TextStyle(
                            fontSize: VFontSize.labelSm,
                            color: PrestigeNoir.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_outlined,
                    size: VIconSize.md,
                    color: PrestigeNoir.muted,
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _editStatus(resident),
                      borderRadius: BorderRadius.circular(VRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: VSpacing.xxs,
                        ),
                        child: Row(
                          children: [
                            StatusDot(presence: presence, size: 8),
                            const SizedBox(width: VSpacing.xs),
                            Expanded(
                              child: Text(
                                statusText,
                                style: const TextStyle(
                                  fontSize: VFontSize.labelSm,
                                  color: PrestigeNoir.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  InkWell(
                    onTap: () => context.push('/shop'),
                    borderRadius: BorderRadius.circular(VRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.xs,
                        vertical: VSpacing.xxs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            VIcons.coins,
                            size: VIconSize.sm,
                            color: VColors.brand,
                          ),
                          const SizedBox(width: VSpacing.xxs),
                          Text(
                            '${resident.sovereignCoins}',
                            style: const TextStyle(
                              fontSize: VFontSize.labelSm,
                              color: VColors.brand,
                              fontWeight: VFontWeight.semiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _topPercentLabel(int tier) {
    switch (tier) {
      case 5:
        return 'Top 1% of Residents';
      case 4:
        return 'Top 5% of Residents';
      case 3:
        return 'Top 15% of Residents';
      case 2:
        return 'Top 35% of Residents';
      default:
        return '';
    }
  }

  List<String> _buildPerksList(int tier, WidgetRef ref) {
    final notifier = ref.read(residentProvider.notifier);
    final perks = <String>[];
    final multiplier = notifier.xpMultiplier;
    final coinBonus = notifier.dailyCoinBonus;
    final reactionSlots = notifier.customReactionSlots;
    final pinLimit = notifier.postPinLimit;
    final worldLimit = notifier.worldCreationLimit;

    if (multiplier > 1.0) perks.add('${multiplier}x XP multiplier');
    if (coinBonus > 0) perks.add('+$coinBonus daily coins');
    if (reactionSlots > 0) perks.add('$reactionSlots custom reaction slots');
    if (pinLimit > 0) perks.add('$pinLimit post pin limit');
    if (worldLimit > 1) perks.add('$worldLimit world creation limit');
    if (tier >= 3) perks.add('Lounge access');
    if (tier >= 4) perks.add('Governance vote');
    if (perks.isEmpty) perks.add('Exclusive tier badge');
    return perks;
  }

  @override
  Widget build(BuildContext context) {
    final residentState = ref.watch(residentProvider);
    final resident = residentState.resident;
    final achievements = ref.watch(achievementProvider);
    if (!_funnelOpenedWorld || !_funnelOpenedNexus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadFunnelPrefs();
      });
    }
    final theme = Theme.of(context);
    ref.listen<ResidentState>(residentProvider, (prev, next) {
      if (prev?.resident != null &&
          next.resident != null &&
          next.resident!.tier.value > prev!.resident!.tier.value) {
        final oldTier = prev.resident!.tier.value;
        final newTier = next.resident!.tier.value;
        final perks = _buildPerksList(newTier, ref);
        TierUpDialog.show(
          context,
          oldTier: oldTier,
          newTier: newTier,
          perks: perks,
        );
      }
    });

    if (residentState.isLoading) {
      return _wrapShell(body: const ScreenLoading.profile());
    }

    if (resident == null) {
      return _wrapShell(
        body: AppErrorState(
          message: residentState.loadError ?? 'Could not load your profile.',
          onRetry: () => ref.read(residentProvider.notifier).loadResident(),
        ),
      );
    }

    final currentXp = resident.totalXp;
    if (currentXp != _previousXp && _previousXp != 0) {
      Haptics.light();
    }
    _previousXp = currentXp;

    final tierValue = resident.tier.value;
    final nextTierValue = tierValue + 1;
    final currentThreshold = xpThresholds[tierValue] ?? 0;
    final nextThreshold = xpThresholds[nextTierValue];
    final tierProgress = nextThreshold != null
        ? ((currentXp - currentThreshold) / (nextThreshold - currentThreshold))
              .clamp(0.0, 1.0)
        : 1.0;

    final tierNames = {
      1: 'Hustler',
      2: 'High Roller',
      3: 'Elite',
      4: 'Old Money',
      5: 'Apex',
    };
    final nextTierName = tierNames[nextTierValue] ?? 'Max';

    Future<void> refreshHonourWall() => refreshHonourWallData(
      ref,
      context,
      onAfterLoad: _loadHighPrestigeWorlds,
    );

    final headerActions = [
      VAccessibleHeaderAction(
        label: 'Preview public profile',
        icon: const Icon(VIcons.user),
        onPress: () => context.push(residentProfilePath(resident.id)),
      ),
      VAccessibleHeaderAction(
        label: 'Settings',
        icon: const Icon(VIcons.settings),
        onPress: () => context.push('/settings'),
      ),
    ];

    return _wrapShell(
      headerActions: headerActions,
      body: RefreshIndicator(
        onRefresh: refreshHonourWall,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: VSpacing.xxl),
          children: [
            if (residentState.loadError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.md,
                  VSpacing.sm,
                  VSpacing.md,
                  0,
                ),
                child: SyncWarningBanner(
                  message: residentState.loadError!,
                  onRetry: () =>
                      ref.read(residentProvider.notifier).loadResident(),
                ),
              ),
            if (achievements.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.md,
                  VSpacing.sm,
                  VSpacing.md,
                  0,
                ),
                child: SyncWarningBanner(
                  message: achievements.error!,
                  onRetry: () =>
                      ref.read(achievementProvider.notifier).loadAchievements(),
                ),
              ),
            if (widget.embedded) const IdentityVerificationCard(),
            // ── Hero / You profile card ───────────────────
            if (widget.embedded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.md,
                  VSpacing.md,
                  VSpacing.md,
                  0,
                ),
                child: _buildYouProfileCard(
                  context,
                  resident,
                  currentXp,
                  tierValue,
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
                child: StreakStatsRow(
                  streakCount: resident.streakCount,
                  streakShields: resident.streakShields,
                ),
              ),
              const SizedBox(height: VSpacing.md),
            ] else
              Container(
                padding: const EdgeInsets.all(VSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar with tier-colored glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'avatar-${resident.id}',
                        child: CosmeticAvatar(
                          totalXp: currentXp,
                          size: _avatarRadius * 2,
                          imageUrl: resident.avatarUrl,
                          seed: resident.id,
                        ),
                      ),
                    ),
                    const SizedBox(height: VSpacing.md),

                    // Name with tier badge
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LuminaryNameplate(
                                  name: resident.name,
                                  tier: resident.tier.value,
                                  fontSize: VFontSize.headlineMd,
                                  textAlign: TextAlign.center,
                                  title: resident.title,
                                ),
                                const SizedBox(width: VSpacing.sm),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: ProgressionAccess.canAccessAscension(
                                          tierValue,
                                        )
                                        ? () =>
                                            context.push('/ascension-path')
                                        : null,
                                    borderRadius: BorderRadius.circular(
                                      VRadius.pill,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: VSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          VRadius.pill,
                                        ),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TierIcon(tier: tierValue, size: 18),
                                          const SizedBox(width: VSpacing.xxs),
                                          Text(
                                            resident.tier.label,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  fontWeight: VFontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(width: VSpacing.xxs),
                                          Icon(
                                            Icons.chevron_right,
                                            size: VIconSize.denseSm,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Top X% indicator
                    if (tierValue >= 2)
                      Padding(
                        padding: const EdgeInsets.only(top: VSpacing.xs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: VColors.tertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(VRadius.pill),
                            border: Border.all(
                              color: VColors.tertiary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                size: VIconSize.xs,
                                color: VColors.tertiary,
                              ),
                              const SizedBox(width: VSpacing.xxs),
                              Text(
                                _topPercentLabel(tierValue),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: VColors.tertiary,
                                  fontWeight: VFontWeight.semiBold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Subscription badge
                    if (_subscriptionTier != SubscriptionTier.resident)
                      Padding(
                        padding: const EdgeInsets.only(top: VSpacing.xs),
                        child: SubscriptionBadge(tier: _subscriptionTier),
                      ),

                    // Bio
                    if (resident.bio.isNotEmpty) ...[
                      const SizedBox(height: VSpacing.md),
                      Text(
                        resident.bio,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    // Profession
                    if (resident.profession != null &&
                        resident.profession!.isNotEmpty) ...[
                      const SizedBox(height: VSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(VRadius.pill),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ProfessionIcon(
                              profession: resident.profession,
                              size: VBadgeSize.professionInline,
                              fallbackColor: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: VSpacing.xxs),
                            Text(
                              resident.profession!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            if (!widget.embedded &&
                !_funnelDismissed &&
                !OnboardingFunnel.isComplete(
                  resident: resident,
                  achievements: achievements.userAchievements,
                  openedWorld: _funnelOpenedWorld,
                  openedNexus: _funnelOpenedNexus,
                )) ...[
              FirstStepsCard(
                resident: resident,
                userAchievements: achievements.userAchievements,
                openedWorld: _funnelOpenedWorld,
                openedNexus: _funnelOpenedNexus,
                onDismiss: () async {
                  final uid = resident.id;
                  await OnboardingFunnelSync.setDismissed(uid, true);
                  if (mounted) setState(() => _funnelDismissed = true);
                },
              ),
              const SizedBox(height: VSpacing.md),
            ],

            _SectionHeader(title: 'My worlds', theme: theme),
            const SizedBox(height: VSpacing.sm),
            JoinedWorldsRow(
              worlds: resident.joinedWorldIds
                  .map((id) => ref.watch(worldProvider).worlds[id])
                  .whereType<World>()
                  .toList(),
            ),
            const SizedBox(height: VSpacing.lg),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Trophy wall', theme: theme),
                  const SizedBox(height: VSpacing.sm),
                  AchievementTrophyWall(
                    achievements: achievements.userAchievements,
                    maxVisible: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.md),
            const AlliesPreviewRow(),
            const SizedBox(height: VSpacing.lg),

            InkWell(
              onTap: () =>
                  setState(() => _progressionExpanded = !_progressionExpanded),
              child: _SectionHeader(
                title: 'Your tier & XP',
                theme: theme,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ProgressionHelpButton(
                      focus: ProgressionFocus.xpAndTier,
                    ),
                    Icon(
                      _progressionExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_progressionExpanded) ...[
              const SizedBox(height: VSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(VSpacing.md),
                  decoration: BoxDecoration(
                    color: VColors.surfaceContainerDark,
                    borderRadius: BorderRadius.circular(VRadius.lg),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          TierIcon(tier: tierValue),
                          const SizedBox(width: VSpacing.sm),
                          Text(
                            resident.tier.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: VFontWeight.semiBold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VSpacing.sm),
                      SovereignProgressBar(
                        progress: tierProgress,
                        color: VColors.brand,
                        label: resident.tier.label,
                        trailing: nextThreshold != null ? nextTierName : 'Max',
                      ),
                      const SizedBox(height: VSpacing.xs),
                      Text(
                        ProgressionGlossary.xpToNextTier(currentXp, tierValue),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(
                          () => _tierPerksExpanded = !_tierPerksExpanded,
                        ),
                        borderRadius: BorderRadius.circular(VRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: VSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Tier perks',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: VFontWeight.semiBold,
                                  ),
                                ),
                              ),
                              Icon(
                                _tierPerksExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_tierPerksExpanded)
                        _PerksCard(
                          tier: tierValue,
                          showHeader: false,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VSpacing.xl),
            ],

            // ── Action Buttons ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Edit Profile',
                      icon: const Icon(VIcons.edit, size: VIconSize.md),
                      isFullWidth: true,
                      onPressed: () => _showEditProfileSheet(resident),
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: VButton(
                      label: 'Share',
                      icon: const Icon(
                        Icons.share_outlined,
                        size: VIconSize.md,
                      ),
                      variant: ButtonVariant.outlined,
                      isFullWidth: true,
                      onPressed: () {
                        final referralCode = resident.referralCode.isNotEmpty
                            ? resident.referralCode
                            : resident.id
                                  .substring(
                                    0,
                                    resident.id.length < 8
                                        ? resident.id.length
                                        : 8,
                                  )
                                  .toUpperCase();
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                '${ProfileShare.shareMessage(name: resident.name, residentId: resident.id)}\n\n'
                                'Or use referral code: $referralCode',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.xl),

            // ── World Prestige Bonus ───────────────────────
            if (_highPrestigeWorlds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(VSpacing.md),
                  decoration: BoxDecoration(
                    color: VColors.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(VRadius.lg),
                    border: Border.all(
                      color: VColors.tertiary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: VIconSize.md,
                            color: VColors.tertiary,
                          ),
                          const SizedBox(width: VSpacing.xs),
                          Text(
                            'World Prestige Bonus',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: VFontWeight.semiBold,
                              color: VColors.tertiary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '+${(_highPrestigeWorlds.length * 5)}%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: VFontWeight.bold,
                              color: VColors.tertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VSpacing.sm),
                      ..._highPrestigeWorlds.map((world) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: VSpacing.xs),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                world['name'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Prestige ${world['prestige']}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: VColors.tertiary,
                                  fontWeight: VFontWeight.semiBold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            if (_highPrestigeWorlds.isNotEmpty)
              const SizedBox(height: VSpacing.lg),

            // ── Completion hints ────────────────────────────
            if (resident.bio.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
                child: CompletionHint(
                  icon: Icons.auto_awesome,
                  title: 'Add a bio',
                  subtitle: 'Tell residents who you are and what you do.',
                  color: VColors.warning,
                  onTap: () => _showEditProfileSheet(resident),
                ),
              ),
            if (resident.profession == null || resident.profession!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
                child: CompletionHint(
                  icon: Icons.work_outline,
                  title: 'Pick a profession',
                  subtitle: 'Unlock profession-specific worlds and badges.',
                  color: VColors.primary,
                  onTap: () => _showEditProfileSheet(resident),
                ),
              ),
            if (resident.bio.isEmpty ||
                resident.profession == null ||
                resident.profession!.isEmpty)
              const SizedBox(height: VSpacing.sm),

            const SizedBox(height: VSpacing.lg),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
              child: VSectionList(
                title: 'More',
                children: [
                  VSectionTile(
                    icon: Icons.insights_outlined,
                    label: 'Progress',
                    detail: 'XP, streak & quests',
                    onTap: () => context.push('/progress'),
                  ),
                  VSectionTile(
                    icon: Icons.handshake_outlined,
                    label: 'Connections',
                    detail: 'Allies & following',
                    onTap: () => context.push('/allies'),
                  ),
                  VSectionTile(
                    icon: Icons.settings_outlined,
                    label: 'Account',
                    detail: 'Settings & shop',
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: VSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.theme,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.md,
        VSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: VFontWeight.bold,
                letterSpacing: 0.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _PerksCard extends ConsumerWidget {
  final int tier;
  final bool showHeader;

  const _PerksCard({
    required this.tier,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(residentProvider.notifier);
    final multiplier = notifier.xpMultiplier;
    final coinBonus = notifier.dailyCoinBonus;
    final reactionSlots = notifier.customReactionSlots;
    final pinLimit = notifier.postPinLimit;
    final worldLimit = notifier.worldCreationLimit;
    final hasLounge = tier >= 3;
    final hasVote = tier >= 4;

    Widget tile(IconData icon, String title, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: VIconSize.sm, color: VColors.tertiary),
            const SizedBox(width: VSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: VFontWeight.semiBold,
              ),
            ),
          ],
        ),
      );
    }

    Widget divider() {
      return Divider(
        height: 1,
        indent: VSpacing.lg + VSpacing.sm,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
    }

    final perksTiles = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile(
          Icons.trending_up,
          'XP Multiplier',
          'x${multiplier.toStringAsFixed(2)}',
        ),
        divider(),
        tile(Icons.monetization_on, 'Daily Coin Bonus', '+$coinBonus'),
        divider(),
        tile(Icons.emoji_emotions, 'Custom Reactions', '$reactionSlots slots'),
        divider(),
        tile(
          Icons.push_pin,
          'Post Pins',
          pinLimit > 0 ? '$pinLimit available' : 'Locked',
        ),
        divider(),
        tile(Icons.language, 'World Creation', '$worldLimit worlds'),
        divider(),
        tile(
          Icons.local_bar,
          'Lounge Access',
          hasLounge ? 'Unlocked' : 'Locked',
        ),
        divider(),
        tile(
          Icons.how_to_vote,
          'Governance Vote',
          hasVote ? 'Unlocked' : 'Locked',
        ),
      ],
    );

    if (!showHeader) {
      return perksTiles;
    }

    final perksBody = Container(
      decoration: BoxDecoration(
        color: VColors.surfaceContainerDark,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: perksTiles,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.md,
              VSpacing.md,
              VSpacing.md,
              VSpacing.sm,
            ),
            child: Text(
              'TIER PERKS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: VFontWeight.bold,
                letterSpacing: 0.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          perksBody,
        ],
      ),
    );
  }
}
