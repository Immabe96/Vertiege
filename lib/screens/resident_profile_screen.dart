import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../router/world_navigation.dart';
import '../forui/v_hub_page.dart';
import '../models/resident.dart';
import '../state/resident_provider.dart';
import '../state/achievement_provider.dart';
import '../state/ally_provider.dart';
import '../services/profile_service.dart';
import '../services/chat_service.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/luminary_nameplate.dart';
import '../ui/icons/v_icons.dart';
import '../widgets/profile/badge_display.dart';
import '../widgets/profile/profile_achievement_showcase.dart';
import '../services/profile_achievements_service.dart';
import '../widgets/shared/profession_icon.dart';
import '../widgets/shared/tier_icon.dart';
import '../utils/profile_share.dart';

class ResidentProfileScreen extends ConsumerStatefulWidget {
  final String residentId;
  final String? highlightAchievementId;

  const ResidentProfileScreen({
    super.key,
    required this.residentId,
    this.highlightAchievementId,
  });

  @override
  ConsumerState<ResidentProfileScreen> createState() =>
      _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends ConsumerState<ResidentProfileScreen> {
  Resident? _profile;
  List<PublicAchievementEntry> _publicAchievements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final currentResident = ref.read(residentProvider).resident;
    Resident? profile;
    if (currentResident?.id == widget.residentId) {
      profile = currentResident;
    } else {
      try {
        profile = await ProfileService.getProfile(widget.residentId);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Failed to load profile';
        });
        return;
      }
    }

    List<PublicAchievementEntry> achievements = [];
    if (profile != null) {
      try {
        achievements = await ProfileAchievementsService.fetchPublicProfile(
          widget.residentId,
        );
      } catch (_) {
        achievements = [];
      }
    }

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _publicAchievements = achievements;
      _loading = false;
      _error = profile == null ? 'Resident not found' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return VHubPage(
      title: _profile?.name ?? 'Resident',
      showBack: true,
      headerActions: _profile == null
          ? const []
          : [
              IconButton(
                tooltip: 'Share profile',
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  final p = _profile!;
                  SharePlus.instance.share(
                    ShareParams(
                      text: ProfileShare.shareMessage(
                        name: p.name,
                        residentId: p.id,
                        achievementId: widget.highlightAchievementId,
                      ),
                    ),
                  );
                },
              ),
            ],
      body: _loading
          ? const ScreenLoading.profile()
          : _error != null || _profile == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: VIconSize.xl,
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: VSpacing.md),
                      Text(
                        _error ?? 'Resident not found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: VSpacing.lg),
                      FilledButton.icon(
                        onPressed: _loadProfile,
                        icon: const Icon(VIcons.arrowLeft),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildBody(theme, achievements, isDark),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    dynamic achievements,
    bool isDark,
  ) {
    final resident = _profile!;
    final isOwnProfile =
        resident.id == ref.read(residentProvider).resident?.id;
    final totalXp = resident.totalXp;

    return ListView(
      padding: const EdgeInsets.all(VSpacing.lg),
      children: [
        FadeIn(
          delayMs: 60,
          child: Container(
            padding: const EdgeInsets.all(VSpacing.xl),
            decoration: BoxDecoration(
              color: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.xl),
              border: Border.all(
                color: isDark
                    ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                    : VColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
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
                      totalXp: totalXp,
                      size: 96,
                      imageUrl: resident.avatarUrl,
                      seed: resident.id,
                    ),
                  ),
                ),
                const SizedBox(height: VSpacing.md),
                LuminaryNameplate(
                  name: resident.name,
                  tier: resident.tier.value,
                  fontSize: VFontSize.headlineMd,
                  textAlign: TextAlign.center,
                  title: resident.title,
                ),
                if (resident.profession != null &&
                    resident.profession!.isNotEmpty) ...[
                  const SizedBox(height: VSpacing.xs),
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
                            ? VColors.glassBorderDark
                            : VColors.glassBorder,
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
                const SizedBox(height: VSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TierIcon(tier: resident.tier.value),
                    const SizedBox(width: VSpacing.xs),
                    Text(
                      resident.tier.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: VColors.primary,
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                  ],
                ),
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
                const SizedBox(height: VSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: VColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Text(
                    '${resident.streakCount} day streak',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: VColors.warning,
                      fontWeight: VFontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (!isOwnProfile) ...[
          const SizedBox(height: VSpacing.lg),
          FadeIn(
            delayMs: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final currentId = ref.read(residentProvider).resident?.id;
                    if (currentId == null) return;
                    final room = await ChatService.getOrCreateRoom(
                      currentId,
                      resident.id,
                    );
                    if (room != null) {
                      if (!mounted) return;
                      context.push(dmPath(room['id'] as String));
                    }
                  },
                  icon: const Icon(VIcons.message),
                  label: const Text('Message'),
                ),
                const SizedBox(width: VSpacing.sm),
                Consumer(
                  builder: (context, ref, _) {
                    final currentId = ref.watch(residentProvider).resident?.id;
                    if (currentId == null) return const SizedBox.shrink();
                    final allyState = ref.watch(allyProvider);
                    final isAlly = allyState.allies.any(
                      (a) => a.otherId(currentId) == resident.id,
                    );
                    final isPending = allyState.pendingRequests.any(
                      (r) =>
                          r.requesterId == currentId &&
                          r.receiverId == resident.id,
                    );
                    if (isAlly) {
                      return OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(VIcons.handshake),
                        label: const Text('Allies'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VColors.success,
                          side: const BorderSide(color: VColors.success),
                        ),
                      );
                    }
                    if (isPending) {
                      return OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(VIcons.handshake),
                        label: const Text('Pending'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                          side: BorderSide(
                            color: isDark
                                ? VColors.outlineVariantDark
                                : VColors.outlineVariant,
                          ),
                        ),
                      );
                    }
                    return OutlinedButton.icon(
                      onPressed: () => ref
                          .read(allyProvider.notifier)
                          .sendRequest(
                            requesterId: currentId,
                            receiverId: resident.id,
                          ),
                      icon: const Icon(VIcons.handshake),
                      label: const Text('Ally'),
                    );
                  },
                ),
                const SizedBox(width: VSpacing.sm),
                Consumer(
                  builder: (context, ref, _) {
                    final isFollowing = ref.watch(
                      residentProvider.select(
                        (s) =>
                            s.resident?.following.contains(resident.id) ??
                            false,
                      ),
                    );
                    return isFollowing
                        ? OutlinedButton.icon(
                            onPressed: () => ref
                                .read(residentProvider.notifier)
                                .unfollow(resident.id),
                            icon: const Icon(VIcons.userMinus),
                            label: const Text('Unfollow'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                              side: BorderSide(
                                color: isDark
                                    ? VColors.outlineVariantDark
                                    : VColors.outlineVariant,
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => ref
                                .read(residentProvider.notifier)
                                .follow(resident.id),
                            icon: const Icon(VIcons.userPlus),
                            label: const Text('Follow'),
                          );
                  },
                ),
              ],
            ),
          ),
        ],

        if (_publicAchievements.isNotEmpty) ...[
          const SizedBox(height: VSpacing.lg),
          FadeIn(
            delayMs: 140,
            child: Container(
              padding: const EdgeInsets.all(VSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? VColors.surfaceContainerDark
                    : VColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(VRadius.xl),
                border: Border.all(
                  color: isDark
                      ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                      : VColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: ProfileAchievementShowcase(
                entries: _publicAchievements,
                highlightAchievementId: widget.highlightAchievementId,
              ),
            ),
          ),
        ],

        if (resident.decorations.isNotEmpty) ...[
          const SizedBox(height: VSpacing.lg),
          FadeIn(
            delayMs: 180,
            child: Container(
              padding: const EdgeInsets.all(VSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? VColors.surfaceContainerDark
                    : VColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(VRadius.xl),
                border: Border.all(
                  color: isDark
                      ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                      : VColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: VIconSize.md,
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
                  const SizedBox(height: VSpacing.md),
                  BadgeDisplay(earnedBadgeIds: resident.decorations),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
