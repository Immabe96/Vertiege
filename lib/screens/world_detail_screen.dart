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
import '../widgets/worlds/chat_preview_panel.dart';
import '../widgets/worlds/alliance_section.dart';
import '../services/permission_service.dart';
import '../services/world_service.dart';
import '../services/legacy_service.dart';
import '../state/event_provider.dart';
import '../utils/world_foundations.dart';
import '../utils/navigation.dart';

import '../widgets/core/fade_in.dart';
import '../widgets/core/loading_state.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/error_banner.dart';

import '../state/post_provider.dart';
import '../models/resident.dart';
import '../models/world.dart' show World;
import '../widgets/worlds/resource_vault.dart';
import '../widgets/worlds/world_share_card.dart';
import '../widgets/shared/share_button.dart';
import '../screens/world_marketplace_screen.dart';
import '../screens/world_polls_screen.dart';
import '../screens/world_treasury_screen.dart';
import '../screens/world_challenges_screen.dart';

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

  bool _shouldShowMarketTab(World? world) {
    if (world == null) return false;
    return world.type.name == 'dominion' || world.prestige >= 30;
  }

  bool _shouldShowPollsTab(World? world, Resident? resident) {
    if (world == null || resident == null) return false;
    return resident.joinedWorldIds.contains(widget.worldId);
  }

  bool _shouldShowTreasuryTab(World? world) {
    if (world == null) return false;
    return world.prestige >= 25;
  }

  bool _shouldShowChallengesTab(World? world, Resident? resident) {
    if (world == null || resident == null) return false;
    return resident.joinedWorldIds.contains(widget.worldId);
  }

  bool _isSovereignOrCouncil(Resident? resident, World world) {
    if (resident == null) return false;
    if (resident.id == world.sovereignId) return true;
    final member = _members.where((m) => m.resident.id == resident.id).firstOrNull;
    return member != null && member.rep >= 5000;
  }

  int _getTabCount(World? world, ResidentState residentState) {
    int count = 4; // Info, Feed, Channels, Residents
    if (_shouldShowMarketTab(world)) count++;
    if (_shouldShowPollsTab(world, residentState.resident)) count++;
    if (_shouldShowTreasuryTab(world)) count++;
    if (_shouldShowChallengesTab(world, residentState.resident)) count++;
    return count;
  }

  int _computeTabCount(WorldState ws, ResidentState rs) => _getTabCount(
    ws.worlds[widget.worldId],
    rs,
  );

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

    final tabCount = _computeTabCount(worldState, ref.watch(residentProvider));
    _ensureTabController(tabCount);

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
        body: const GlassLoadingList(itemCount: 3),
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
                      // Subtle bottom scrim for text readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                (isDark ? VColors.surfaceDark : VColors.surface)
                                    .withValues(alpha: 0.3),
                              ],
                              stops: const [0.85, 1.0],
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
                                      style: TextStyle(
                                        fontSize: VFontSize.headlineLg,
                                        fontWeight: VFontWeight.bold,
                                        color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
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
                                  fontSize: VFontSize.bodyLg,
                                  color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                                ),
                                maxLines: 2,
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
                                    color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
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
                  showMarketTab: _shouldShowMarketTab(world),
                  showPollsTab: _shouldShowPollsTab(world, resident),
                  showTreasuryTab: _shouldShowTreasuryTab(world),
                  showChallengesTab: _shouldShowChallengesTab(world, resident),
                ),
              ),

              // ── Tab Content ──
              SliverFillRemaining(
                hasScrollBody: false,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Info tab: foundation, vault, chat, alliances
                    SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _WorldFoundationSummary(
                            world: world,
                            channels: channels,
                            onOpenChannel: (name) =>
                                _openChannelByName(name, channels),
                          ),
                          ResourceVault(
                            worldId: widget.worldId,
                            channels: channels,
                            vaultUnlocked: ref
                                .read(worldProvider.notifier)
                                .featuresForWorld(widget.worldId)
                                .vault,
                          ),
                          ChatPreviewPanel(worldId: widget.worldId),
                          AllianceSection(
                              worldId: widget.worldId, world: world),
                        ],
                      ),
                    ),
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
                    // Resients tab
                    (!_membersLoading && _members.isEmpty)
                        ? const AppEmptyState(
                            title: 'No content',
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
                    if (_shouldShowMarketTab(world))
                      WorldMarketplaceScreen(
                        worldId: widget.worldId,
                        isMember: isJoined,
                      ),
                    if (_shouldShowPollsTab(world, resident))
                      WorldPollsScreen(
                        worldId: widget.worldId,
                        isSovereignOrCouncil: _isSovereignOrCouncil(resident, world),
                      ),
                    if (_shouldShowTreasuryTab(world))
                      WorldTreasuryScreen(
                        worldId: widget.worldId,
                        isSovereignOrCouncil: _isSovereignOrCouncil(resident, world),
                      ),
                    if (_shouldShowChallengesTab(world, resident))
                      WorldChallengesScreen(
                        worldId: widget.worldId,
                        isSovereignOrCouncil: _isSovereignOrCouncil(resident, world),
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
  final bool showMarketTab;
  final bool showPollsTab;
  final bool showTreasuryTab;
  final bool showChallengesTab;

  const _WorldTabBarDelegate({
    required this.controller,
    required this.color,
    this.showMarketTab = false,
    this.showPollsTab = false,
    this.showTreasuryTab = false,
    this.showChallengesTab = false,
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
          tabs: [
            const Tab(text: 'INFO'),
            const Tab(text: 'FEED'),
            const Tab(text: 'CHANNELS'),
            const Tab(text: 'RESIDENTS'),
            if (showMarketTab) const Tab(text: 'MARKET'),
            if (showPollsTab) const Tab(text: 'POLLS'),
            if (showTreasuryTab) const Tab(text: 'TREASURY'),
            if (showChallengesTab) const Tab(text: 'CHALLENGES'),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _WorldTabBarDelegate oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.color != color ||
        oldDelegate.showMarketTab != showMarketTab ||
        oldDelegate.showPollsTab != showPollsTab ||
        oldDelegate.showTreasuryTab != showTreasuryTab ||
        oldDelegate.showChallengesTab != showChallengesTab;
  }
}

class _WorldFoundationSummary extends StatelessWidget {
  final World world;
  final List<WorldChannel> channels;
  final ValueChanged<String> onOpenChannel;

  const _WorldFoundationSummary({
    required this.world,
    required this.channels,
    required this.onOpenChannel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foundation = foundationForWorld(world);
    final guideChannels = _guideChannels;

    return Padding(
      padding: const EdgeInsets.fromLTRB(VSpacing.md, 0, VSpacing.md, VSpacing.sm),
      child: Container(
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
                        'World Foundation',
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
            const SizedBox(height: VSpacing.md),
            Wrap(
              spacing: VSpacing.xs,
              runSpacing: VSpacing.xs,
              children: [
                for (final item in foundation.focus.take(3))
                  _FoundationChip(label: item),
              ],
            ),
            const SizedBox(height: VSpacing.lg),
            Text(
              'World Guide',
              style: TextStyle(
                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                fontWeight: VFontWeight.bold,
                fontSize: VFontSize.bodyMd,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
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
                  side: BorderSide(color: isDark ? VColors.glassBorderDark : VColors.glassBorder),
                ),
              ),
            ),
          ],
        ),
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

  String get _accessLabel {
    if (world.requiredProfession != null) {
      return 'Verified ${world.requiredProfession} world';
    }
    return 'Tier ${world.requiredTier} ${tierNames[world.requiredTier] ?? 'access'}';
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
        border: Border.all(color: isDark ? VColors.glassBorderDark : VColors.glassBorder),
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
