import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../services/world_service.dart';
import '../../state/resident_provider.dart';
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
import '../../widgets/profile/referral_chip.dart';
import '../../widgets/profile/subscription_badge.dart';
import '../../widgets/profile/trophy_case.dart';
import '../../widgets/core/tier_up_dialog.dart';
import '../../config/achievements.dart';
import '../../config/cosmetics.dart';

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen> {
  final _scrollController = ScrollController();
  int _previousXp = 0;
  SubscriptionTier _subscriptionTier = SubscriptionTier.resident;
  List<Map<String, dynamic>> _highPrestigeWorlds = [];

  static const double _avatarRadius = 48;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionTier();
    _loadHighPrestigeWorlds();
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
              await AuthService.signOut();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = resident == null && residentState.isLoading;

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

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (resident == null) {
      return Scaffold(
        backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentXp = achievements.totalXp;
    if (currentXp != _previousXp && _previousXp != 0) {
      Haptics.light();
    }
    _previousXp = currentXp;

    final verifiedAchievementCount = achievements.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .length;

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

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: (isDark ? VColors.surfaceDark : VColors.surface)
            .withValues(alpha: 0.86),
        elevation: 0,
        title: Text(
          'Identity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
              size: VIconSize.md,
            ),
            tooltip: 'Refresh',
            onPressed: () async {
              Haptics.light();
              try {
                await ref.read(residentProvider.notifier).loadResident();
                await ref.read(achievementProvider.notifier).loadAchievements();
                await ref.read(postProvider.notifier).loadPosts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile refreshed'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refresh failed'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Hero Section ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(VSpacing.lg),
            child: Column(
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
                    Container(
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
                      child: Text(
                        resident.tier.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: VColors.primary,
                          fontWeight: VFontWeight.bold,
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

                // REP badge
                const SizedBox(height: VSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.lg,
                    vertical: VSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: VColors.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Text(
                    '$totalRep REP',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: VColors.tertiary,
                      fontWeight: VFontWeight.bold,
                    ),
                  ),
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
                      color: isDark
                          ? VColors.glassBackgroundDark
                          : VColors.glassBackground,
                      borderRadius: BorderRadius.circular(VRadius.pill),
                      border: Border.all(
                        color: isDark
                            ? VColors.glassBorderDark
                            : VColors.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.work,
                          size: VIconSize.xs,
                          color: isDark
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

          // ── Referral Code ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: ReferralChip(
              referralCode: resident.referralCode,
              referredBy: resident.referredBy,
            ),
          ),
          const SizedBox(height: VSpacing.lg),

          // ── Tier Progress ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: Column(
              children: [
                SovereignProgressBar(
                  progress: tierProgress,
                  color: VColors.primary,
                  label: '${resident.tier.label} Tier',
                  trailing: nextThreshold != null
                      ? 'Next: $nextTierName'
                      : 'Max Tier',
                ),
                const SizedBox(height: VSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentXp - currentThreshold} / ${nextThreshold != null ? nextThreshold - currentThreshold : 0} XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      '$currentXp total XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.lg),

          // ── Tier Perks ────────────────────────────────
          _PerksCard(tier: tierValue, isDark: isDark),

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

          // ── Stats Row ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events,
                    value: '$verifiedAchievementCount',
                    label: 'Achievements',
                    onTap: () => context.push('/achievements'),
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    value: '${resident.following.length}',
                    label: 'Following',
                    onTap: () => context.push('/search'),
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: _StatCard(
                    icon: Icons.public,
                    value: '${resident.joinedWorldIds.length}',
                    label: 'Worlds',
                    onTap: () => context.push('/explore'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.lg),

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

          // ── Streak Display ──────────────────────────────
          if (resident.streakCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
              child: StreakDisplay(
                streakCount: resident.streakCount,
                streakShields: resident.streakShields,
              ),
            ),
          if (resident.streakCount > 0) const SizedBox(height: VSpacing.lg),

          // ── Trophy Case ─────────────────────────────────
          TrophyCase(
            resident: resident,
            achievements: achievements.userAchievements,
            totalXp: currentXp,
          ),
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

          const Divider(height: 1),

          // ── Badges section (profession verifications only) ──
          if (professionBadgeIdsFor(resident.verifiedRoles).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.lg,
                VSpacing.lg,
                VSpacing.lg,
                VSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: VIconSize.sm,
                    color: VColors.tertiary,
                  ),
                  const SizedBox(width: VSpacing.xs),
                  Text(
                    'Badges',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
              child: BadgeDisplay(
                earnedBadgeIds: professionBadgeIdsFor(resident.verifiedRoles),
              ),
            ),
            const SizedBox(height: VSpacing.lg),
            const Divider(height: 1),
          ],

          // ── Navigation Links ──────────────────────────
          _NavTile(
            icon: Icons.emoji_events,
            iconColor: VColors.tertiary,
            title: 'Achievements',
            subtitle: '$verifiedAchievementCount verified · $currentXp XP',
            onTap: () => context.push('/achievements'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final allies = ref.watch(allyProvider).allies;
              return _NavTile(
                icon: Icons.handshake,
                iconColor: allies.isNotEmpty
                    ? VColors.tertiary
                    : (isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant),
                title: 'Allies',
                subtitle: allies.isNotEmpty
                    ? '${allies.length} ${allies.length == 1 ? 'ally' : 'allies'}'
                    : 'Find residents to connect',
                onTap: () => context.push('/search'),
              );
            },
          ),
          _NavTile(
            icon: Icons.leaderboard,
            iconColor: VColors.tertiary,
            title: 'Hall of Ascension',
            subtitle: 'View global rankings',
            onTap: () => context.push('/hall-of-ascension'),
          ),
          _NavTile(
            icon: Icons.monetization_on,
            iconColor: VColors.tertiary,
            title: 'Sovereign Regalia',
            subtitle: '${resident.sovereignCoins} Sovereign Coins',
            onTap: () => context.push('/shop'),
          ),
          _NavTile(
            icon: Icons.settings_outlined,
            iconColor: isDark
                ? VColors.onSurfaceVariantDark
                : VColors.onSurfaceVariant,
            title: 'Settings',
            onTap: () => context.push('/settings'),
          ),

          const SizedBox(height: VSpacing.sm),

          // ── Sign out ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: ListTile(
              leading: const Icon(Icons.logout, color: VColors.error),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: VColors.error),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VRadius.lg),
              ),
              onTap: _confirmSignOut,
            ),
          ),

          const SizedBox(height: VSpacing.xxl),
        ],
      ),
    );
  }
}

class _PerksCard extends ConsumerWidget {
  final int tier;
  final bool isDark;

  const _PerksCard({required this.tier, required this.isDark});

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
          Container(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(VSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? VColors.glassBackgroundDark
                : VColors.glassBackground,
            borderRadius: BorderRadius.circular(VRadius.lg),
            border: Border.all(
              color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: VIconSize.md, color: VColors.primary),
              const SizedBox(height: VSpacing.xs),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.lg,
            vertical: VSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: VIconSize.md, color: iconColor),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: VFontWeight.regular,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: VIconSize.md,
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
