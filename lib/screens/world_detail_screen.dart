import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../forui/v_hub_page.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../config/tiers.dart';
import '../config/world_capability_matrix.dart';
import '../models/channel.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../state/channel_provider.dart';
import '../state/chat_provider.dart';
import '../widgets/worlds/world_access_guard.dart';
import '../widgets/worlds/world_channel_list.dart';

import '../widgets/worlds/world_member_row.dart';
import '../widgets/worlds/world_hero_banner.dart';
import '../widgets/worlds/world_realm_dossier.dart';

import '../widgets/worlds/world_feed_tab.dart';
import '../widgets/v_section_list.dart';
import '../widgets/worlds/world_detail_members.dart';
import '../services/permission_service.dart';
import '../services/world_service.dart';
import '../services/feature_flags.dart';
import '../state/event_provider.dart';
import '../router/world_navigation.dart';
import '../utils/navigation.dart';
import '../utils/v_motion.dart';

import '../widgets/core/fade_in.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';

import '../state/post_provider.dart';
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
        final duration = context.motionDuration(VAnimation.normal);
        _tabController?.animateTo(0, duration: duration);
      });
    }
  }

  void _applyDefaultTabIfNeeded(bool isJoined) {
    if (_defaultTabApplied || _tabController == null) return;
    final hasPost =
        _highlightPostId != null && _highlightPostId!.isNotEmpty;
    if (hasPost) {
      _defaultTabApplied = true;
      return;
    }
    final index = isJoined ? 0 : 4;
    _defaultTabApplied = true;
    if (_tabController!.index == index) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabController == null) return;
      _tabController!.animateTo(index);
    });
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
    context.push(worldChannelPath(widget.worldId, channel));
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

    _ensureTabController(5); // Feed, Channels, People, Manage, About
    _applyDefaultTabIfNeeded(isJoined);

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
        ? () => context.push(worldSettingsPath(widget.worldId))
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
              WorldHeroBanner(
                worldId: widget.worldId,
                world: world,
                expandedHeight: heroHeight,
                isDark: isDark,
                prestigeTierColor: prestigeTierColor,
                tierLabel: tierLabel,
                isJoined: isJoined,
                innerBoxIsScrolled: innerBoxIsScrolled,
                scaleAnimation: scaleAnimation,
                joinAnimController: _joinAnimController,
                joinButtonKey: _joinButtonKey,
                onBack: () => safeBack(context, fallback: '/explore'),
                onShare: () => _showWorldShareSheet(world),
                onSettings: onSettings,
                onJoin: _handleJoin,
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
                    isJoined: isJoined,
                    onJoin: _handleJoin,
                    onHighlightMissing: _onHighlightPostMissing,
                    channels: channels,
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
                      ? AppEmptyState(
                          title: 'No residents yet',
                          description: isJoined
                              ? 'Invite people who match this world\'s culture.'
                              : 'Join to meet members and join the conversation.',
                          icon: Icons.people_outline,
                          actionLabel: isJoined ? 'Invite residents' : 'Join world',
                          onAction: isJoined
                              ? () => context.push('/search')
                              : _handleJoin,
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
                  child: WorldRealmDossier(
                    world: world,
                    worldId: widget.worldId,
                    channels: channels,
                    worldPosts: posts,
                    resident: resident,
                    isJoined: isJoined,
                    isSovereignOrCouncil:
                        _isSovereignOrCouncil(resident, world),
                    onJoin: _handleJoin,
                    onSettings: onSettings,
                    onShare: () => _showWorldShareSheet(world),
                    onOpenChannel: (name) =>
                        _openChannelByName(name, channels),
                    members: _members,
                    membersLoading: _membersLoading,
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
            Tab(text: 'ABOUT'),
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
    final resident = ref.watch(residentProvider).resident;
    final showMarket = WorldCapabilityMatrix.worldHasMarketplace(world);
    final showTreasury = WorldCapabilityMatrix.worldHasTreasury(world);
    final canList = WorldCapabilityMatrix.canCreateListing(
      resident,
      world,
      isJoined: isJoined,
    );
    final canTreasuryAdmin = WorldCapabilityMatrix.canManageTreasury(
      resident,
      world,
    );

    if (!isJoined) {
      return const AppEmptyState(
        title: 'Join to manage',
        description: 'Economy and world tools unlock after you join.',
        icon: Icons.lock_outline,
        variant: EmptyStateVariant.default_,
      );
    }

    final isCouncilOrSovereign = canTreasuryAdmin;

    final links = <FTileMixin>[
      if (FeatureFlags.treasury && showTreasury)
        VSectionTile(
          icon: Icons.account_balance_wallet,
          label: 'Treasury',
          onTap: () => context.push(
            worldTreasuryPath(worldId, admin: canTreasuryAdmin),
          ),
        ),
      if (FeatureFlags.marketplace && showMarket)
        VSectionTile(
          icon: Icons.storefront,
          label: 'Marketplace',
          onTap: () => context.push(
            worldMarketplacePath(worldId, member: isJoined),
          ),
        ),
      if (FeatureFlags.polls)
        VSectionTile(
          icon: Icons.how_to_vote,
          label: 'Polls',
          onTap: () => context.push(
            worldPollsPath(worldId, admin: isCouncilOrSovereign),
          ),
        ),
      VSectionTile(
        icon: Icons.work_outline,
        label: 'Role board',
        onTap: () => context.push(
          worldJobsPath(worldId, admin: isCouncilOrSovereign),
        ),
      ),
      VSectionTile(
        icon: Icons.menu_book_outlined,
        label: 'World archive',
        onTap: () => context.push(worldArchivePath(worldId)),
      ),
    ];

    final prestigeColor = world.prestige >= 40
        ? VColors.tierApex
        : world.prestige >= 20
        ? VColors.primary
        : VColors.tierHustler;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VSectionList(title: 'World tools', children: links),
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
                    canList
                        ? 'Prestige ${world.prestige} · you can list on the marketplace'
                        : (WorldCapabilityMatrix.blockReasonCreateListing(
                              resident,
                              world,
                              isJoined: isJoined,
                            ) ??
                            'Prestige ${world.prestige} · economy modules'),
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
