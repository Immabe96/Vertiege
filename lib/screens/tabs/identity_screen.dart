import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../state/resident_provider.dart';
import '../../state/achievement_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../utils/haptics.dart';

import '../../widgets/core/fade_in.dart';

import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/tactile_button.dart';
import '../../widgets/profile/cosmetic_avatar.dart';
import '../../widgets/profile/luminary_nameplate.dart';
import '../../widgets/profile/badge_display.dart';
import '../../state/ally_provider.dart';
import '../../widgets/shared/progress_bar.dart';
import '../../widgets/core/sovereign_stat.dart';
import '../../widgets/profile/streak_display.dart';
import '../../widgets/profile/completion_hint.dart';
import '../../widgets/profile/referral_chip.dart';
import '../../widgets/profile/subscription_badge.dart';
import '../../config/achievements.dart';

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen> {
  final _scrollController = ScrollController();
  int _previousXp = 0;
  SubscriptionTier _subscriptionTier = SubscriptionTier.resident;

  static const double _avatarRadius = 80;
  static const double _goldBorderWidth = 2.5;

  static const _professions = [
    '', 'Aviation', 'Medical', 'Finance', 'Legal',
    'Technology', 'Engineering', 'Arts',
  ];

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSubscriptionTier();
  }

  Future<void> _loadSubscriptionTier() async {
    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      final tier = await SubscriptionService.getTier(resident.id);
      if (mounted) {
        setState(() => _subscriptionTier = tier);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Edit Profile Modal ──────────────────────────────────────

  void _showEditProfileSheet(Resident resident) {
    final nameController = TextEditingController(text: resident.name);
    final bioController = TextEditingController(text: resident.bio);
    final nameFocus = FocusNode();
    final bioFocus = FocusNode();
    File? editAvatarFile;
    String selectedProfession = resident.profession ?? '';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.cardFeatured)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (ctx, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lg,
                      Spacing.sm,
                      Spacing.lg,
                      Spacing.xl,
                    ),
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: Spacing.lg),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(RadiusTokens.pill),
                          ),
                        ),
                      ),

                      // Title
                      Text(
                        'Edit Profile',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeights.bold,
                            ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Customize how others see you in the worlds.',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── Avatar Picker ──────────────────────
                      _sectionHeader(ctx, 'Profile Photo'),
                      const SizedBox(height: Spacing.sm),
                      _buildEditAvatarPicker(ctx, resident, (f) => setSheetState(() => editAvatarFile = f)),
                      const SizedBox(height: Spacing.lg),

                      // ── Display Name ───────────────────────
                      _sectionHeader(ctx, 'Display name'),
                      const SizedBox(height: Spacing.sm),
                      TextField(
                        controller: nameController,
                        focusNode: nameFocus,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: 100,
                        onSubmitted: (_) => bioFocus.requestFocus(),
                        decoration: InputDecoration(
                          hintText: 'Your display name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(RadiusTokens.card),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── Bio ────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionHeader(ctx, 'Bio'),
                          Text(
                            '${bioController.text.length}/160',
                            style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                  color: bioController.text.length >= 160
                                      ? AppColors.semanticError
                                      : Theme.of(ctx).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      TextField(
                        controller: bioController,
                        focusNode: bioFocus,
                        maxLines: 3,
                        maxLength: 160,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'A few words about yourself...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(RadiusTokens.card),
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 56),
                            child: Icon(Icons.edit_note),
                          ),
                          filled: true,
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── Profession ─────────────────────────
                      _sectionHeader(ctx, 'Profession'),
                      const SizedBox(height: Spacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _professions.map((p) {
                          final isSel = selectedProfession == p;
                          return ChoiceChip(
                            label: Text(p.isEmpty ? 'None' : p),
                            selected: isSel,
                            onSelected: (_) => setSheetState(() => selectedProfession = p),
                            selectedColor: AppColors.accentLevel,
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.ink : Theme.of(ctx).colorScheme.onSurfaceVariant,
                              fontSize: FontSizes.body,
                            ),
                            backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                            side: BorderSide(
                              color: isSel ? AppColors.primary : AppColors.surfaceOverlay,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Self-declared — verification coming in a future update.',
                        style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: Spacing.xl),

                      // ── Save Button ────────────────────────
                      TactileButton(
                        label: saving ? 'Saving...' : 'Save Changes',
                        icon: saving ? null : Icons.check,
                        fullWidth: true,
                        color: AppColors.accentLevel,
                        onPressed: saving
                            ? null
                            : () {
                                final name = nameController.text.trim();
                                if (name.isEmpty || name.length < 2) {
                                  Haptics.heavy();
                                  nameFocus.requestFocus();
                                  return;
                                }

                                setSheetState(() => saving = true);

                                final cloudAvatar = editAvatarFile?.path;

                                ref.read(residentProvider.notifier).updateProfile(
                                      name: name,
                                      bio: bioController.text.trim(),
                                      avatarPath: cloudAvatar,
                                      profession: selectedProfession.isEmpty ? null : selectedProfession,
                                    );

                                Navigator.of(sheetContext).pop();
                              },
                      ),
                      const SizedBox(height: Spacing.sm),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      bioController.dispose();
      nameFocus.dispose();
      bioFocus.dispose();
    });
  }

  // ── Edit Profile Sheet ────────────────────────────────────


  // ── Sign Out ────────────────────────────────────────────────

  void _confirmSignOut() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
        ),
        title: const Text('Sign out?'),
        content: const Text('You\'ll need to sign in again to access your worlds and progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.signOut();
              if (mounted) context.go('/login');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.semanticError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // ── Tier Progress Color ─────────────────────────────────────

  Color _tierProgressColor(ResidentTier tier) {
    switch (tier) {
      case ResidentTier.apex:
        return AppColors.tertiary;
      case ResidentTier.oldMoney:
        return AppColors.tertiary;
      case ResidentTier.elite:
        return AppColors.primary;
      case ResidentTier.highRollers:
        return AppColors.tierHighRoller;
      case ResidentTier.hustlers:
        return AppColors.surfaceOverlay;
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final achievements = ref.watch(achievementProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (resident == null) {
      return const Scaffold(body: ScreenLoading.profile());
    }

    // Animate XP change detection
    final currentXp = achievements.totalXp;
    if (currentXp != _previousXp && _previousXp != 0) {
      Haptics.light();
    }
    _previousXp = currentXp;

    final verifiedAchievementCount =
        achievements.userAchievements.where((a) => a.status == AchievementStatus.verified).length;

    // Calculate total REP across all world standings
    final totalRep = resident.worldStandings.values.fold<int>(0, (sum, ws) => sum + ws.rep);

    // Compute tier progress for SovereignProgressBar
    final tierValue = resident.tier.value;
    final nextTierValue = tierValue + 1;
    final currentThreshold = xpThresholds[tierValue] ?? 0;
    final nextThreshold = xpThresholds[nextTierValue];
    final tierProgress = nextThreshold != null
        ? ((currentXp - currentThreshold) / (nextThreshold - currentThreshold)).clamp(0.0, 1.0)
        : 1.0;

    final tierNames = {1: 'Hustler', 2: 'High Roller', 3: 'Elite', 4: 'Old Money', 5: 'Apex'};
    final nextTierName = tierNames[nextTierValue] ?? 'Max';
    final tierColor = _tierProgressColor(resident.tier);
    final xpInTier = currentXp - currentThreshold;
    final xpNeeded = nextThreshold != null ? nextThreshold - currentThreshold : 0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              toolbarHeight: 56,
              elevation: 0,
              backgroundColor: AppColors.surface.withAlpha(204),
              title: const Text('Identity'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: AppColors.inkSecondary),
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          Haptics.light();
          await ref.read(residentProvider.notifier).loadResident();
          await ref.read(achievementProvider.notifier).loadAchievements();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
        displacement: 80,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: Spacing.section),

            // ── Sovereign Profile Header ──────────────────
            // Glow + Avatar stack
            Center(
              child: SizedBox(
                width: (_avatarRadius * 2) + 48,
                height: (_avatarRadius * 2) + 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow behind avatar
                    Container(
                      width: _avatarRadius * 2 + 16,
                      height: _avatarRadius * 2 + 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.tertiary.withValues(alpha: 0.10),
                            blurRadius: 48,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    // Avatar with gold border ring
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.tertiary,
                          width: _goldBorderWidth,
                        ),
                      ),
                      child: Hero(
                        tag: 'avatar-${resident.id}',
                        child: CosmeticAvatar(
                          totalXp: currentXp,
                          size: _avatarRadius * 2,
                          imageUrl: resident.avatarUrl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // ── Name ──────────────────────────────────────
            FadeIn(
              delayMs: 60,
              child: Center(
                child: LuminaryNameplate(
                  name: resident.name,
                  tier: resident.tier.value,
                  fontSize: FontSizes.headlineLg,
                  textAlign: TextAlign.center,
                  title: resident.title,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),

            // ── Tier Title ─────────────────────────────────
            FadeIn(
              delayMs: 80,
              child: Center(
                child: Text(
                  resident.tier.label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: FontSizes.bodyMd,
                    fontWeight: FontWeights.semiBold,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
            ),

            // ── Subscription Badge ───────────────────────
            if (_subscriptionTier != SubscriptionTier.resident)
              FadeIn(
                delayMs: 85,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: Spacing.xs),
                    child: SubscriptionBadge(tier: _subscriptionTier),
                  ),
                ),
              ),

            const SizedBox(height: Spacing.sm),

            // ── REP Badge Pill ─────────────────────────────
            FadeIn(
              delayMs: 90,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  ),
                  child: Text(
                    '$totalRep REP',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.onTertiary,
                      fontWeight: FontWeights.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),

            // ── Referral Code ──────────────────────────────
            FadeIn(
              delayMs: 95,
              child: ReferralChip(
                referralCode: resident.referralCode,
                referredBy: resident.referredBy,
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // ── Standing / Tier Progress ───────────────────
            FadeIn(
              delayMs: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Column(
                  children: [
                    SovereignProgressBar(
                      progress: tierProgress,
                      color: tierColor,
                      label: '${resident.tier.label} Tier',
                      trailing: nextThreshold != null ? 'Next: $nextTierName' : 'Max Tier',
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$xpInTier / $xpNeeded XP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          '$currentXp total XP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeights.semiBold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),

            // ── Action Buttons ─────────────────────────────
            FadeIn(
              delayMs: 110,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Row(
                  children: [
                    // Primary: Edit Profile
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showEditProfileSheet(resident),
                        icon: const Icon(Icons.edit, size: IconSizes.md),
                        label: const Text('Edit Profile'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.tertiary,
                          foregroundColor: AppColors.onTertiary,
                          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RadiusTokens.card),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    // Secondary: Share
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Share.share('Join me on Vertiege! My profile: ${resident.name}');
                        },
                        icon: const Icon(Icons.share_outlined, size: IconSizes.md),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.glassBorder),
                          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RadiusTokens.card),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),

            // ── Stats Grid ─────────────────────────────────
            FadeIn(
              delayMs: 120,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: SovereignStat(
                        icon: Icons.emoji_events,
                        value: verifiedAchievementCount,
                        label: 'Achievements',
                        onTap: () => context.push('/achievements'),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: SovereignStat(
                        icon: Icons.people,
                        value: resident.following.length,
                        label: 'Following',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: SovereignStat(
                        icon: Icons.public,
                        value: resident.joinedWorldIds.length,
                        label: 'Worlds',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // ── Streak Display ──────────────────────────────
            FadeIn(
              delayMs: 130,
              child: StreakDisplay(
                streakCount: resident.streakCount,
                streakShields: resident.streakShields,
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // ── Profile completion hints ────────────────────
            if (resident.bio.isEmpty)
              FadeIn(
                delayMs: 140,
                child: CompletionHint(
                  icon: Icons.auto_awesome,
                  title: 'Add a bio',
                  subtitle: 'Tell people who you are and what you do.',
                  color: AppColors.warning,
                  onTap: () => _showEditProfileSheet(resident),
                ),
              ),
            if (resident.profession == null || resident.profession!.isEmpty)
              FadeIn(
                delayMs: 150,
                child: CompletionHint(
                  icon: Icons.work_outline,
                  title: 'Pick a profession',
                  subtitle: 'Unlock profession-specific worlds and badges.',
                  color: AppColors.primary,
                  onTap: () => _showEditProfileSheet(resident),
                ),
              ),
            if (resident.bio.isEmpty || resident.profession == null || resident.profession!.isEmpty)
              const SizedBox(height: Spacing.sm),

            // ── Divider ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                height: 1,
              ),
            ),
            const SizedBox(height: Spacing.sm),

            // ── Badges section ─────────────────────────────
            FadeIn(
              delayMs: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: _SectionHeader(
                  icon: Icons.emoji_events,
                  title: 'Badges',
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            FadeIn(
              delayMs: 170,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: BadgeDisplay(earnedBadgeIds: resident.decorations),
              ),
            ),
            const SizedBox(height: Spacing.xs),

            // ── Divider ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                height: 1,
              ),
            ),
            const SizedBox(height: Spacing.sm),

            // ── Achievements link ──────────────────────────
            FadeIn(
              delayMs: 180,
              child: ListTile(
                leading: Icon(Icons.emoji_events, color: AppColors.tertiary),
                title: const Text('Achievements'),
                subtitle: Text('$verifiedAchievementCount verified'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currentXp XP',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Icon(Icons.chevron_right, color: colorScheme.outline),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
                onTap: () => context.push('/achievements'),
              ),
            ),
            FadeIn(
              delayMs: 183,
              child: Consumer(
                builder: (context, ref, _) {
                  final allies = ref.watch(allyProvider).allies;
                  return ListTile(
                    leading: Icon(
                      Icons.handshake,
                      color: allies.isNotEmpty ? AppColors.tertiary : colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Allies'),
                    subtitle: Text(allies.isNotEmpty
                        ? '${allies.length} ${allies.length == 1 ? 'ally' : 'allies'}'
                        : 'No allies yet'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.card),
                    ),
                  );
                },
              ),
            ),
            FadeIn(
              delayMs: 185,
              child: ListTile(
                leading: Icon(Icons.leaderboard, color: AppColors.tertiary),
                title: const Text('Hall of Ascension'),
                subtitle: const Text('View global rankings'),
                trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
                onTap: () => context.push('/hall-of-ascension'),
              ),
            ),
            FadeIn(
              delayMs: 190,
              child: ListTile(
                leading: Icon(Icons.monetization_on, color: AppColors.tertiary),
                title: const Text('Sovereign Regalia'),
                subtitle: Text(
                  '${resident.sovereignCoins} Sovereign Coins',
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    color: AppColors.tertiary,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
                onTap: () => context.push('/shop'),
              ),
            ),
            FadeIn(
              delayMs: 195,
              child: ListTile(
                leading: Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
                title: const Text('Settings'),
                trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
                onTap: () => context.push('/settings'),
              ),
            ),

            const SizedBox(height: Spacing.md),

            // ── Sign out ───────────────────────────────────
            FadeIn(
              delayMs: 230,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.semanticError),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.semanticError),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.card),
                  ),
                  onTap: _confirmSignOut,
                ),
              ),
            ),

            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Widget _buildEditAvatarPicker(
    BuildContext ctx,
    Resident resident,
    void Function(File?) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: _pickButton(ctx, Icons.camera_alt_outlined, 'Camera', () async {
            final picked = await _picker.pickImage(
              source: ImageSource.camera,
              maxWidth: 512,
              maxHeight: 512,
              imageQuality: 85,
            );
            if (picked != null) onChanged(File(picked.path));
          }),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _pickButton(ctx, Icons.photo_library_outlined, 'Gallery', () async {
            final picked = await _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 512,
              maxHeight: 512,
              imageQuality: 85,
            );
            if (picked != null) onChanged(File(picked.path));
          }),
        ),
      ],
    );
  }

  Widget _pickButton(
    BuildContext ctx,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final t = Theme.of(ctx);
    return Material(
      color: t.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(RadiusTokens.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: Spacing.xs),
              Text(label, style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: FontSizes.body)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeights.bold,
            letterSpacing: LetterSpacing.micro,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: IconSizes.sm + 2, color: theme.colorScheme.primary),
        const SizedBox(width: Spacing.sm),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeights.bold,
            letterSpacing: LetterSpacing.micro,
          ),
        ),
      ],
    );
  }
}
