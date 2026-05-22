import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_system.dart';
import 'package:vertiege/theme/colors.dart';
import '../config/tiers.dart';
import '../models/channel.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../state/channel_provider.dart';
import '../state/chat_provider.dart';
import '../widgets/worlds/world_access_guard.dart';
import '../widgets/worlds/world_channel_list.dart';

import '../widgets/worlds/world_banner.dart';
import '../widgets/worlds/world_member_row.dart';

import '../widgets/worlds/world_feed_tab.dart';
import '../widgets/v_section_list.dart';
import '../widgets/worlds/world_detail_members.dart';
import '../services/permission_service.dart';
import '../services/world_service.dart';
import '../services/legacy_service.dart';
import '../services/feature_flags.dart';
import '../state/event_provider.dart';
import '../utils/world_foundations.dart';
import '../utils/navigation.dart';

import '../widgets/core/fade_in.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/error_banner.dart';

import '../state/post_provider.dart';
import '../models/resident.dart';
import '../models/world.dart' show World;
import '../widgets/worlds/resource_vault.dart';
import '../widgets/worlds/world_share_card.dart';
import '../widgets/shared/share_button.dart';
import '../widgets/worlds/alliance_section.dart';
import '../widgets/worlds/chat_preview_panel.dart';

class WorldDetailScreen extends ConsumerStatefulWidget {
  final String worldId;

  const WorldDetailScreen({super.key, required this.worldId});

  @override
  ConsumerState<WorldDetailScreen> createState() => _WorldDetailScreenState();
}

class _WorldDetailScreenState extends ConsumerState<WorldDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _joinAnimController;
  TabController? _tabController;
  final GlobalKey _joinButtonKey = GlobalKey();

  List<WorldMemberEntry> _members = [];
  bool _membersLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  int _displayedMembers = 0;
  int _displayedPosts = 0;
  int _displayedEvents = 0;
  bool _statsAnimated = false;
  String? _highlightPostId;
  bool _appliedPostQuery = false;

  bool _isSovereignOrCouncil(Resident? resident, World world) {
    if (resident == null) return false;
    if (resident.id == world.sovereignId) return true;
    final member = _members.where((m) => m.resident.id == resident.id).firstOrNull;
    return member != null && member.rep >= 5000;
  }

  void _ensureTabController(int length) {
    if (_tabController == null || _tabController!.length != length) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
    }
  }

  @override
  void initState() {
    super.initState();
    _joinAnimController = AnimationController(
      duration: VAnimation.fast,
      vsync: this,
    );
    _loadMembers();
    _maybeAutoJoin();
    _runGovernanceChecks();
    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      ref.read(chatProvider.notifier).loadChannelReads(resident.id);
    }
  }

  void _maybeAutoJoin() {
    final worldState = ref.read(worldProvider);
    final world = worldState.worlds[widget.worldId];
    final resident = ref.read(residentProvider).resident;
    if (world == null || resident == null) return;
    final alreadyJoined = resident.joinedWorldIds.contains(widget.worldId);
    if (!alreadyJoined &&
        !resident.bannedWorldIds.contains('${widget.worldId}:${resident.id}')) {
      ref.read(channelProvider.notifier).loadChannels(widget.worldId);
    } else {
      ref.read(channelProvider.notifier).loadChannels(widget.worldId);
    }
  }

  Future<void> _loadMembers() async {
    try {
      final members = await WorldService.getMembers(widget.worldId);
      if (mounted) {
        setState(() {
          _members = members
              .map(
                (m) => WorldMemberEntry(
                  resident: Resident(
                    id: m['resident_id'] ?? '',
                    name: m['resident_name'] ?? 'Member',
                    avatarUrl: m['avatar_url'] ?? '',
                  ),
                  rep: m['rep'] ?? 0,
                ),
              )
              .toList();
          _membersLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _membersLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load world data';
        });
      }
    }
  }

  Future<void> _retryLoad() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _membersLoading = true;
    });
    await _loadMembers();
    await ref.read(postProvider.notifier).loadPosts();
  }

  void _runGovernanceChecks() {
    final worldNotifier = ref.read(worldProvider.notifier);
    worldNotifier.runCouncilCheck(widget.worldId);
  }

  void _startStatAnimation() {
    if (_statsAnimated) return;
    _statsAnimated = true;

    final world = ref.read(worldProvider).worlds[widget.worldId];
    final posts = ref
        .read(postProvider.notifier)
        .getPostsByWorld(widget.worldId);
    final events =
        ref.read(eventProvider).eventsByWorld[widget.worldId]?.length ?? 0;

    final targetMembers = world?.memberCount ?? 0;
    final targetPosts = posts.length;
    final targetEvents = events;

    const duration = VAnimation.slow;
    const steps = 20;
    final stepDuration = duration ~/ steps;

    for (var i = 1; i <= steps; i++) {
      Future.delayed(stepDuration * i, () {
        if (!mounted) return;
        setState(() {
          _displayedMembers = ((targetMembers * i) / steps).round();
          _displayedPosts = ((targetPosts * i) / steps).round();
          _displayedEvents = ((targetEvents * i) / steps).round();
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedPostQuery) return;
    _appliedPostQuery = true;
    final postId = GoRouterState.of(context).uri.queryParameters['post'];
    if (postId != null && postId.isNotEmpty) {
      _highlightPostId = postId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController?.animateTo(0);
      });
    }
  }

  @override
  void dispose() {
    _joinAnimController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _handleJoin() {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;
    final isJoined = resident.joinedWorldIds.contains(widget.worldId);
    if (isJoined) {
      _showLeaveConfirmation();
    } else {
      _animateJoinButton();
      ref.read(residentProvider.notifier).joinWorld(widget.worldId);
    }
  }

  void _animateJoinButton() {
    _joinAnimController.forward().then((_) {
      if (mounted) _joinAnimController.reverse();
    });
  }

  void _showLeaveConfirmation() {
    final world = ref.read(worldProvider).worlds[widget.worldId];
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Leave ${world?.name ?? widget.worldId}?'),
        content: const Text(
          'You will lose all your standing and rep in this world. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              _animateJoinButton();
              ref.read(residentProvider.notifier).leaveWorld(widget.worldId);
              Navigator.pop(ctx);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Color _getPrestigeTierColor(int prestige) {
    if (prestige >= 40) return VColors.tierApex;
    if (prestige >= 20) return VColors.primary;
    return VColors.tierHustler;
  }


  void _openChannelByName(String channelName, List<WorldChannel> channels) {
    final normalized = channelName.toLowerCase();
    final channel = channels
        .where((c) => c.name.toLowerCase() == normalized)
        .firstOrNull;
    if (channel == null) {
      ref.read(channelProvider.notifier).ensureDefaultChannels(widget.worldId);
      return;
    }
    context.push(
      '/explore/${widget.worldId}/${Uri.encodeComponent(channel.name)}'
      '?id=${Uri.encodeComponent(channel.id)}',
    );
  }

  void _showWorldShareSheet(World world) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShareButton(
              shareText: 'Join me in ${world.name} on Vertiege!',
              onShared: () => Navigator.of(ctx).pop(),
              child: WorldShareCard(world: world),
            ),
            const SizedBox(height: VSpacing.md),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worldState = ref.watch(worldProvider);
    final world = worldState.worlds[widget.worldId];
    final resident = ref.watch(residentProvider).resident;
    final posts = ref
        .watch(postProvider.notifier)
        .getPostsByWorld(widget.worldId);
    final channels =
        ref.watch(channelProvider).channelsByWorld[widget.worldId] ?? [];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isJoined = resident?.joinedWorldIds.contains(widget.worldId) ?? false;

    _ensureTabController(5); // Feed, Channels, People, Manage, More

    final scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _joinAnimController,
            curve: VAnimation.standard,
          ),
        );

    // â”€â”€ Loading state â”€â”€
    if (worldState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('World')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // â”€â”€ Error state â”€â”€
    if (_hasError && world == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('World')),
        body: ListView(
          padding: const EdgeInsets.all(VSpacing.md),
          children: [
            SovereignErrorBanner(
              message: _errorMessage ?? 'Failed to load world',
              onRetry: _retryLoad,
            ),
            const SizedBox(height: VSpacing.md),
            AppEmptyState(
              title: 'Could not load this world',
              description:
                  'Check your connection and try again. If this keeps happening, the world may have been removed.',
              icon: Icons.public_off,
              variant: EmptyStateVariant.error,
              actionLabel: 'Retry',
              onAction: _retryLoad,
            ),
          ],
        ),
      );
    }

    // â”€â”€ World not found â”€â”€
    if (world == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('World')),
        body: AppEmptyState(
          title: 'World not found',
          description: 'This world may have been removed.',
          icon: Icons.public_off,
          variant: EmptyStateVariant.error,
          actionLabel: 'Retry',
          onAction: _retryLoad,
        ),
      );
    }

    final tierLabel = world.requiredProfession != null
        ? world.requiredProfession!
        : (tierNames[world.requiredTier] ?? 'Open');

    // Prestige-based tier for hero glow, badge, and button colors
    final prestigeTierColor = _getPrestigeTierColor(world.prestige);
    final heroHeight = (MediaQuery.of(context).size.height * 0.28)
        .clamp(210.0, 300.0)
        .toDouble();

    final onSettings =
        resident != null &&
            WorldPermissions.canManageSettings(
              resident,
              widget.worldId,
              world.sovereignId,
            ) &&
            ref
                .read(worldProvider.notifier)
                .featuresForWorld(widget.worldId)
                .governance
        ? () => context.push('/explore/${widget.worldId}/settings')
        : null;

    return WorldAccessGuard(
      worldId: widget.worldId,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(postProvider.notifier).loadPosts();
            await ref
                .read(channelProvider.notifier)
                .ensureDefaultChannels(widget.worldId);
            await _loadMembers();
            _statsAnimated = false;
            await Future<void>.delayed(const Duration(milliseconds: 200));
          },
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // â”€â”€ Hero â€” Reddit-style collapsible header (pull to stretch) â”€â”€
              SliverAppBar(
                expandedHeight: heroHeight,
                pinned: true,
                stretch: true,
                backgroundColor:
                    isDark ? VColors.surfaceDark : VColors.surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () =>
                      safeBack(context, fallback: '/explore'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    tooltip: 'Share world',
                    onPressed: () => _showWorldShareSheet(world),
                  ),
                  if (onSettings != null)
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      tooltip: 'World settings',
                      onPressed: onSettings,
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: prestigeTierColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: prestigeTierColor.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Banner image
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: Hero(
                          tag: 'world-icon-${widget.worldId}',
                          child: WorldBanner(
                            worldId: world.id,
                            assetKey: world.assetKey,
                            width: double.infinity,
                            height: heroHeight,
                            worldType: world.type,
                            prestige: world.prestige,
                          ),
                        ),
                      ),
                      // Scrim so title/description stay readable on any banner
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.55),
                                Colors.black.withValues(alpha: 0.82),
                              ],
                              stops: const [0.35, 0.72, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Content overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(VSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tier badge â€” colored by prestige tier
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: VSpacing.md,
                                  vertical: VSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: prestigeTierColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    VRadius.md,
                                  ),
                                  border: Border.all(
                                    color: prestigeTierColor.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  world.requiredProfession != null
                                      ? tierLabel.toUpperCase()
                                      : 'TIER $tierLabel'.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: VFontSize.labelMd,
                                    fontWeight: VFontWeight.semiBold,
                                    color: prestigeTierColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: VSpacing.sm),
                              // World name + sovereign crown
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      world.name,
                                      style: const TextStyle(
                                        fontSize: VFontSize.headlineLg,
                                        fontWeight: VFontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black45,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: VSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: VSpacing.sm,
                                      vertical: VSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: VColors.tertiary,
                                      borderRadius: BorderRadius.circular(
                                        VRadius.pill,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: VColors.tertiary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                          Icon(
                                            Icons.shield,
                                            size: 12,
                                            color: VColors.onTertiary,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'SOVEREIGN',
                                            style: TextStyle(
                                              fontSize: VFontSize.labelMd,
                                              fontWeight: VFontWeight.bold,
                                              color: VColors.onTertiary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (world.description.trim().isNotEmpty) ...[
                                const SizedBox(height: VSpacing.xs),
                                Text(
                                  world.description.trim(),
                                  style: TextStyle(
                                    fontSize: VFontSize.bodyMd,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.3,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: VSpacing.lg),
                              // Action buttons â€” colored by prestige tier
                              Row(
                                children: [
                                  ScaleTransition(
                                    scale: scaleAnimation,
                                    child: AnimatedBuilder(
                                      animation: _joinAnimController,
                                      builder: (context, _) {
                                        // Determine foreground for tier button
                                        final btnBg = isJoined
                                            ? VColors.error
                                            : prestigeTierColor;
                                        final btnFg = isJoined
                                            ? VColors.onError
                                            : VColors.onPrimary;
                                        return FilledButton(
                                          key: _joinButtonKey,
                                          onPressed: _handleJoin,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: btnBg,
                                            foregroundColor: btnFg,
                                          ),
                                          child: Text(
                                            isJoined
                                                ? 'LEAVE WORLD'
                                                : 'JOIN WORLD',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),

              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: 60,
                  child: _WorldStatsStrip(
                    members: _displayedMembers,
                    posts: _displayedPosts,
                    events: _displayedEvents,
                    onVisible: _startStatAnimation,
                    onMembersTap: () => context.push(
                      '/explore/${widget.worldId}/members'
                      '?name=${Uri.encodeComponent(world.name)}'
                      '&sovereign=${Uri.encodeComponent(world.sovereignId)}',
                    ),
                  ),
                ),
              ),

              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate: _WorldTabBarDelegate(
                    controller: _tabController!,
                    color: prestigeTierColor,
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _WorldDetailTabScroll(
                  child: WorldFeedTab(
                    worldId: widget.worldId,
                    world: world,
                    resident: resident,
                    posts: posts,
                    cs: cs,
                    primaryScroll: true,
                    highlightPostId: _highlightPostId,
                  ),
                ),
                _WorldDetailTabScroll(
                  child: channels.isEmpty
                      ? AppEmptyState(
                          title: 'Preparing channels',
                          description:
                              'This world is getting its starter channels.',
                          icon: Icons.forum_outlined,
                          actionLabel: 'Retry',
                          onAction: () => ref
                              .read(channelProvider.notifier)
                              .ensureDefaultChannels(widget.worldId),
                        )
                      : WorldChannelList(worldId: widget.worldId),
                ),
                _WorldDetailTabScroll(
                  child: (!_membersLoading && _members.isEmpty)
                      ? const AppEmptyState(
                          title: 'No residents yet',
                          description:
                              'No residents have joined this world yet.',
                          icon: Icons.people_outline,
                          variant: EmptyStateVariant.default_,
                        )
                      : WorldDetailMembers(
                          worldId: widget.worldId,
                          world: world,
                          members: _members,
                          membersLoading: _membersLoading,
                        ),
                ),
                _WorldDetailTabScroll(
                  child: _ManageTab(
                    world: world,
                    worldId: widget.worldId,
                    isJoined: isJoined,
                  ),
                ),
                _WorldDetailTabScroll(
                  child: _MoreTab(
                    world: world,
                    worldId: widget.worldId,
                    channels: channels,
                    resident: resident,
                    isJoined: isJoined,
                    isSovereignOrCouncil:
                        _isSovereignOrCouncil(resident, world),
                    onOpenChannel: (name) =>
                        _openChannelByName(name, channels),
                    onSettings: onSettings,
                    onShare: () => _showWorldShareSheet(world),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab body that shares one outer scroll with the world hero + stats.
/// Single stats row (members / posts / events) â€” shown once below hero.
class _WorldStatsStrip extends StatefulWidget {
  final int members;
  final int posts;
  final int events;
  final VoidCallback onVisible;
  final VoidCallback onMembersTap;

  const _WorldStatsStrip({
    required this.members,
    required this.posts,
    required this.events,
    required this.onVisible,
    required this.onMembersTap,
  });

  @override
  State<_WorldStatsStrip> createState() => _WorldStatsStripState();
}

class _WorldStatsStripState extends State<_WorldStatsStrip> {
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_triggered && mounted) {
        _triggered = true;
        widget.onVisible();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        VSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.people_outline,
              value: '${widget.members}',
              label: 'Residents',
              onTap: widget.onMembersTap,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: _StatChip(
              icon: Icons.forum_outlined,
              value: '${widget.posts}',
              label: 'Posts',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: _StatChip(
              icon: Icons.event_available_outlined,
              value: '${widget.events}',
              label: 'Events',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FCard.raw(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: VSpacing.md,
            ),
            child: Column(
              children: [
                Icon(icon, size: VIconSize.md, color: VColors.primary),
                const SizedBox(height: VSpacing.xs),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: VFontSize.headlineSm,
                    fontWeight: VFontWeight.bold,
                    color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: VFontSize.labelMd,
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldDetailTabScroll extends StatelessWidget {
  final Widget child;

  const _WorldDetailTabScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WorldTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final Color color;

  const _WorldTabBarDelegate({
    required this.controller,
    required this.color,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? VColors.surfaceDark : VColors.surface;
    final dividerColor = isDark ? VColors.outlineDark : VColors.outline;
    final unselectedColor = isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;

    return ColoredBox(
      color: bgColor.withValues(alpha: 0.96),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: dividerColor),
            top: BorderSide(
              color: dividerColor.withValues(alpha: 0.6),
            ),
          ),
        ),
        child: TabBar(
          controller: controller,
          labelColor: color,
          unselectedLabelColor: unselectedColor,
          indicatorColor: color,
          labelStyle: TextStyle(
            fontSize: VFontSize.labelSm,
            fontWeight: VFontWeight.semiBold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: VFontSize.labelSm,
            fontWeight: VFontWeight.regular,
          ),
          tabs: const [
            Tab(text: 'FEED'),
            Tab(text: 'CHANNELS'),
            Tab(text: 'PEOPLE'),
            Tab(text: 'MANAGE'),
            Tab(text: 'MORE'),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _WorldTabBarDelegate oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.color != color;
  }
}

class _ManageTab extends ConsumerWidget {
  final World world;
  final String worldId;
  final bool isJoined;

  const _ManageTab({
    required this.world,
    required this.worldId,
    required this.isJoined,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showMarket = world.type.name == 'dominion' || world.prestige >= 30;
    final showTreasury = world.prestige >= 25;

    if (!isJoined) {
      return const AppEmptyState(
        title: 'Join to manage',
        description: 'Economy and world tools unlock after you join.',
        icon: Icons.lock_outline,
        variant: EmptyStateVariant.default_,
      );
    }

    final links = <FTileMixin>[
      if (FeatureFlags.treasury && showTreasury)
        VSectionTile(
          icon: Icons.account_balance_wallet,
          label: 'Treasury',
          onTap: () => context.push('/explore/$worldId/treasury'),
        ),
      if (FeatureFlags.marketplace && showMarket)
        VSectionTile(
          icon: Icons.storefront,
          label: 'Marketplace',
          onTap: () => context.push('/explore/$worldId/marketplace'),
        ),
      if (FeatureFlags.polls)
        VSectionTile(
          icon: Icons.how_to_vote,
          label: 'Polls',
          onTap: () => context.push('/explore/$worldId/polls'),
        ),
      if (FeatureFlags.challenges)
        VSectionTile(
          icon: Icons.emoji_events,
          label: 'World challenges',
          onTap: () => context.push('/explore/$worldId/challenges'),
        ),
    ];

    if (links.isEmpty) {
      return const AppEmptyState(
        title: 'Economy not available',
        description: 'No economy modules are enabled for this world yet.',
        icon: Icons.savings_outlined,
        variant: EmptyStateVariant.default_,
      );
    }

    final prestigeColor = world.prestige >= 40
        ? VColors.tierApex
        : world.prestige >= 20
        ? VColors.primary
        : VColors.tierHustler;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VSectionList(title: 'Economy & governance', children: links),
        const SizedBox(height: VSpacing.md),
        FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.md),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: prestigeColor),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: Text(
                    'Prestige ${world.prestige} Â· unlocks economy features',
                    style: TextStyle(
                      fontSize: VFontSize.bodySm,
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreTab extends ConsumerWidget {
  final World world;
  final String worldId;
  final List<WorldChannel> channels;
  final Resident? resident;
  final bool isJoined;
  final bool isSovereignOrCouncil;
  final ValueChanged<String> onOpenChannel;
  final VoidCallback? onSettings;
  final VoidCallback onShare;

  const _MoreTab({
    required this.world,
    required this.worldId,
    required this.channels,
    required this.resident,
    required this.isJoined,
    required this.isSovereignOrCouncil,
    required this.onOpenChannel,
    required this.onSettings,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = ref.read(worldProvider.notifier).featuresForWorld(worldId);
    final settingsTap = onSettings; // local capture for null promotion

    final foundation = foundationForWorld(world);
    final quickLinks = <FTileMixin>[
      VSectionTile(
        icon: Icons.share_outlined,
        label: 'Share world',
        onTap: onShare,
      ),
      if (isJoined)
        VSectionTile(
          icon: Icons.people_outline,
          label: 'Full resident roster',
          onTap: () => context.push(
            '/explore/$worldId/members'
            '?name=${Uri.encodeComponent(world.name)}'
            '&sovereign=${Uri.encodeComponent(world.sovereignId)}',
          ),
        ),
      if (settingsTap != null && features.governance)
        VSectionTile(
          icon: Icons.settings,
          label: 'World settings',
          onTap: settingsTap,
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: VSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontWeight: VFontWeight.bold,
                      fontSize: VFontSize.bodyLg,
                      color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Text(
                    foundation.premise,
                    style: TextStyle(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                      fontSize: VFontSize.bodyMd,
                      height: 1.35,
                    ),
                  ),
                  if (world.createdAt > 0) ...[
                    const SizedBox(height: VSpacing.sm),
                    Text(
                      LegacyService.formatFoundedDate(
                        DateTime.fromMillisecondsSinceEpoch(world.createdAt),
                      ),
                      style: TextStyle(
                        fontSize: VFontSize.labelMd,
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpacing.md),
          VSectionList(title: 'Social & links', children: quickLinks),
          const SizedBox(height: VSpacing.md),
          ResourceVault(
            worldId: worldId,
            channels: channels,
            vaultUnlocked: features.vault,
          ),
          const SizedBox(height: VSpacing.md),
          ChatPreviewPanel(worldId: worldId),
          const SizedBox(height: VSpacing.md),
          AllianceSection(worldId: worldId, world: world),
        ],
      ),
    );
  }
}
