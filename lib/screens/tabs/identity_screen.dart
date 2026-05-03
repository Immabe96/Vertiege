import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../services/auth_service.dart';
import '../../state/resident_provider.dart';
import '../../state/achievement_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

import '../../widgets/core/fade_in.dart';
import '../../widgets/core/tactile_button.dart';
import '../../widgets/profile/cosmetic_avatar.dart';
import '../../widgets/profile/name_banner.dart';
import '../../widgets/profile/badge_display.dart';
import '../../widgets/profile/share_card.dart';

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  int _previousXp = 0;

  static const double _coverHeight = 180;
  static const double _avatarSize = 80;
  static const double _avatarBorderWidth = 4;
  static const double _parallaxFactor = 0.45;

  static const _avatars = [
    'avatar-1', 'avatar-2', 'avatar-3',
    'avatar-4', 'avatar-5', 'avatar-6',
  ];

  static const _professions = [
    '', 'Aviation', 'Medical', 'Finance', 'Legal',
    'Technology', 'Engineering', 'Arts',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if ((offset - _scrollOffset).abs() > 1) {
      setState(() => _scrollOffset = offset);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ── Edit Profile Modal ──────────────────────────────────────

  void _showEditProfileSheet(Resident resident) {
    final nameController = TextEditingController(text: resident.name);
    final bioController = TextEditingController(text: resident.bio);
    final nameFocus = FocusNode();
    final bioFocus = FocusNode();
    String selectedAvatar = _avatarFromUrl(resident.avatarUrl);
    String selectedProfession = resident.profession ?? '';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.xl)),
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
                            borderRadius: BorderRadius.circular(RadiusTokens.round),
                          ),
                        ),
                      ),

                      // Title
                      Text(
                        'Edit Profile',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
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
                      _sectionHeader(ctx, 'Avatar'),
                      const SizedBox(height: Spacing.sm),
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: _avatars.length,
                          separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
                          itemBuilder: (context, index) {
                            final a = _avatars[index];
                            final selected = selectedAvatar == a;
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedAvatar = a),
                              child: AnimatedContainer(
                                duration: AnimDurations.fast,
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? AppColors.seed : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: selected
                                      ? [BoxShadow(color: AppColors.seed.withValues(alpha: 0.3), blurRadius: 12)]
                                      : null,
                                ),
                                child: ClipOval(
                                  child: Image.asset('assets/generated/$a.png', fit: BoxFit.cover),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
                            borderRadius: BorderRadius.circular(RadiusTokens.md),
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
                                      ? AppColors.dangerRed
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
                            borderRadius: BorderRadius.circular(RadiusTokens.md),
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
                      DropdownButtonFormField<String>(
                        initialValue: selectedProfession,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(RadiusTokens.md),
                          ),
                          prefixIcon: const Icon(Icons.work_outline),
                          filled: true,
                        ),
                        items: _professions.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.isEmpty ? 'None' : p),
                            )).toList(),
                        onChanged: (v) => setSheetState(() => selectedProfession = v ?? ''),
                      ),
                      const SizedBox(height: Spacing.xl),

                      // ── Save Button ────────────────────────
                      TactileButton(
                        label: saving ? 'Saving...' : 'Save Changes',
                        icon: saving ? null : Icons.check,
                        fullWidth: true,
                        color: AppColors.seed,
                        onPressed: saving
                            ? null
                            : () {
                                final name = nameController.text.trim();
                                if (name.isEmpty || name.length < 2) {
                                  HapticFeedback.heavyImpact();
                                  nameFocus.requestFocus();
                                  return;
                                }

                                setSheetState(() => saving = true);

                                ref.read(residentProvider.notifier).updateProfile(
                                      name: name,
                                      bio: bioController.text.trim(),
                                      avatarUrl: 'assets/generated/$selectedAvatar.png',
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

  // ── Sign Out ────────────────────────────────────────────────

  void _confirmSignOut() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
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
              backgroundColor: AppColors.dangerRed,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final achievements = ref.watch(achievementProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (resident == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    // Animate XP change detection
    final currentXp = achievements.totalXp;
    if (currentXp != _previousXp && _previousXp != 0) {
      HapticFeedback.lightImpact();
    }
    _previousXp = currentXp;

    final verifiedAchievementCount =
        achievements.userAchievements.where((a) => a.status == AchievementStatus.verified).length;

    final avatarBorderColor = isDark ? AppColors.darkSurfaceBase : colorScheme.surface;
    final coverOverflow = _scrollOffset > 0 ? _scrollOffset * _parallaxFactor : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          // ── Cover image with parallax ─────────────────────
          Positioned(
            top: -coverOverflow,
            left: 0,
            right: 0,
            height: _coverHeight + coverOverflow,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.gradientPrimary,
                ),
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(residentProvider.notifier).loadResident();
              await ref.read(achievementProvider.notifier).loadAchievements();
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            displacement: 80,
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                // Spacer for cover height minus half avatar overlap
                SizedBox(height: _coverHeight - (_avatarSize / 2) - _avatarBorderWidth),

                // ── Avatar (overlapping cover) ──────────────
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: avatarBorderColor,
                        width: _avatarBorderWidth,
                      ),
                      boxShadow: ShadowTokens.md,
                    ),
                    child: Hero(
                      tag: 'avatar-${resident.id}',
                      child: CosmeticAvatar(
                        totalXp: currentXp,
                        size: _avatarSize,
                        imageUrl: resident.avatarUrl,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md - 4),

                // ── Name ────────────────────────────────────
                FadeIn(
                  delayMs: 60,
                  child: Center(
                    child: NameBanner(
                      profession: resident.profession,
                      name: resident.name,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xs + 2),

                // ── Tier label ───────────────────────────────
                FadeIn(
                  delayMs: 80,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(RadiusTokens.round),
                      ),
                      child: Text(
                        resident.tier.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          letterSpacing: LetterSpacing.wide,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // ── Animated XP counter ─────────────────────
                FadeIn(
                  delayMs: 95,
                  child: _AnimatedXpCounter(xp: currentXp),
                ),
                const SizedBox(height: Spacing.xs),

                // ── Stats row ────────────────────────────────
                FadeIn(
                  delayMs: 110,
                  child: _StatsRow(
                    achievementCount: verifiedAchievementCount,
                    followingCount: resident.following.length,
                    worldsCount: resident.joinedWorldIds.length,
                    onAchievementsTap: () => context.push('/achievements'),
                    onFollowingTap: () {
                      // Future: navigate to following list
                    },
                    onWorldsTap: () {
                      // Scroll to worlds section or navigate
                    },
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // ── Edit Profile button ─────────────────────
                FadeIn(
                  delayMs: 120,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditProfileSheet(resident),
                        icon: const Icon(Icons.edit, size: IconSizes.md),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: Spacing.md - 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RadiusTokens.md),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // ── Profile completion hints ────────────────
                if (resident.bio.isEmpty)
                  FadeIn(
                    delayMs: 140,
                    child: _CompletionHint(
                      icon: Icons.auto_awesome,
                      title: 'Add a bio',
                      subtitle: 'Tell people who you are and what you do.',
                      color: AppColors.beeYellow,
                      onTap: () => _showEditProfileSheet(resident),
                    ),
                  ),
                if (resident.profession == null || resident.profession!.isEmpty)
                  FadeIn(
                    delayMs: 150,
                    child: _CompletionHint(
                      icon: Icons.work_outline,
                      title: 'Pick a profession',
                      subtitle: 'Unlock profession-specific worlds and badges.',
                      color: AppColors.eelBlue,
                      onTap: () => _showEditProfileSheet(resident),
                    ),
                  ),
                if (resident.bio.isEmpty || resident.profession == null || resident.profession!.isEmpty)
                  const SizedBox(height: Spacing.sm),

                // ── Divider ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    height: 1,
                  ),
                ),
                const SizedBox(height: Spacing.sm),

                // ── Badges section ───────────────────────────
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

                // ── Divider ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    height: 1,
                  ),
                ),
                const SizedBox(height: Spacing.sm),

                // ── Achievements link ────────────────────────
                FadeIn(
                  delayMs: 180,
                  child: ListTile(
                    leading: Icon(Icons.emoji_events, color: AppColors.gold),
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
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    onTap: () => context.push('/achievements'),
                  ),
                ),
                FadeIn(
                  delayMs: 195,
                  child: ListTile(
                    leading: Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
                    title: const Text('Settings'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    onTap: () => context.push('/settings'),
                  ),
                ),

                const SizedBox(height: Spacing.md),

                // ── Sign out ─────────────────────────────────
                FadeIn(
                  delayMs: 210,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.dangerRed),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.dangerRed),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      onTap: _confirmSignOut,
                    ),
                  ),
                ),

                const SizedBox(height: Spacing.md),

                // ── Share card ───────────────────────────────
                FadeIn(
                  delayMs: 230,
                  child: ShareCard(
                    resident: resident,
                    totalXp: currentXp,
                    achievementCount: verifiedAchievementCount,
                  ),
                ),

                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  String _avatarFromUrl(String url) {
    for (final a in _avatars) {
      if (url.contains(a)) return a;
    }
    return _avatars[0];
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: LetterSpacing.wide,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated XP Counter
// ═══════════════════════════════════════════════════════════════

class _AnimatedXpCounter extends StatelessWidget {
  final int xp;
  const _AnimatedXpCounter({required this.xp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: xp),
        duration: AnimDurations.entrance,
        curve: AnimCurves.easeOut,
        builder: (context, value, _) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.seed.withValues(alpha: 0.08),
                  AppColors.gemPink.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(RadiusTokens.md),
              border: Border.all(
                color: AppColors.seed.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: IconSizes.md, color: AppColors.beeYellow),
                const SizedBox(width: Spacing.sm),
                Text(
                  '${value}XP',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.seed,
                    letterSpacing: LetterSpacing.tight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Stats Row
// ═══════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final int achievementCount;
  final int followingCount;
  final int worldsCount;
  final VoidCallback? onAchievementsTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onWorldsTap;

  const _StatsRow({
    required this.achievementCount,
    required this.followingCount,
    required this.worldsCount,
    this.onAchievementsTap,
    this.onFollowingTap,
    this.onWorldsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Row(
        children: [
          Expanded(child: _StatItem(label: 'Achievements', count: achievementCount, onTap: onAchievementsTap)),
          _StatDivider(),
          Expanded(child: _StatItem(label: 'Following', count: followingCount, onTap: onFollowingTap)),
          _StatDivider(),
          Expanded(child: _StatItem(label: 'Worlds', count: worldsCount, onTap: onWorldsTap)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _StatItem({required this.label, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.slow,
      curve: AnimCurves.bouncy,
      builder: (context, progress, _) {
        return Transform.scale(
          scale: progress,
          child: Opacity(
            opacity: progress,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(RadiusTokens.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: LetterSpacing.tight,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs - 2),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        letterSpacing: LetterSpacing.wide,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section Header
// ═══════════════════════════════════════════════════════════════

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
            fontWeight: FontWeight.w700,
            letterSpacing: LetterSpacing.wide,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Profile Completion Hint
// ═══════════════════════════════════════════════════════════════

class _CompletionHint extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _CompletionHint({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  State<_CompletionHint> createState() => _CompletionHintState();
}

class _CompletionHintState extends State<_CompletionHint> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs + 2),
      child: Dismissible(
        key: ValueKey('hint-${widget.title}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: Spacing.md),
          child: Icon(Icons.close, color: theme.colorScheme.outline),
        ),
        onDismissed: (_) => setState(() => _dismissed = true),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(RadiusTokens.md),
            child: Container(
              padding: const EdgeInsets.all(Spacing.md - 4),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(RadiusTokens.sm),
                    ),
                    child: Icon(widget.icon, size: IconSizes.md, color: widget.color),
                  ),
                  const SizedBox(width: Spacing.md - 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: IconSizes.xs + 2, color: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
