import 'package:flutter/material.dart';
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

import '../widgets/worlds/world_info_cards.dart';
import '../widgets/worlds/world_feed_tab.dart';
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

    _ensureTabController(4); // Feed, Channels, Residents, More

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

    // ── Loading state ──
    if (worldState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('World')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ── Error state ──
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

    // ── World not found ──
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
          child: CustomScrollView(
            slivers: [
              // ── Hero Section — Full-bleed banner with tier glow ──
              SliverToBoxAdapter(
                child: Container(
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
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + VSpacing.sm,
                        left: VSpacing.sm,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: VIconSize.lg,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          onPressed: () =>
                              safeBack(context, fallback: '/explore'),
                        ),
                      ),
                      // Share button (top-right, left of settings)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + VSpacing.sm,
                        right: (onSettings != null ? 56.0 : VSpacing.sm),
                        child: IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: VIconSize.lg,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          tooltip: 'Share world',
                          onPressed: () => _showWorldShareSheet(world),
                        ),
                      ),
                      // Settings gear (top-right)
                      if (onSettings != null)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + VSpacing.sm,
                          right: VSpacing.sm,
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: VIconSize.lg,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            tooltip: 'World settings',
                            onPressed: onSettings,
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
                              // Tier badge — colored by prestige tier
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
                              const SizedBox(height: VSpacing.xs),
                              // Description
                              Text(
                                world.description,
                                style: TextStyle(
                                  fontSize: VFontSize.bodyMd,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.35,
                                  shadows: const [
                                    Shadow(color: Colors.black38, blurRadius: 6),
                                  ],
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Prestige progress bar
                              const SizedBox(height: VSpacing.sm),
                              _PrestigeProgressBar(
                                prestige: world.prestige,
                                tierColor: prestigeTierColor,
                                isDark: isDark,
                              ),
                              // Founded date (legacy)
                              if (world.createdAt > 0) ...[
                                const SizedBox(height: VSpacing.sm),
                                Text(
                                  LegacyService.formatFoundedDate(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      world.createdAt,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: VFontSize.labelMd,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: VSpacing.lg),
                              // Action buttons — colored by prestige tier
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

              // ── Bento Info Cards — GlassPanel stat cards ──
              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: 60,
                  child: WorldInfoCards(
                    world: world,
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

              // ── Live Chat Preview ──
              SliverPersistentHeader(
                pinned: true,
                delegate: _WorldTabBarDelegate(
                  controller: _tabController!,
                  color: prestigeTierColor,
                ),
              ),

              // ── Tab Content ──
              SliverFillRemaining(
                hasScrollBody: false,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Feed tab
                    WorldFeedTab(
                      worldId: widget.worldId,
                      world: world,
                      resident: resident,
                      posts: posts,
                      cs: cs,
                    ),
                    // Channels tab: list or empty
                    channels.isEmpty
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
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(VSpacing.md),
                            physics: const ClampingScrollPhysics(),
                            child: WorldChannelList(worldId: widget.worldId),
                          ),
                    // Residents tab
                    (!_membersLoading && _members.isEmpty)
                        ? const AppEmptyState(
                            title: 'No residents yet',
                            description:
                                'No residents have joined this world yet.',
                            icon: Icons.people_outline,
                            variant: EmptyStateVariant.default_,
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(VSpacing.md),
                            physics: const ClampingScrollPhysics(),
                            child: WorldDetailMembers(
                              worldId: widget.worldId,
                              world: world,
                              members: _members,
                              membersLoading: _membersLoading,
                            ),
                          ),
                    // More tab
                    _MoreTab(
                      world: world,
                      worldId: widget.worldId,
                      channels: channels,
                      resident: resident,
                      isJoined: isJoined,
                      isSovereignOrCouncil: _isSovereignOrCouncil(resident, world),
                      onOpenChannel: (name) =>
                          _openChannelByName(name, channels),
                      onSettings: onSettings,
                      onShare: () => _showWorldShareSheet(world),
                      prestigeTierColor: prestigeTierColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            Tab(text: 'RESIDENTS'),
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
  final Color prestigeTierColor;

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
    required this.prestigeTierColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = ref.read(worldProvider.notifier).featuresForWorld(worldId);
    final showMarket = world.type.name == 'dominion' || world.prestige >= 30;
    final showTreasury = world.prestige >= 25;
    final settingsTap = onSettings; // local capture for null promotion

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foundation card
          _FoundationCard(world: world),
          const SizedBox(height: VSpacing.md),
          // Guide card
          _GuideCard(
            world: world,
            channels: channels,
            onOpenChannel: onOpenChannel,
          ),
          const SizedBox(height: VSpacing.md),
          // Quick links
          _SectionHeader(title: 'Quick Links', isDark: isDark),
          const SizedBox(height: VSpacing.sm),
          if (isJoined)
            _MoreLink(
              icon: Icons.people_outline,
              label: 'Residents',
              onTap: () => context.push(
                '/explore/$worldId/members'
                '?name=${Uri.encodeComponent(world.name)}'
                '&sovereign=${Uri.encodeComponent(world.sovereignId)}',
              ),
            ),
          if (settingsTap != null && features.governance)
            _MoreLink(
              icon: Icons.settings,
              label: 'World Settings',
              onTap: settingsTap,
            ),
          _MoreLink(
            icon: Icons.share_outlined,
            label: 'Share World',
            onTap: onShare,
          ),
          if (FeatureFlags.marketplace && showMarket && isJoined)
            _MoreLink(
              icon: Icons.storefront,
              label: 'Marketplace',
              onTap: () => context.push('/explore/$worldId/marketplace'),
            ),
          if (FeatureFlags.polls && isJoined)
            _MoreLink(
              icon: Icons.how_to_vote,
              label: 'Polls',
              onTap: () => context.push('/explore/$worldId/polls'),
            ),
          if (FeatureFlags.treasury && showTreasury && isJoined)
            _MoreLink(
              icon: Icons.account_balance_wallet,
              label: 'Treasury',
              onTap: () => context.push('/explore/$worldId/treasury'),
            ),
          if (FeatureFlags.challenges && isJoined)
            _MoreLink(
              icon: Icons.emoji_events,
              label: 'Challenges',
              onTap: () => context.push('/explore/$worldId/challenges'),
            ),
          const SizedBox(height: VSpacing.md),
          // World info section
          _SectionHeader(title: 'World Info', isDark: isDark),
          const SizedBox(height: VSpacing.sm),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: VFontSize.labelSm,
        fontWeight: VFontWeight.semiBold,
        color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MoreLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, size: VIconSize.md, color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant),
      title: Text(label, style: TextStyle(fontSize: VFontSize.bodyMd)),
      trailing: const Icon(Icons.chevron_right, size: VIconSize.sm),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _FoundationCard extends StatelessWidget {
  final World world;

  const _FoundationCard({required this.world});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foundation = foundationForWorld(world);

    return Container(
      padding: const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.xl),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: VColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VRadius.lg),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: VColors.tertiary,
                  size: VIconSize.md,
                ),
              ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foundation',
                      style: TextStyle(
                        color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                        fontWeight: VFontWeight.bold,
                        fontSize: VFontSize.bodyLg,
                      ),
                    ),
                    Text(
                      _accessLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                        fontSize: VFontSize.labelMd,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            foundation.premise,
            style: TextStyle(
              color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
              fontSize: VFontSize.bodyMd,
              height: 1.35,
            ),
          ),
          if (foundation.focus.isNotEmpty) ...[
            const SizedBox(height: VSpacing.md),
            Wrap(
              spacing: VSpacing.xs,
              runSpacing: VSpacing.xs,
              children: [
                for (final item in foundation.focus.take(3))
                  _FoundationChip(label: item),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String get _accessLabel {
    if (world.requiredProfession != null) {
      return 'Verified ${world.requiredProfession} world';
    }
    return 'Tier ${world.requiredTier} ${tierNames[world.requiredTier] ?? 'access'}';
  }
}

class _GuideCard extends StatelessWidget {
  final World world;
  final List<WorldChannel> channels;
  final ValueChanged<String> onOpenChannel;

  const _GuideCard({
    required this.world,
    required this.channels,
    required this.onOpenChannel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final guideChannels = _guideChannels;

    return Container(
      padding: const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.xl),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guide',
            style: TextStyle(
              color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
              fontWeight: VFontWeight.bold,
              fontSize: VFontSize.bodyLg,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'Start here to learn about this world.',
            style: TextStyle(
              color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
              fontSize: VFontSize.labelMd,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          Row(
            children: [
              for (final channel in guideChannels)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: channel == guideChannels.last ? 0 : VSpacing.sm,
                    ),
                    child: _GuideButton(
                      label: channel.name,
                      icon: _iconForChannel(channel.name),
                      onTap: () => onOpenChannel(channel.name),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onOpenChannel('general'),
              icon: const Icon(Icons.forum_outlined, size: VIconSize.sm),
              label: const Text('Open General Discussion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: VColors.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<WorldChannel> get _guideChannels {
    const names = {'info', 'rules', 'roles'};
    final result =
        channels
            .where((channel) => names.contains(channel.name.toLowerCase()))
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    if (result.isNotEmpty) return result;
    return const [
      WorldChannel(id: 'info', worldId: '', name: 'info'),
      WorldChannel(id: 'rules', worldId: '', name: 'rules'),
      WorldChannel(id: 'roles', worldId: '', name: 'roles'),
    ];
  }

  IconData _iconForChannel(String name) => switch (name.toLowerCase()) {
    'info' => Icons.info_outline,
    'rules' => Icons.gavel_outlined,
    'roles' => Icons.badge_outlined,
    _ => Icons.tag,
  };
}

class _FoundationChip extends StatelessWidget {
  final String label;

  const _FoundationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: VSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: (isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
          fontSize: VFontSize.labelMd,
          fontWeight: VFontWeight.semiBold,
        ),
      ),
    );
  }
}

class _GuideButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GuideButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.xs,
          vertical: VSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: VColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(VRadius.md),
          border: Border.all(color: VColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: VColors.primary, size: VIconSize.md),
            const SizedBox(height: VSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                fontSize: VFontSize.labelMd,
                fontWeight: VFontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrestigeProgressBar extends StatelessWidget {
  final int prestige;
  final Color tierColor;
  final bool isDark;

  const _PrestigeProgressBar({required this.prestige, required this.tierColor, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    const thresholds = [5, 15, 25, 40, 55];
    int currentLevel = 0;
    int nextThreshold = thresholds.first;
    for (int i = 0; i < thresholds.length; i++) {
      if (prestige >= thresholds[i]) {
        currentLevel = i + 1;
        nextThreshold = i + 1 < thresholds.length ? thresholds[i + 1] : thresholds.last + 15;
      } else {
        nextThreshold = thresholds[i];
        break;
      }
    }
    final prevThreshold = currentLevel > 0 ? thresholds[currentLevel - 1] : 0;
    final range = nextThreshold - prevThreshold;
    final progress = range > 0 ? ((prestige - prevThreshold) / range).clamp(0.0, 1.0) : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prestige $prestige',
              style: TextStyle(fontSize: VFontSize.labelMd, fontWeight: VFontWeight.semiBold, color: tierColor),
            ),
            if (currentLevel < thresholds.length)
              Text(
                'Next: $nextThreshold',
                style: TextStyle(fontSize: VFontSize.labelMd, color: (isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant).withValues(alpha: 0.7)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.sm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: (isDark ? VColors.surfaceContainerHighestDark : VColors.surfaceContainerHighest).withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(tierColor),
          ),
        ),
      ],
    );
  }
}
