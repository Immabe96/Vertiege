import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';
import '../theme/colors.dart';
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
import '../widgets/core/glass_panel.dart';
import '../widgets/core/glow_border.dart';
import '../state/post_provider.dart';
import '../models/resident.dart';
import '../models/world.dart' show World;
import '../widgets/worlds/resource_vault.dart';
import '../widgets/worlds/world_share_card.dart';
import '../widgets/shared/share_button.dart';

class WorldDetailScreen extends ConsumerStatefulWidget {
  final String worldId;

  const WorldDetailScreen({super.key, required this.worldId});

  @override
  ConsumerState<WorldDetailScreen> createState() => _WorldDetailScreenState();
}

class _WorldDetailScreenState extends ConsumerState<WorldDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _joinAnimController;
  late final TabController _tabController;
  final GlobalKey _joinButtonKey = GlobalKey();

  List<WorldMemberEntry> _members = [];
  bool _membersLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  int _displayedMembers = 0;
  int _displayedPosts = 0;
  int _displayedEvents = 0;
  bool _statsAnimated = false;

  @override
  void initState() {
    super.initState();
    _joinAnimController = AnimationController(
      duration: AnimDurations.fast,
      vsync: this,
    );
    _tabController = TabController(length: 3, vsync: this);
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

    const duration = AnimDurations.slow;
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
    _tabController.dispose();
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
    if (prestige >= 40) return AppColors.tertiary;
    if (prestige >= 20) return AppColors.primary;
    return AppColors.hustler;
  }

  GlowTier _getPrestigeGlowTier(int prestige) {
    if (prestige >= 40) return GlowTier.apex;
    if (prestige >= 20) return GlowTier.elite;
    return GlowTier.hustler;
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
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShareButton(
              shareText: 'Join me in ${world.name} on Vertiege!',
              onShared: () => Navigator.of(ctx).pop(),
              child: WorldShareCard(world: world),
            ),
            const SizedBox(height: Spacing.md),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _joinAnimController,
            curve: AnimCurves.easeOut,
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
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            SovereignErrorBanner(
              message: _errorMessage ?? 'Failed to load world',
              onRetry: _retryLoad,
            ),
            const SizedBox(height: Spacing.md),
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
    final prestigeGlowTier = _getPrestigeGlowTier(world.prestige);
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
                      // Gradient overlay (with tier tint at bottom)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppColors.canvas],
                              stops: const [0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + Spacing.sm,
                        left: Spacing.sm,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.ink,
                            size: IconSizes.lg,
                          ),
                          onPressed: () =>
                              safeBack(context, fallback: '/explore'),
                        ),
                      ),
                      // Share button (top-right, left of settings)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + Spacing.sm,
                        right: (onSettings != null ? 56.0 : Spacing.sm),
                        child: IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: AppColors.ink,
                            size: IconSizes.lg,
                          ),
                          tooltip: 'Share world',
                          onPressed: () => _showWorldShareSheet(world),
                        ),
                      ),
                      // Settings gear (top-right)
                      if (onSettings != null)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + Spacing.sm,
                          right: Spacing.sm,
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: AppColors.ink,
                              size: IconSizes.lg,
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
                          padding: const EdgeInsets.all(Spacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tier badge — colored by prestige tier
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.md,
                                  vertical: Spacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: prestigeTierColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    RadiusTokens.md,
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
                                    fontSize: FontSizes.labelSm,
                                    fontWeight: FontWeights.semiBold,
                                    color: prestigeTierColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Spacing.sm),
                              // World name + sovereign crown
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      world.name,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: FontSizes.headlineLg,
                                        fontWeight: FontWeights.bold,
                                        color: AppColors.ink,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Spacing.sm,
                                      vertical: Spacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.tertiary,
                                          AppColors.tertiaryFixedDim,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        RadiusTokens.pill,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.tertiary.withValues(
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
                                          color: AppColors.onTertiary,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'SOVEREIGN',
                                          style: TextStyle(
                                            fontSize: FontSizes.labelSm,
                                            fontWeight: FontWeights.bold,
                                            color: AppColors.onTertiary,
                                            letterSpacing: LetterSpacing.label,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacing.xs),
                              // Description
                              Text(
                                world.description,
                                style: TextStyle(
                                  fontSize: FontSizes.bodyLg,
                                  color: AppColors.inkSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Founded date (legacy)
                              if (world.createdAt > 0) ...[
                                const SizedBox(height: Spacing.sm),
                                Text(
                                  LegacyService.formatFoundedDate(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      world.createdAt,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: FontSizes.labelSm,
                                    color: AppColors.inkMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: Spacing.lg),
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
                                            ? AppColors.error
                                            : prestigeTierColor;
                                        final btnFg = isJoined
                                            ? AppColors.onError
                                            : (prestigeGlowTier == GlowTier.apex
                                                  ? AppColors.onTertiary
                                                  : AppColors.onPrimary);
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
              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: 80,
                  child: _WorldFoundationSummary(
                    world: world,
                    channels: channels,
                    onOpenChannel: (name) => _openChannelByName(name, channels),
                  ),
                ),
              ),

              // ── Resource Vault ──
              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: 100,
                  child: ResourceVault(
                    worldId: widget.worldId,
                    channels: channels,
                    vaultUnlocked: ref
                        .read(worldProvider.notifier)
                        .featuresForWorld(widget.worldId)
                        .vault,
                  ),
                ),
              ),

              // ── Alliances Section ──
              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: 115,
                  child: ChatPreviewPanel(worldId: widget.worldId),
                ),
              ),

              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: 130,
                  child: AllianceSection(worldId: widget.worldId, world: world),
                ),
              ),

              // ── Tab Bar — Tertiary label, uppercase ──
              SliverPersistentHeader(
                pinned: true,
                delegate: _WorldTabBarDelegate(
                  controller: _tabController,
                  color: prestigeTierColor,
                ),
              ),

              // ── Tab Content ──
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Feed tab: PostInput + Posts
                    WorldFeedTab(
                      worldId: widget.worldId,
                      world: world,
                      resident: resident,
                      posts: posts,
                      cs: cs,
                    ),
                    // Channels tab: list or empty via GlassPanel
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
                            padding: const EdgeInsets.all(Spacing.md),
                            physics: const ClampingScrollPhysics(),
                            child: WorldChannelList(worldId: widget.worldId),
                          ),
                    // Members tab: member rows or empty via GlassPanel
                    (!_membersLoading && _members.isEmpty)
                        ? const AppEmptyState(
                            title: 'No content',
                            description:
                                'No members have joined this world yet.',
                            icon: Icons.people_outline,
                            variant: EmptyStateVariant.default_,
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(Spacing.md),
                            physics: const ClampingScrollPhysics(),
                            child: WorldDetailMembers(
                              worldId: widget.worldId,
                              world: world,
                              members: _members,
                              membersLoading: _membersLoading,
                            ),
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

  const _WorldTabBarDelegate({required this.controller, required this.color});

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
    return ColoredBox(
      color: AppColors.canvas.withValues(alpha: 0.96),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.glassBorder),
            top: BorderSide(
              color: AppColors.glassBorder.withValues(alpha: 0.6),
            ),
          ),
        ),
        child: TabBar(
          controller: controller,
          labelColor: color,
          unselectedLabelColor: AppColors.inkMuted,
          indicatorColor: color,
          labelStyle: const TextStyle(
            fontSize: FontSizes.labelSm,
            fontWeight: FontWeights.semiBold,
            letterSpacing: LetterSpacing.label,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: FontSizes.labelSm,
            fontWeight: FontWeights.regular,
            letterSpacing: LetterSpacing.label,
          ),
          tabs: const [
            Tab(text: 'FEED'),
            Tab(text: 'CHANNELS'),
            Tab(text: 'MEMBERS'),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _WorldTabBarDelegate oldDelegate) {
    return oldDelegate.controller != controller || oldDelegate.color != color;
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
    final foundation = foundationForWorld(world);
    final guideChannels = _guideChannels;
    final orientation = orientationStepsForWorld(world);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.sm),
      child: GlassPanel(
        padding: const EdgeInsets.all(Spacing.lg),
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    color: AppColors.tertiary,
                    size: IconSizes.md,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'World Foundation',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeights.bold,
                          fontSize: FontSizes.bodyLg,
                        ),
                      ),
                      Text(
                        _accessLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: FontSizes.labelSm,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Text(
              foundation.premise,
              style: const TextStyle(
                color: AppColors.inkSecondary,
                fontSize: FontSizes.bodyMd,
                height: 1.35,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.xs,
              runSpacing: Spacing.xs,
              children: [
                for (final item in foundation.focus.take(3))
                  _FoundationChip(label: item),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            const Text(
              'Orientation Path',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeights.bold,
                fontSize: FontSizes.bodyMd,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            for (var i = 0; i < orientation.length; i++)
              _OrientationStepTile(
                index: i + 1,
                title: orientation[i].title,
                description: orientation[i].description,
                channel: orientation[i].channel,
                onTap: () => onOpenChannel(orientation[i].channel),
              ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                for (final channel in guideChannels)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: channel == guideChannels.last ? 0 : Spacing.sm,
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
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onOpenChannel('general'),
                icon: const Icon(Icons.forum_outlined, size: IconSizes.sm),
                label: const Text('Open General Discussion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.tertiary,
                  side: const BorderSide(color: AppColors.glassBorder),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.inkSecondary,
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.semiBold,
        ),
      ),
    );
  }
}

class _OrientationStepTile extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final String channel;
  final VoidCallback onTap;

  const _OrientationStepTile({
    required this.index,
    required this.title,
    required this.description,
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(RadiusTokens.md),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: AppColors.tertiary,
                    fontWeight: FontWeights.bold,
                    fontSize: FontSizes.labelSm,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeights.semiBold,
                      ),
                    ),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: FontSizes.labelSm,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '#$channel',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.semiBold,
                ),
              ),
              const SizedBox(width: Spacing.xs),
              const Icon(
                Icons.chevron_right,
                color: AppColors.inkMuted,
                size: IconSizes.sm,
              ),
            ],
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xs,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: IconSizes.md),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: FontSizes.labelSm,
                fontWeight: FontWeights.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
