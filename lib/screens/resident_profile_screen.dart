import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resident.dart';
import '../state/resident_provider.dart';
import '../state/achievement_provider.dart';
import 'package:go_router/go_router.dart';
import '../services/profile_service.dart';
import '../services/chat_service.dart';
import '../state/ally_provider.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/luminary_nameplate.dart';
import '../widgets/profile/badge_display.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(_profile?.name ?? 'Resident')),
      body: _buildBody(theme, achievements),
    );
  }

  Widget _buildBody(ThemeData theme, dynamic achievements) {
    if (_loading) {
      return const ScreenLoading.profile();
    }
    if (_error != null || _profile == null) {
      return AppErrorState(
        message: _error ?? 'Resident not found',
        onRetry: _loadProfile,
      );
    }
    final resident = _profile!;
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        // ── Glass profile card ──────────────────────────
        GlassPanel(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: [
              Center(
                child: Hero(
                  tag: 'avatar-${resident.id}',
                  child: CosmeticAvatar(
                    totalXp:
                        resident.id == ref.read(residentProvider).resident?.id
                        ? achievements.totalXp
                        : 0,
                    imageUrl: resident.avatarUrl,
                    seed: resident.id,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
              if (resident.profession != null)
                Center(
                  child: Text(
                    resident.profession!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FadeIn(
                delayMs: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TierIcon(tier: resident.tier.value),
                    const SizedBox(width: 8),
                    Text(
                      resident.tier.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              FadeIn(
                delayMs: 100,
                child: Center(
                  child: Text(
                    '${resident.tier.label} Tier',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              if (resident.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                FadeIn(
                  delayMs: 120,
                  child: Text(
                    resident.bio,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FadeIn(
                delayMs: 140,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  ),
                  child: Text(
                    'Streak: ${resident.streakCount} days',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeights.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Action buttons ──────────────────────────────
        if (resident.id != ref.watch(residentProvider).resident?.id) ...[
          const SizedBox(height: Spacing.lg),
          FadeIn(
            delayMs: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Message button — gold CTA
                FilledButton.icon(
                  onPressed: () async {
                    final currentId = ref.read(residentProvider).resident?.id;
                    if (currentId == null) return;
                    final room = await ChatService.getOrCreateRoom(
                      currentId,
                      resident.id,
                    );
                    if (room != null && mounted) {
                      final roomId = room['id'] as String;
                      context.push('/chat/$roomId');
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: AppColors.onTertiary,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                // Allegiance button
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
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                        ),
                      );
                    }
                    if (isPending) {
                      return OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.handshake_outlined),
                        label: const Text('Allegiance Pending'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.inkMuted,
                          side: const BorderSide(color: AppColors.glassBorder),
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
                      label: const Text('Send Allegiance'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    );
                  },
                ),
                const SizedBox(width: Spacing.sm),
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
                              foregroundColor: AppColors.inkSecondary,
                              side: const BorderSide(
                                color: AppColors.glassBorder,
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => ref
                                .read(residentProvider.notifier)
                                .follow(resident.id),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Follow'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          );
                  },
                ),
              ],
            ),
          ),
        ],

        // ── Decorations / badges ────────────────────────
        if (resident.decorations.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          FadeIn(
            delayMs: 180,
            child: BadgeDisplay(earnedBadgeIds: resident.decorations),
          ),
        ],
      ],
    );
  }
}
