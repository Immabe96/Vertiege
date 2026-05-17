import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../widgets/profile/badge_display.dart';
import '../widgets/shared/tier_icon.dart';

class ResidentProfileScreen extends ConsumerStatefulWidget {
  final String residentId;

  const ResidentProfileScreen({super.key, required this.residentId});

  @override
  ConsumerState<ResidentProfileScreen> createState() =>
      _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends ConsumerState<ResidentProfileScreen> {
  Resident? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final currentResident = ref.read(residentProvider).resident;
    if (currentResident?.id == widget.residentId) {
      setState(() {
        _profile = currentResident;
        _loading = false;
      });
      return;
    }
    try {
      final fetched = await ProfileService.getProfile(widget.residentId);
      if (!mounted) return;
      setState(() {
        _profile = fetched;
        _loading = false;
        _error = fetched == null ? 'Resident not found' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load profile';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _profile?.name ?? 'Resident',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
      ),
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
                        icon: const Icon(Icons.refresh),
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
    final totalXp = isOwnProfile ? achievements.totalXp : 0;

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
                    if (room != null && mounted) {
                      context.push('/chat/${room['id']}');
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
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
                        icon: const Icon(Icons.handshake),
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
                        icon: const Icon(Icons.handshake_outlined),
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
                      icon: const Icon(Icons.handshake_outlined),
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
                            icon: const Icon(Icons.person_remove),
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
                            icon: const Icon(Icons.person_add),
                            label: const Text('Follow'),
                          );
                  },
                ),
              ],
            ),
          ),
        ],

        if (resident.decorations.isNotEmpty) ...[
          const SizedBox(height: VSpacing.lg),
          FadeIn(
            delayMs: 160,
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
