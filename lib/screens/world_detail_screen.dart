import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_system.dart';
import '../theme/colors.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../state/channel_provider.dart';
import '../widgets/worlds/world_access_guard.dart';
import '../widgets/worlds/world_banner.dart';
import '../widgets/worlds/world_channel_list.dart';
import '../widgets/worlds/world_residents.dart';
import '../services/permission_service.dart';
import '../services/world_service.dart';
import '../state/event_provider.dart';
import '../widgets/feed/post_input.dart';
import '../widgets/feed/post_item.dart';
import '../widgets/core/fade_in.dart';
import '../state/post_provider.dart';
import '../models/resident.dart';

class WorldDetailScreen extends ConsumerStatefulWidget {
  final String worldId;

  const WorldDetailScreen({super.key, required this.worldId});

  @override
  ConsumerState<WorldDetailScreen> createState() => _WorldDetailScreenState();
}

class _WorldDetailScreenState extends ConsumerState<WorldDetailScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  late final AnimationController _joinAnimController;
  final GlobalKey _joinButtonKey = GlobalKey();

  List<_MemberEntry> _members = [];
  bool _membersLoading = true;

  int _displayedMembers = 0;
  int _displayedPosts = 0;
  int _displayedEvents = 0;
  bool _statsAnimated = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _joinAnimController = AnimationController(
      duration: AnimDurations.fast,
      vsync: this,
    );
    _loadMembers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAutoJoin();
  }

  void _maybeAutoJoin() {
    final worldState = ref.read(worldProvider);
    final world = worldState.worlds[widget.worldId];
    final resident = ref.read(residentProvider).resident;
    if (world == null || resident == null) return;
    final alreadyJoined = resident.joinedWorldIds.contains(widget.worldId);
    if (!alreadyJoined &&
        !resident.bannedWorldIds.contains('${widget.worldId}:${resident.id}')) {
      Future.microtask(() {
        ref.read(channelProvider.notifier).loadChannels(widget.worldId);
      });
    } else {
      Future.microtask(() {
        ref.read(channelProvider.notifier).loadChannels(widget.worldId);
      });
    }
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0;
    });
  }

  Future<void> _loadMembers() async {
    try {
      final members = await WorldService.getMembers(widget.worldId);
      if (mounted) {
        setState(() {
          _members = members
              .map((m) => _MemberEntry(
                    resident: Resident(
                      id: m['resident_id'] ?? '',
                      name: m['resident_name'] ?? 'Member',
                      avatarUrl: 'https://via.placeholder.com/150',
                    ),
                    rep: m['rep'] ?? 0,
                  ))
              .toList();
          _membersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  void _startStatAnimation() {
    if (_statsAnimated) return;
    _statsAnimated = true;

    final world = ref.read(worldProvider).worlds[widget.worldId];
    final posts =
        ref.read(postProvider.notifier).getPostsByWorld(widget.worldId);
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
    _scrollController.dispose();
    _joinAnimController.dispose();
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
            'You will lose all your standing and rep in this world. This action cannot be undone.'),
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

  @override
  Widget build(BuildContext context) {
    final world = ref.watch(worldProvider).worlds[widget.worldId];
    final resident = ref.watch(residentProvider).resident;
    final posts =
        ref.watch(postProvider.notifier).getPostsByWorld(widget.worldId);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isJoined = resident?.joinedWorldIds.contains(widget.worldId) ?? false;

    final scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _joinAnimController,
      curve: AnimCurves.easeOut,
    ));

    return WorldAccessGuard(
      worldId: widget.worldId,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(postProvider.notifier).loadPosts();
            await _loadMembers();
            _statsAnimated = false;
            await Future<void>.delayed(const Duration(milliseconds: 200));
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Hero Banner Header ────────────────────
              _HeroBanner(
                worldId: widget.worldId,
                scrollOffset: _scrollOffset,
                worldName: world?.name ?? widget.worldId,
                isJoined: isJoined,
                scaleAnimation: scaleAnimation,
                joinAnimController: _joinAnimController,
                joinButtonKey: _joinButtonKey,
                onJoin: _handleJoin,
                onSettings: world != null &&
                        resident != null &&
                        WorldPermissions.canManageSettings(
                            resident, widget.worldId, world.sovereignId)
                    ? () => context.push('/explore/${widget.worldId}/settings')
                    : null,
              ),

              if (world != null) ...[
                // ── Info Sheet — Travel App curved detail pattern
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 60,
                    child: _WorldInfoSheet(
                      world: world,
                      resident: resident,
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

                // ── Member avatars ──────────────────────
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 90,
                    child: _MemberRow(
                      members: _members,
                      isLoading: _membersLoading,
                      onlineCount:
                          math.min(8, (_members.length * 0.4).round()),
                      onTap: () => context.push(
                        '/explore/${widget.worldId}/members'
                        '?name=${Uri.encodeComponent(world.name)}'
                        '&sovereign=${Uri.encodeComponent(world.sovereignId)}',
                      ),
                    ),
                  ),
                ),

                // ── Events ──────────────────────────────
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 110,
                    child: _EventsCard(
                        worldId: widget.worldId,
                        sovereignId: world.sovereignId),
                  ),
                ),

                // ── Channels ────────────────────────────
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 130,
                    child: WorldChannelList(worldId: widget.worldId),
                  ),
                ),

                // ── Residents ───────────────────────────
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 160,
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: WorldResidents(world: world),
                    ),
                  ),
                ),
              ],

              // ── Post input / locked notice ───────────
              if (resident != null &&
                  world != null &&
                  WorldPermissions.canPost(
                      resident, widget.worldId, world.sovereignId))
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 200,
                    child: PostInput(
                        worldId: widget.worldId,
                        sovereignId: world.sovereignId),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 200,
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Card(
                        color: cs.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.md),
                          child: Row(
                            children: [
                              Icon(Icons.lock,
                                  size: IconSizes.md, color: cs.outline),
                              const SizedBox(width: Spacing.sm + 4),
                              Expanded(
                                child: Text(
                                  'Member+ required to post',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: cs.outline),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Posts ────────────────────────────────
              if (posts.isEmpty)
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 240,
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: IconSizes.xl, color: cs.outlineVariant),
                            const SizedBox(height: Spacing.sm + 4),
                            Text('No posts in this world yet',
                                style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PostItem(
                        post: posts[index],
                        index: index,
                        worldId: widget.worldId),
                    childCount: posts.length,
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: Spacing.xxl + Spacing.xxl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Hero Banner — parallax banner with overlay info and actions
// ──────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String worldId;
  final double scrollOffset;
  final String worldName;
  final bool isJoined;
  final Animation<double> scaleAnimation;
  final AnimationController joinAnimController;
  final GlobalKey joinButtonKey;
  final VoidCallback onJoin;
  final VoidCallback? onSettings;

  const _HeroBanner({
    required this.worldId,
    required this.scrollOffset,
    required this.worldName,
    required this.isJoined,
    required this.scaleAnimation,
    required this.joinAnimController,
    required this.joinButtonKey,
    required this.onJoin,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    const expandedHeight = 260.0;
    final theme = Theme.of(context);
    final parallaxOffset = (scrollOffset * 0.5).clamp(0.0, expandedHeight);
    final collapseProgress =
        (scrollOffset / (expandedHeight - kToolbarHeight - 48)).clamp(0.0, 1.0);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      actions: [
        if (onSettings != null)
          IconButton(
            icon: const Icon(Icons.settings, size: IconSizes.md),
            tooltip: 'World settings',
            onPressed: onSettings,
          ),
        ScaleTransition(
          scale: scaleAnimation,
          child: AnimatedBuilder(
            animation: joinAnimController,
            builder: (context, _) {
              if (isJoined) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton.icon(
                    key: joinButtonKey,
                    onPressed: onJoin,
                    icon: const Icon(Icons.exit_to_app, size: IconSizes.sm),
                    label: const Text('Leave'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilledButton.icon(
                  key: joinButtonKey,
                  onPressed: onJoin,
                  icon: const Icon(Icons.add, size: IconSizes.sm),
                  label: const Text('Join'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          // Parallax banner
          Positioned(
            top: -parallaxOffset,
            left: 0,
            right: 0,
            height: expandedHeight,
            child: Hero(
              tag: 'world-icon-$worldId',
              child: WorldBanner(worldId: worldId),
            ),
          ),
          // Gradient overlay for readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: expandedHeight * 0.55,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      theme.colorScheme.surface.withValues(alpha: 0.75),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Title on banner (fades out on scroll)
          Positioned(
            left: Spacing.md,
            right: Spacing.md,
            bottom: 20,
            child: Opacity(
              opacity: (1.0 - collapseProgress).clamp(0.0, 1.0),
              child: Text(
                worldName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: LetterSpacing.heading,
                  shadows: const [
                    Shadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 2)),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// World Info Sheet — curved card immediately below banner
// ──────────────────────────────────────────────────────────

class _WorldInfoSheet extends StatefulWidget {
  final dynamic world;
  final dynamic resident;
  final int members;
  final int posts;
  final int events;
  final VoidCallback onVisible;
  final VoidCallback onMembersTap;

  const _WorldInfoSheet({
    required this.world,
    required this.resident,
    required this.members,
    required this.posts,
    required this.events,
    required this.onVisible,
    required this.onMembersTap,
  });

  @override
  State<_WorldInfoSheet> createState() => _WorldInfoSheetState();
}

class _WorldInfoSheetState extends State<_WorldInfoSheet> {
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final world = widget.world;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: AppColors.alphaBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.md, Spacing.md, Spacing.md, Spacing.sm),
            child: Text(
              world.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: LineHeight.relaxed,
                color: cs.onSurface,
              ),
            ),
          ),

          // Sovereign + Prestige row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: IconSizes.sm, color: cs.primary),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    'Sovereign: ${world.sovereignName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(Icons.star, size: IconSizes.sm, color: AppColors.gold),
                const SizedBox(width: Spacing.xs),
                Text(
                  'Prestige ${world.prestige}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Divider
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),

          // Stats row — Travel App detail stats pattern
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.sm + 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                    icon: Icons.people,
                    label: 'Members',
                    value: widget.members,
                    color: cs.primary),
                _StatItem(
                    icon: Icons.forum,
                    label: 'Posts',
                    value: widget.posts,
                    color: AppColors.brandGreen),
                _StatItem(
                    icon: Icons.event,
                    label: 'Events',
                    value: widget.events,
                    color: AppColors.streakOrange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          child: Icon(icon, size: IconSizes.md, color: color),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Member Row — overlapping avatars + online count
// ──────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  final List<_MemberEntry> members;
  final bool isLoading;
  final int onlineCount;
  final VoidCallback onTap;

  const _MemberRow({
    required this.members,
    required this.isLoading,
    required this.onlineCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final displayMembers = members.take(8).toList();
    final remaining = members.length - displayMembers.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Row(
            children: [
              if (isLoading) ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Spacing.sm),
                Text('Loading members...', style: theme.textTheme.bodySmall),
              ] else ...[
                SizedBox(
                  height: 40,
                  child: Stack(
                    children: displayMembers.asMap().entries.map((entry) {
                      return Positioned(
                        left: entry.key * 28.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.surface,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                NetworkImage(entry.value.resident.avatarUrl),
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                if (remaining > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm, vertical: Spacing.xs),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(RadiusTokens.round),
                    ),
                    child: Text(
                      '+$remaining more',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (remaining > 0) const SizedBox(width: Spacing.sm),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.online,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.online,
                          blurRadius: 4,
                          spreadRadius: 0.5),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  '$onlineCount online',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.online,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              Icon(Icons.chevron_right,
                  size: IconSizes.md, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Events Card
// ──────────────────────────────────────────────────────────

class _EventsCard extends ConsumerWidget {
  final String worldId;
  final String sovereignId;

  const _EventsCard({required this.worldId, required this.sovereignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref
            .watch(eventProvider)
            .eventsByWorld[worldId]
            ?.where((e) => e.isUpcoming)
            .toList() ??
        [];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final resident = ref.watch(residentProvider).resident;
    final canCreate = resident != null &&
        WorldPermissions.canAnnounce(resident, worldId, sovereignId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.xs),
          child: Row(
            children: [
              Icon(Icons.event_note, size: IconSizes.sm, color: cs.primary),
              const SizedBox(width: Spacing.sm),
              Text('Upcoming Events',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              if (canCreate)
                TextButton.icon(
                  onPressed: () => _showCreateEvent(context, ref),
                  icon: const Icon(Icons.add, size: IconSizes.xs),
                  label: const Text('Create'),
                ),
            ],
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: Spacing.md, bottom: Spacing.xs),
            child: Text('No upcoming events',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.outline)),
          )
        else
          ...events.take(3).map((event) {
            final isRsvp =
                resident != null && event.rsvpIds.contains(resident.id);
            return ListTile(
              dense: true,
              leading: Icon(
                  isRsvp ? Icons.event_available : Icons.event,
                  size: IconSizes.md,
                  color: isRsvp ? cs.primary : cs.onSurfaceVariant),
              title: Text(event.title, style: theme.textTheme.bodyMedium),
              subtitle: Text(event.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall),
              trailing: TextButton(
                onPressed: () {
                  if (resident != null) {
                    ref
                        .read(eventProvider.notifier)
                        .toggleRsvp(worldId, event.id, resident.id);
                  }
                },
                child: Text(
                    isRsvp
                        ? 'Going (${event.rsvpIds.length})'
                        : 'RSVP (${event.rsvpIds.length})',
                    style: TextStyle(
                        fontSize: FontSizes.caption,
                        color: isRsvp ? cs.primary : cs.outline)),
              ),
            );
          }),
      ],
    );
  }

  void _showCreateEvent(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Event title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'Description', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final resident = ref.read(residentProvider).resident;
              if (resident == null) return;
              ref.read(eventProvider.notifier).createEvent(
                    worldId: worldId,
                    title: title,
                    description: descCtrl.text.trim(),
                    createdBy: resident.id,
                    createdByName: resident.name,
                    startsAt: DateTime.now()
                        .add(const Duration(hours: 1))
                        .millisecondsSinceEpoch,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _MemberEntry {
  final Resident resident;
  final int rep;
  const _MemberEntry({required this.resident, required this.rep});
}
