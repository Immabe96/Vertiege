import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../router/world_navigation.dart';
import 'package:vertiege/ui/ui.dart';
import '../models/resident.dart';
import '../state/resident_provider.dart';
import '../state/achievement_provider.dart';
import '../state/ally_provider.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';
import '../services/profile_service.dart';
import '../services/chat_service.dart';
import '../theme/prestige_noir.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/luminary_nameplate.dart';
import '../widgets/profile/badge_display.dart';
import '../widgets/profile/profile_achievement_showcase.dart';
import '../widgets/profile/profile_standing_grid.dart';
import '../services/profile_achievements_service.dart';
import '../widgets/shared/profession_icon.dart';
import '../widgets/shared/tier_icon.dart';
import '../utils/profile_share.dart';
import '../widgets/report_sheet.dart';
import '../services/moderation_service.dart';

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
  List<Post> _standingPosts = [];
  bool _hasMoreStandingPosts = false;
  bool _loadingMoreStanding = false;
  bool _loading = true;
  String? _error;
  static const _postRepository = PostRepository();
  static const _standingPageSize = 12;

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
    List<Post> standingPosts = [];
    if (profile != null) {
      try {
        achievements = await ProfileAchievementsService.fetchPublicProfile(
          widget.residentId,
        );
      } catch (_) {
        achievements = [];
      }
      try {
        standingPosts = await _postRepository.publishedPostsByResident(
          widget.residentId,
        );
      } catch (_) {
        standingPosts = [];
      }
    }

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _publicAchievements = achievements;
      _standingPosts = standingPosts;
      _hasMoreStandingPosts = standingPosts.length >= _standingPageSize;
      _loading = false;
      _error = profile == null ? 'Resident not found' : null;
    });
  }

  Future<void> _loadMoreStandingPosts() async {
    if (_loadingMoreStanding || !_hasMoreStandingPosts) return;
    setState(() => _loadingMoreStanding = true);
    try {
      final next = await _postRepository.publishedPostsByResident(
        widget.residentId,
        offset: _standingPosts.length,
      );
      if (!mounted) return;
      setState(() {
        _standingPosts = [..._standingPosts, ...next];
        _hasMoreStandingPosts = next.length >= _standingPageSize;
        _loadingMoreStanding = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMoreStanding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementProvider);
    final theme = Theme.of(context);

    return VHubPage(
      title: _profile?.name ?? 'Resident',
      showBack: true,
      headerActions: _profile == null
          ? const []
          : [
              if (_profile!.id !=
                  ref.watch(residentProvider).resident?.id)
                VIconButton(
                  semanticsLabel: 'Report resident',
                  tooltip: 'Report',
                  child: const Icon(Icons.flag_outlined),
                  onPressed: () {
                    final me = ref.read(residentProvider).resident;
                    final target = _profile;
                    if (me == null || target == null) return;
                    ReportSheet.show(
                      context,
                      targetLabel: 'resident',
                      onSubmit: (reason, details) {
                        Navigator.pop(context);
                        ModerationService.submitReport(
                          reportedResidentId: target.id,
                          reporterId: me.id,
                          reason: reason.name,
                          details: details,
                        );
                        VFeedback.showMessage(
                          context,
                          'Report submitted. Thank you.',
                        );
                      },
                    );
                  },
                ),
              VIconButton(
                semanticsLabel: 'Share profile',
                tooltip: 'Share profile',
                child: const Icon(Icons.share_outlined),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: VSpacing.md),
                  Text(
                    _error ?? 'Resident not found',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: VSpacing.lg),
                  VButton(
                    label: 'Retry',
                    icon: const Icon(VIcons.arrowLeft),
                    onPressed: _loadProfile,
                  ),
                ],
              ),
            )
          : _buildBody(theme, achievements),
    );
  }

  Widget _buildBody(ThemeData theme, dynamic achievements) {
    final resident = _profile!;
    final isOwnProfile = resident.id == ref.read(residentProvider).resident?.id;
    final totalXp = resident.totalXp;
    return ListView(
      padding: const EdgeInsets.all(VSpacing.lg),
      children: [
        // Cover image banner.
        if (resident.coverImageUrl != null &&
            resident.coverImageUrl!.isNotEmpty) ...[
          FadeIn(
            delayMs: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.bento),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.network(
                  resident.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: PrestigeNoir.surfaceRaised,
                    child: const Center(
                      child: Icon(
                        Icons.landscape,
                        size: VIconSize.xl,
                        color: PrestigeNoir.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: VSpacing.md),
        ],
        FadeIn(
          delayMs: 60,
          child: VPrestigeCard(
            padding: const EdgeInsets.all(VSpacing.lg),
            child: Column(
              children: [
                Hero(
                  tag: 'avatar-${resident.id}',
                  child: CosmeticAvatar(
                    totalXp: totalXp,
                    size: 72,
                    imageUrl: resident.avatarUrl,
                    seed: resident.id,
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
                      border: Border.all(color: PrestigeNoir.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ProfessionIcon(
                          profession: resident.profession,
                          size: VBadgeSize.professionInline,
                          fallbackColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: VSpacing.xxs),
                        Text(
                          resident.profession!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: VColors.brand,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          const SizedBox(height: VSpacing.md),
          FadeIn(
            delayMs: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VButton(
                  label: 'Message',
                  isFullWidth: true,
                  icon: const Icon(VIcons.message),
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
                ),
                const SizedBox(height: VSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                      return const VButton(
                        label: 'Allies',
                        variant: ButtonVariant.outlined,
                        icon: Icon(VIcons.handshake),
                      );
                    }
                    if (isPending) {
                      return const VButton(
                        label: 'Pending',
                        variant: ButtonVariant.outlined,
                        icon: Icon(VIcons.handshake),
                      );
                    }
                    return VButton(
                      label: 'Ally',
                      variant: ButtonVariant.outlined,
                      icon: const Icon(VIcons.handshake),
                      onPressed: () => ref
                          .read(allyProvider.notifier)
                          .sendRequest(
                            requesterId: currentId,
                            receiverId: resident.id,
                          ),
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
                        ? VButton(
                            label: 'Unfollow',
                            variant: ButtonVariant.outlined,
                            icon: const Icon(VIcons.userMinus),
                            onPressed: () => ref
                                .read(residentProvider.notifier)
                                .unfollow(resident.id),
                          )
                        : VButton(
                            label: 'Follow',
                            variant: ButtonVariant.outlined,
                            icon: const Icon(VIcons.userPlus),
                            onPressed: () => ref
                                .read(residentProvider.notifier)
                                .follow(resident.id),
                          );
                  },
                ),
                  ],
                ),
              ],
            ),
          ),
        ],

        if (_publicAchievements.isNotEmpty) ...[
          const SizedBox(height: VSpacing.lg),
          FadeIn(
            delayMs: 140,
            child: VPrestigeCard(
              padding: const EdgeInsets.all(VSpacing.lg),
              child: ProfileAchievementShowcase(
                entries: _publicAchievements,
                highlightAchievementId: widget.highlightAchievementId,
              ),
            ),
          ),
        ] else if (!isOwnProfile) ...[
          const SizedBox(height: VSpacing.lg),
          FadeIn(
            delayMs: 140,
            child: VPrestigeCard(
              padding: const EdgeInsets.all(VSpacing.lg),
              child: Text(
                'No public achievements yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: PrestigeNoir.muted,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: VSpacing.lg),
        FadeIn(
          delayMs: 160,
          child: VPrestigeCard(
            padding: const EdgeInsets.all(VSpacing.lg),
            child: ProfileStandingGrid(
              posts: _standingPosts,
              maxVisible: _standingPosts.length,
              hasMore: _hasMoreStandingPosts,
              isLoadingMore: _loadingMoreStanding,
              onLoadMore: _loadMoreStandingPosts,
            ),
          ),
        ),

        if (resident.decorations.isNotEmpty) ...[
          const SizedBox(height: VSpacing.lg),
          FadeIn(
            delayMs: 180,
            child: VPrestigeCard(
              padding: const EdgeInsets.all(VSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: VIconSize.md,
                        color: VColors.brand,
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
