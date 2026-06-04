import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../forui/v_hub_page.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../config/tiers.dart';
import '../config/world_page_ia.dart';
import '../models/channel.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../state/channel_provider.dart';
import '../state/chat_provider.dart';
import '../widgets/worlds/world_access_guard.dart';
import '../widgets/worlds/world_channel_list.dart';

import '../widgets/worlds/world_member_row.dart';
import '../widgets/worlds/world_hero_banner.dart';
import '../widgets/worlds/world_profile_header.dart';
import '../widgets/worlds/world_realm_dossier.dart';
import '../widgets/worlds/world_home_tab.dart';
import '../widgets/worlds/world_shop_tab.dart';
import '../widgets/worlds/world_tools_panel.dart';
import '../widgets/core/sync_warning_banner.dart';
import '../widgets/worlds/world_feed_tab.dart';
import '../widgets/core/glass_sheet.dart';
import '../widgets/worlds/world_detail_members.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/permission_service.dart';
import '../services/onboarding_funnel_prefs.dart';
import '../services/world_nav_prefs.dart';
import '../services/world_service.dart';
import '../state/event_provider.dart';
import '../router/world_navigation.dart';
import '../utils/navigation.dart';
import '../utils/v_motion.dart';

import '../widgets/core/fade_in.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';

import '../state/post_provider.dart';
import '../state/quest_provider.dart';
import '../models/post.dart';
import '../models/resident.dart';
import '../models/world.dart' show World;
import '../widgets/worlds/world_share_card.dart';
import '../widgets/shared/share_button.dart';
import '../widgets/core/v_feedback.dart';

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
  List<WorldDetailTabId> _tabIds = const [];

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
  bool _defaultTabApplied = false;
  bool _memberOpensOnFeed = true;
  bool _navPrefsLoaded = false;

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
    _loadNavPrefs();
    _runGovernanceChecks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeAutoJoin();
      OnboardingFunnelPrefs.markOpenedWorld();
      ref.read(questProvider.notifier).onWorldVisited();
      unawaited(
        AnalyticsService.logEvent(
          AnalyticsEvents.worldViewed,
          parameters: {'world_id': widget.worldId},
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        ref.read(chatProvider.notifier).loadChannelReads(resident.id);
      }
    });
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

    if (!mounted || !context.motionEnabled) {
      final world = ref.read(worldProvider).worlds[widget.worldId];
      final posts = ref
          .read(postProvider.notifier)
          .getPostsByWorld(widget.worldId);
      final events =
          ref.read(eventProvider).eventsByWorld[widget.worldId]?.length ?? 0;
      setState(() {
        _displayedMembers = world?.memberCount ?? 0;
        _displayedPosts = posts.length;
        _displayedEvents = events;
      });
      return;
    }

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
  void didUpdateWidget(WorldDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worldId != widget.worldId) {
      _defaultTabApplied = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedPostQuery) return;
    _appliedPostQuery = true;
    final query = GoRouterState.of(context).uri.queryParameters;
    final postId = query['post'] ?? query['highlight'];
    if (postId != null && postId.isNotEmpty) {
      _highlightPostId = postId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final w = ref.read(worldProvider).worlds[widget.worldId];
        if (w == null || _tabController == null) return;
        final duration = context.motionDuration(VAnimation.normal);
        _tabController!.animateTo(
          WorldPageIa.feedIndex(w),
          duration: duration,
        );
      });
    }
  }

  Future<void> _loadNavPrefs() async {
    final opensOnFeed = await WorldNavPrefs.memberOpensOnFeed();
    if (!mounted) return;
    setState(() {
      _memberOpensOnFeed = opensOnFeed;
      _navPrefsLoaded = true;
    });
  }

  void _applyDefaultTabIfNeeded(World world, bool isJoined) {
    if (_defaultTabApplied || _tabController == null || !_navPrefsLoaded) {
      return;
    }
    final hasPost =
        _highlightPostId != null && _highlightPostId!.isNotEmpty;
    final index = WorldPageIa.defaultTabIndex(
      world: world,
      isJoined: isJoined,
      hasPostHighlight: hasPost,
      memberOpensOnFeed: _memberOpensOnFeed,
    );
    _defaultTabApplied = true;
    if (_tabController!.index == index) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabController == null) return;
      _tabController!.animateTo(index);
    });
  }

  void _goToTab(World world, WorldDetailTabId id) {
    final index = WorldPageIa.indexOf(world, id);
    if (index < 0 || _tabController == null) return;
    _tabController!.animateTo(index);
  }

  void _openToolsSheet(
    World world, {
    required bool isJoined,
    required bool isAdminOrCouncil,
    required VoidCallback? onSettings,
  }) {
    showAppSheet(
      context,
      WorldToolsPanel(
        world: world,
        worldId: widget.worldId,
        isJoined: isJoined,
        isAdminOrCouncil: isAdminOrCouncil,
        onDismiss: () => Navigator.pop(context),
        onShare: () => _showWorldShareSheet(world),
        onSettings: onSettings,
        onOpenRealmGuide: () => _showRealmGuideSheet(
          world,
          channels: ref.read(channelProvider).channelsByWorld[widget.worldId] ?? [],
          posts: ref.read(postProvider.notifier).getPostsByWorld(widget.worldId),
          resident: ref.read(residentProvider).resident,
          isJoined: isJoined,
          onSettings: onSettings,
        ),
      ),
      maxSize: 0.92,
    );
  }

  Widget _buildTabBody(
    WorldDetailTabId tabId, {
    required World world,
    required Resident? resident,
    required List<Post> posts,
    required List<WorldChannel> channels,
    required ColorScheme cs,
    required bool isJoined,
    required VoidCallback? onSettings,
  }) {
    switch (tabId) {
      case WorldDetailTabId.home:
        return WorldHomeTab(
          world: world,
          worldId: widget.worldId,
          worldPosts: posts,
          isJoined: isJoined,
          onOpenFeed: () => _goToTab(world, WorldDetailTabId.feed),
          onOpenRealmGuide: () => _showRealmGuideSheet(
            world,
            channels: channels,
            posts: posts,
            resident: resident,
            isJoined: isJoined,
            onSettings: onSettings,
          ),
        );
      case WorldDetailTabId.feed:
        return WorldFeedTab(
          worldId: widget.worldId,
          world: world,
          resident: resident,
          posts: posts,
          cs: cs,
          primaryScroll: true,
          highlightPostId: _highlightPostId,
          isJoined: isJoined,
          onJoin: _handleJoin,
          onHighlightMissing: _onHighlightPostMissing,
          channels: channels,
        );
      case WorldDetailTabId.channels:
        return channels.isEmpty
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
            : WorldChannelList(worldId: widget.worldId);
      case WorldDetailTabId.members:
        return (!_membersLoading && _members.isEmpty)
            ? AppEmptyState(
                title: 'No members yet',
                description: isJoined
                    ? 'Invite people who match this world\'s culture.'
                    : 'Join to meet members and join the conversation.',
                icon: Icons.people_outline,
                actionLabel: isJoined ? 'Invite members' : 'Join world',
                onAction: isJoined
                    ? () => context.push('/search')
                    : _handleJoin,
              )
            : WorldDetailMembers(
                worldId: widget.worldId,
                world: world,
                members: _members,
                membersLoading: _membersLoading,
              );
      case WorldDetailTabId.shop:
        return WorldShopTab(
          world: world,
          worldId: widget.worldId,
          isJoined: isJoined,
        );
    }
  }

  void _showRealmGuideSheet(
    World world, {
    required List<WorldChannel> channels,
    required List<Post> posts,
    required Resident? resident,
    required bool isJoined,
    required VoidCallback? onSettings,
  }) {
    showAppSheet(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.md,
          VSpacing.sm,
          VSpacing.md,
          VSpacing.xl,
        ),
        child: WorldRealmDossier(
          world: world,
          worldId: widget.worldId,
          channels: channels,
          worldPosts: posts,
          resident: resident,
          isJoined: isJoined,
          isSovereignOrCouncil: _isSovereignOrCouncil(resident, world),
          onJoin: _handleJoin,
          onSettings: onSettings,
          onShare: () => _showWorldShareSheet(world),
          onOpenChannel: (name) => _openChannelByName(name, channels),
          members: _members,
          membersLoading: _membersLoading,
        ),
      ),
      maxSize: 0.92,
    );
  }

  void _onHighlightPostMissing() {
    if (!mounted) return;
    setState(() => _highlightPostId = null);
    VFeedback.showMessage(context, 'That post is no longer available.');
  }

  @override
  void dispose() {
    _joinAnimController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;
    final isJoined = resident.joinedWorldIds.contains(widget.worldId);
    if (isJoined) {
      _showLeaveConfirmation();
      return;
    }
    _animateJoinButton();
    await ref.read(residentProvider.notifier).joinWorld(widget.worldId);
    if (!mounted) return;
    final world = ref.read(worldProvider).worlds[widget.worldId];
    if (world == null) return;
    await _maybePromptFeedDefault(world);
    if (!mounted) return;
    setState(() => _defaultTabApplied = false);
    _applyDefaultTabIfNeeded(world, true);
  }

  Future<void> _maybePromptFeedDefault(World world) async {
    if (await WorldNavPrefs.hasAskedFeedDefault()) return;
    if (!mounted) return;

    final openFeed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog.raw(
        builder: (context, dialogStyle) => Padding(
          padding: const EdgeInsets.all(VSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'You joined ${world.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              const Text(
                'When you open worlds you\'ve joined, start on the Feed tab? '
                'You can change this anytime in Settings.',
              ),
              const SizedBox(height: VSpacing.lg),
              FButton(
                onPress: () => Navigator.pop(ctx, true),
                child: const Text('Yes, open on Feed'),
              ),
              const SizedBox(height: VSpacing.sm),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Start on Home instead'),
              ),
            ],
          ),
        ),
      ),
    );

    final preferFeed = openFeed ?? true;
    await WorldNavPrefs.setMemberOpensOnFeed(preferFeed);
    if (!mounted) return;
    setState(() {
      _memberOpensOnFeed = preferFeed;
      _defaultTabApplied = false;
    });
    if (preferFeed) {
      _goToTab(world, WorldDetailTabId.feed);
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
      worldChannelDestinationPath(
        widget.worldId,
        channel,
        worldName: ref.read(worldProvider).worlds[widget.worldId]?.name,
      ),
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

    if (world != null) {
      final nextTabs = WorldPageIa.tabsFor(world);
      if (_tabIds != nextTabs) {
        _tabIds = nextTabs;
        _defaultTabApplied = false;
      }
      _ensureTabController(nextTabs.length);
      _applyDefaultTabIfNeeded(world, isJoined);
    }

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
      return const VHubPage(
        title: 'World',
        showBack: true,
        body: ScreenLoading.detail(),
      );
    }

    if (_hasError && world == null) {
      return VHubPage(
        title: 'World',
        showBack: true,
        body: AppErrorState(
          message: _errorMessage ?? 'Failed to load world',
          onRetry: _retryLoad,
        ),
      );
    }

    if (world == null) {
      return VHubPage(
        title: 'World',
        showBack: true,
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
        ? () => context.push(worldSettingsPath(widget.worldId))
        : null;

    final tabLabels = WorldPageIa.tabsFor(world).map(WorldPageIa.tabLabel).toList();
    final isAdminOrCouncil = _isSovereignOrCouncil(resident, world);

    return WorldAccessGuard(
      worldId: widget.worldId,
      child: FScaffold(
        childPad: false,
        child: RefreshIndicator(
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
              WorldHeroBanner(
                world: world,
                isDark: isDark,
                prestigeTierColor: prestigeTierColor,
                isJoined: isJoined,
                innerBoxIsScrolled: innerBoxIsScrolled,
                scaleAnimation: scaleAnimation,
                joinButtonKey: _joinButtonKey,
                onBack: () => safeBack(context, fallback: '/explore'),
                onShare: () => _showWorldShareSheet(world),
                onSettings: onSettings,
                onOpenTools: () => _openToolsSheet(
                  world,
                  isJoined: isJoined,
                  isAdminOrCouncil: isAdminOrCouncil,
                  onSettings: onSettings,
                ),
                onJoin: _handleJoin,
              ),
              if (worldState.loadError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VSpacing.md,
                      VSpacing.sm,
                      VSpacing.md,
                      0,
                    ),
                    child: SyncWarningBanner(
                      message: worldState.loadError!,
                      onRetry: () =>
                          ref.read(worldProvider.notifier).loadWorlds(),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: context.motionEnabled ? 40 : 0,
                  child: WorldProfileHeader(
                    world: world,
                    worldId: widget.worldId,
                    prestigeTierColor: prestigeTierColor,
                    tierLabel: tierLabel,
                    isJoined: isJoined,
                    scaleAnimation: scaleAnimation,
                    joinButtonKey: _joinButtonKey,
                    onJoin: _handleJoin,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: context.motionEnabled ? 60 : 0,
                  child: _WorldStatsStrip(
                    members: _displayedMembers,
                    posts: _displayedPosts,
                    events: _displayedEvents,
                    onVisible: _startStatAnimation,
                    onMembersTap: () => context.push(
                      worldMembersPath(
                        widget.worldId,
                        worldName: world.name,
                        sovereignId: world.sovereignId,
                      ),
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
                    tabLabels: tabLabels,
                  ),
                ),
              ),
            ],
            body: AnimatedBuilder(
              animation: _tabController!,
              builder: (context, _) {
                final tabIds = WorldPageIa.tabsFor(world);
                final tabId = tabIds[_tabController!.index];
                return Builder(
                  builder: (context) {
                    return CustomScrollView(
                      key: PageStorageKey('world_tab_${tabId.name}'),
                      slivers: [
                        SliverOverlapInjector(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                            context,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: VSpacing.md,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTabBody(
                                  tabId,
                                  world: world,
                                  resident: resident,
                                  posts: posts,
                                  channels: channels,
                                  cs: cs,
                                  isJoined: isJoined,
                                  onSettings: onSettings,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
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
        child: Semantics(
          button: onTap != null,
          label: onTap != null ? '$label, $value' : null,
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
      ),
    );
  }
}

class _WorldTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final Color color;
  final List<String> tabLabels;

  const _WorldTabBarDelegate({
    required this.controller,
    required this.color,
    required this.tabLabels,
  });

  /// Room for [TabBar] plus top/bottom divider lines without sliver overflow.
  static const double _tabBarHeight = 52;

  @override
  double get minExtent => _tabBarHeight;

  @override
  double get maxExtent => _tabBarHeight;

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

    return SizedBox(
      height: _tabBarHeight,
      child: ColoredBox(
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
              for (final label in tabLabels) Tab(text: label),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _WorldTabBarDelegate oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.color != color ||
        oldDelegate.tabLabels != tabLabels;
  }
}
