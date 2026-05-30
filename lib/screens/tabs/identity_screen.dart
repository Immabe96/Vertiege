import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../forui/v_hub_page.dart';
import '../../widgets/v_section_list.dart';
import '../../widgets/identity/honour_stat_chip.dart';
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../services/world_service.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../state/achievement_provider.dart';
import '../../state/post_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import '../../widgets/profile/cosmetic_avatar.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/icons/v_icons.dart';
import '../../widgets/profile/luminary_nameplate.dart';
import '../../widgets/profile/badge_display.dart';
import '../../widgets/profile/edit_profile_sheet.dart';
import '../../state/ally_provider.dart';
import '../../widgets/shared/progress_bar.dart';
import '../../widgets/profile/streak_display.dart';
import '../../widgets/profile/completion_hint.dart';
import '../../widgets/profile/subscription_badge.dart';
import '../../widgets/achievements/achievement_queue_summary.dart';
import '../../widgets/profile/trophy_case.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/sync_warning_banner.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/core/tier_up_dialog.dart';
import '../../widgets/shared/profession_icon.dart';
import '../../widgets/shared/tier_icon.dart';
import '../../widgets/identity/joined_worlds_row.dart';
import '../../config/onboarding_funnel.dart';
import '../../services/onboarding_funnel_prefs.dart';
import '../../widgets/onboarding/first_steps_card.dart';
import '../../config/achievements.dart';
import '../../config/progression_glossary.dart';
import '../../widgets/core/progression_help_button.dart';
import '../../config/cosmetics.dart';
import '../../widgets/core/v_feedback.dart';

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen> {
  final _scrollController = ScrollController();
  final _exploreSectionKey = GlobalKey();
  bool _handledRouteTab = false;
  int _previousXp = 0;
  SubscriptionTier _subscriptionTier = SubscriptionTier.resident;
  List<Map<String, dynamic>> _highPrestigeWorlds = [];
  bool _funnelDismissed = true;
  bool _funnelOpenedWorld = false;
  bool _funnelOpenedNexus = false;
  bool _tierPerksExpanded = false;

  static const double _avatarRadius = 48;

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

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.xl),
        ),
        title: const Text('Sign out?'),
        content: const Text(
          'You\'ll need to sign in again to access your worlds and progress.',
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Sign Out',
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.signOut(ref: ref);
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
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
    final isDark = theme.brightness == Brightness.dark;
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
      return const VHubPage(
        title: 'Wall of Honour',
        body: ScreenLoading.profile(),
      );
    }

    if (resident == null) {
      return VHubPage(
        title: 'Wall of Honour',
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

    final verifiedAchievementCount = achievements.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .length;
    final allyCount = ref.watch(allyProvider).allies.length;

    final totalRep = resident.worldStandings.values.fold<int>(
      0,
      (sum, ws) => sum + ws.rep,
    );

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

    Future<void> refreshHonourWall() async {
      Haptics.light();
      try {
        await ref.read(residentProvider.notifier).loadResident();
        await ref.read(achievementProvider.notifier).loadAchievements();
        await ref.read(postProvider.notifier).loadPosts();
        await _loadHighPrestigeWorlds();
        if (!mounted) return;
        VFeedback.showMessage(context, 'Honour wall refreshed');
      } catch (_) {
        if (!mounted) return;
        VFeedback.showMessage(context, 'Refresh failed');
      }
    }

    return VHubPage(
      title: 'Wall of Honour',
      headerActions: [
        VAccessibleHeaderAction(
          label: 'Refresh honour wall',
          icon: const Icon(FIcons.rotateCw),
          onPress: refreshHonourWall,
        ),
        VAccessibleHeaderAction(
          label: 'Settings',
          icon: const Icon(FIcons.settings),
          onPress: () => context.push('/settings'),
        ),
      ],
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
                onRetry: () => ref
                    .read(achievementProvider.notifier)
                    .loadAchievements(),
              ),
            ),
          // ── Hero Section ──────────────────────────────
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
                        color: VColors.primary.withValues(alpha: 0.2),
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
                Row(
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
                        onTap: () => context.push('/ascension-path'),
                        borderRadius: BorderRadius.circular(VRadius.pill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: VColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(VRadius.pill),
                            border: Border.all(
                              color: VColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TierIcon(tier: tierValue, size: 18),
                              const SizedBox(width: VSpacing.xxs),
                              Text(
                                resident.tier.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: VColors.primary,
                                  fontWeight: VFontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: VColors.primary.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                          Icon(
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
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
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
                        color: isDark
                            ? VColors.outlineVariantDark.withValues(alpha: 0.4)
                            : VColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ProfessionIcon(
                          profession: resident.profession,
                          size: VBadgeSize.professionInline,
                          fallbackColor: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: VSpacing.xxs),
                        Text(
                          resident.profession!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (!_funnelDismissed &&
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
                await OnboardingFunnelPrefs.setDismissed(true);
                if (mounted) setState(() => _funnelDismissed = true);
              },
            ),
            const SizedBox(height: VSpacing.md),
          ],

          _SectionHeader(
            title: 'Honours & rep',
            theme: theme,
            trailing: const ProgressionHelpButton(
              focus: ProgressionFocus.repAndStanding,
            ),
          ),
          const SizedBox(height: VSpacing.sm),

          // ── Honour stats (achievements · worlds · rep) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: HonourStatChip(
                    icon: Icons.emoji_events,
                    value: '$verifiedAchievementCount',
                    label: 'Verified',
                    accent: VColors.tertiary,
                    onTap: () => context.push('/achievements'),
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: HonourStatChip(
                    icon: Icons.public,
                    value: '${resident.joinedWorldIds.length}',
                    label: 'Worlds',
                    accent: VColors.primary,
                    onTap: () => context.push('/explore'),
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: HonourStatChip(
                    icon: Icons.military_tech,
                    value: '$totalRep',
                    label: 'World rep',
                    accent: VColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.lg),

          _SectionHeader(title: 'My worlds', theme: theme),
          const SizedBox(height: VSpacing.sm),
          JoinedWorldsRow(
            worlds: resident.joinedWorldIds
                .map((id) => ref.watch(worldProvider).worlds[id])
                .whereType<World>()
                .toList(),
          ),
          const SizedBox(height: VSpacing.lg),

          _SectionHeader(title: 'Today', theme: theme),
          const SizedBox(height: VSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: resident.streakCount > 0
                ? StreakDisplay(
                    streakCount: resident.streakCount,
                    streakShields: resident.streakShields,
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_outlined,
                        size: VIconSize.md,
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: VSpacing.sm),
                      Expanded(
                        child: Text(
                          'No active streak—start from daily quests.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/daily-quests'),
                        child: const Text('Quests'),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: VSpacing.lg),

          _SectionHeader(title: 'Honours', theme: theme),
          const SizedBox(height: VSpacing.sm),

          AchievementQueueSummary(
            userAchievements: achievements.userAchievements,
          ),

          TrophyCase(
            resident: resident,
            achievements: achievements.userAchievements,
            totalXp: currentXp,
          ),
          const SizedBox(height: VSpacing.lg),

          if (professionBadgeIdsFor(resident.verifiedRoles).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.lg,
                0,
                VSpacing.lg,
                VSpacing.sm,
              ),
              child: Text(
                'BADGES',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: VFontWeight.bold,
                  letterSpacing: 0.5,
                  color: VColors.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
              child: BadgeDisplay(
                earnedBadgeIds: professionBadgeIdsFor(resident.verifiedRoles),
              ),
            ),
            const SizedBox(height: VSpacing.lg),
          ],

          _SectionHeader(
            title: 'Your tier & XP',
            theme: theme,
            trailing: const ProgressionHelpButton(
              focus: ProgressionFocus.xpAndTier,
            ),
          ),
          const SizedBox(height: VSpacing.sm),

          // ── Progress (tier bar + XP + collapsible perks) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(VSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? VColors.surfaceContainerDark
                    : VColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(VRadius.lg),
                border: Border.all(
                  color: isDark
                      ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                      : VColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      TierIcon(tier: tierValue, size: 28),
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
                    color: VColors.primary,
                    label: resident.tier.label,
                    trailing: nextThreshold != null ? nextTierName : 'Max',
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    ProgressionGlossary.xpToNextTier(currentXp, tierValue),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        setState(() => _tierPerksExpanded = !_tierPerksExpanded),
                    borderRadius: BorderRadius.circular(VRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
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
                            color: isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_tierPerksExpanded)
                    _PerksCard(
                      tier: tierValue,
                      isDark: isDark,
                      showHeader: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpacing.xl),

          // ── Action Buttons ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showEditProfileSheet(resident),
                    icon: const Icon(VIcons.edit, size: VIconSize.md),
                    label: const Text('Edit Profile'),
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
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
                              'Join me on Vertiege! 🌟\n\n${resident.name} is inviting you.\n\nDownload Vertiege and use referral code: $referralCode',
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_outlined, size: VIconSize.md),
                    label: const Text('Share'),
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
                        Icon(
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
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
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
                subtitle: 'Tell people who you are and what you do.',
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
            key: _exploreSectionKey,
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: VSectionList(
              title: 'Social',
              children: [
                VSectionTile(
                  icon: Icons.people,
                  label: 'Following (${resident.following.length})',
                  onTap: () => context.push('/following'),
                ),
                VSectionTile(
                  icon: Icons.handshake,
                  label: allyCount == 0
                      ? 'Find allies'
                      : 'Allies ($allyCount)',
                  onTap: () => context.push('/allies'),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: VSectionList(
              title: 'Explore',
              children: [
                VSectionTile(
                  icon: Icons.explore,
                  label: 'Daily quests',
                  onTap: () => context.push('/daily-quests'),
                ),
                VSectionTile(
                  icon: Icons.leaderboard,
                  label: 'Hall of Ascension',
                  onTap: () => context.push('/hall-of-ascension'),
                ),
                VSectionTile(
                  icon: Icons.leaderboard_outlined,
                  label: 'Weekly league',
                  onTap: () => context.push('/leagues'),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: VSectionList(
              title: 'Vault',
              children: [
                VSectionTile(
                  icon: Icons.monetization_on,
                  label: 'Sovereign Regalia · ${resident.sovereignCoins} coins',
                  iconColor: VColors.tertiary,
                  onTap: () => context.push('/shop'),
                ),
                VSectionTile(
                  icon: Icons.workspace_premium,
                  label: 'Subscription',
                  onTap: () => context.push('/subscription'),
                ),
              ],
            ),
          ),

          const SizedBox(height: VSpacing.sm),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: VSectionList(
              title: 'Account',
              children: [
                VSectionTile(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  iconColor: VColors.error,
                  onTap: _confirmSignOut,
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
      padding: const EdgeInsets.fromLTRB(VSpacing.lg, VSpacing.md, VSpacing.lg, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: VFontWeight.bold,
                letterSpacing: 0.5,
                color: VColors.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _PerksCard extends ConsumerWidget {
  final int tier;
  final bool isDark;
  final bool showHeader;

  const _PerksCard({
    required this.tier,
    required this.isDark,
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

    Widget _tile(IconData icon, String title, String value) {
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
                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
                fontWeight: VFontWeight.semiBold,
              ),
            ),
          ],
        ),
      );
    }

    Widget _divider() {
      return Divider(
        height: 1,
        indent: VSpacing.lg + VSpacing.sm,
        color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
      );
    }

    final perksTiles = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tile(
          Icons.trending_up,
          'XP Multiplier',
          'x${multiplier.toStringAsFixed(2)}',
        ),
        _divider(),
        _tile(Icons.monetization_on, 'Daily Coin Bonus', '+$coinBonus'),
        _divider(),
        _tile(
          Icons.emoji_emotions,
          'Custom Reactions',
          '$reactionSlots slots',
        ),
        _divider(),
        _tile(
          Icons.push_pin,
          'Post Pins',
          pinLimit > 0 ? '$pinLimit available' : 'Locked',
        ),
        _divider(),
        _tile(Icons.language, 'World Creation', '$worldLimit worlds'),
        _divider(),
        _tile(
          Icons.local_bar,
          'Lounge Access',
          hasLounge ? 'Unlocked' : 'Locked',
        ),
        _divider(),
        _tile(
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
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isDark
              ? VColors.outlineVariantDark.withValues(alpha: 0.2)
              : VColors.outlineVariant.withValues(alpha: 0.3),
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
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ),
          perksBody,
        ],
      ),
    );
  }
}

