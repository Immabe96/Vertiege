import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/post.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/v_motion.dart';
import '../../models/resident.dart';
import '../../services/permission_service.dart';
import '../core/empty_state.dart';
import '../core/glass_panel.dart';
import '../feed/post_input.dart';
import '../feed/post_item.dart';
import 'event_card.dart';

class WorldFeedTab extends ConsumerStatefulWidget {
  final String worldId;
  final dynamic world;
  final Resident? resident;
  final List<dynamic> posts;
  final ColorScheme cs;

  /// When true, builds a single [ListView] for [NestedScrollView] tab bodies.
  final bool primaryScroll;
  final String? highlightPostId;
  final bool isJoined;
  final VoidCallback? onJoin;
  final VoidCallback? onHighlightMissing;

  const WorldFeedTab({
    super.key,
    required this.worldId,
    required this.world,
    required this.resident,
    required this.posts,
    required this.cs,
    this.primaryScroll = false,
    this.highlightPostId,
    this.isJoined = true,
    this.onJoin,
    this.onHighlightMissing,
  });

  @override
  ConsumerState<WorldFeedTab> createState() => _WorldFeedTabState();
}

class _WorldFeedTabState extends ConsumerState<WorldFeedTab>
    with SingleTickerProviderStateMixin {
  final _highlightKey = GlobalKey();
  late final AnimationController _highlightFlash;
  bool _reportedMissingHighlight = false;

  @override
  void initState() {
    super.initState();
    _highlightFlash = AnimationController(
      vsync: this,
      duration: VAnimation.slow,
    );
    if (widget.highlightPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlight();
        if (mounted && context.motionEnabled) {
          _highlightFlash.forward();
        } else {
          _highlightFlash.value = 1.0;
        }
        _verifyHighlightPost();
      });
    }
  }

  @override
  void didUpdateWidget(WorldFeedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightPostId != oldWidget.highlightPostId ||
        widget.posts.length != oldWidget.posts.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlight();
        _verifyHighlightPost();
      });
    }
  }

  @override
  void dispose() {
    _highlightFlash.dispose();
    super.dispose();
  }

  void _scrollToHighlight() {
    final ctx = _highlightKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: context.motionDuration(VAnimation.normal),
        curve: context.motionCurve,
        alignment: 0.2,
      );
    }
  }

  void _verifyHighlightPost() {
    final highlightId = widget.highlightPostId;
    if (highlightId == null || _reportedMissingHighlight) return;
    final found = widget.posts.any((p) => (p as Post).id == highlightId);
    if (!found) {
      _reportedMissingHighlight = true;
      widget.onHighlightMissing?.call();
    }
  }

  Widget _postTile(Post post, int index, String worldId, String? highlightId) {
    final highlighted = highlightId != null && post.id == highlightId;
    Widget tile = PostItem(post: post, index: index, worldId: worldId);
    if (!highlighted) {
      return tile;
    }

    if (!context.motionEnabled) {
      return Container(
        key: _highlightKey,
        margin: const EdgeInsets.symmetric(
          horizontal: VSpacing.sm,
          vertical: VSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VRadius.md),
          border: Border.all(
            color: VColors.primary.withValues(alpha: 0.5),
            width: 2,
          ),
          color: VColors.primary.withValues(alpha: 0.08),
        ),
        child: tile,
      );
    }

    tile = AnimatedBuilder(
      animation: _highlightFlash,
      builder: (context, child) {
        final t = _highlightFlash.value;
        final flash = t < 0.5 ? t * 2 : (1 - t) * 2;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VRadius.md),
            border: Border.all(
              color: Color.lerp(
                VColors.primary.withValues(alpha: 0.35),
                VColors.primary,
                flash,
              )!,
              width: 2,
            ),
            color: VColors.primary.withValues(alpha: 0.06 + flash * 0.10),
          ),
          child: child,
        );
      },
      child: tile,
    );

    return Container(
      key: _highlightKey,
      margin: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: VSpacing.xs,
      ),
      child: tile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final worldId = widget.worldId;
    final world = widget.world;
    final resident = widget.resident;
    final posts = widget.posts;
    final primaryScroll = widget.primaryScroll;
    final highlightPostId = widget.highlightPostId;
    final isJoined = widget.isJoined;
    final onJoin = widget.onJoin;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventPosts = posts
        .where((p) => (p as dynamic).isEvent == true)
        .toList();
    final regularPosts = posts
        .where((p) => (p as dynamic).isEvent != true)
        .toList();

    final postHeader = resident != null &&
            world != null &&
            WorldPermissions.canPost(resident, worldId, world.sovereignId)
        ? PostInput(worldId: worldId, sovereignId: world.sovereignId)
        : Padding(
            padding: const EdgeInsets.all(VSpacing.md),
            child: VSurfacePanel(
              padding: const EdgeInsets.all(VSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    size: VIconSize.md,
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: VSpacing.sm + 4),
                  Expanded(
                    child: Text(
                      'Member+ required to post',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

    if (!primaryScroll) {
      return Column(
        children: [
          postHeader,
          if (eventPosts.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
                scrollDirection: Axis.horizontal,
                itemCount: eventPosts.length,
                itemBuilder: (context, index) => SizedBox(
                  width: 300,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < eventPosts.length - 1 ? VSpacing.sm : 0,
                    ),
                    child: EventCard(post: eventPosts[index]),
                  ),
                ),
              ),
            ),
          Expanded(
            child: regularPosts.isEmpty && eventPosts.isEmpty
                ? AppEmptyState(
                    title: isJoined ? 'No posts yet' : 'Join to participate',
                    description: isJoined
                        ? 'Be the first to share an update in this world.'
                        : 'Join this world to read the full feed and post with members.',
                    icon: isJoined
                        ? Icons.auto_awesome
                        : Icons.lock_outline,
                    actionLabel: isJoined ? null : 'Join world',
                    onAction: isJoined ? null : onJoin,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: VSpacing.xxl + VSpacing.xxl,
                    ),
                    itemCount: regularPosts.length,
                    itemBuilder: (context, index) => _postTile(
                      regularPosts[index] as Post,
                      index,
                      worldId,
                      highlightPostId,
                    ),
                  ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: VSpacing.xxl + VSpacing.xxl),
      children: [
        postHeader,
        if (eventPosts.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
              scrollDirection: Axis.horizontal,
              itemCount: eventPosts.length,
              itemBuilder: (context, index) => SizedBox(
                width: 300,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < eventPosts.length - 1 ? VSpacing.sm : 0,
                  ),
                  child: EventCard(post: eventPosts[index]),
                ),
              ),
            ),
          ),
        if (regularPosts.isEmpty && eventPosts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(VSpacing.xl),
            child: AppEmptyState(
              title: isJoined ? 'No posts yet' : 'Join to participate',
              description: isJoined
                  ? 'Be the first to share an update in this world.'
                  : 'Join this world to read the full feed and post with members.',
              icon: isJoined ? Icons.auto_awesome : Icons.lock_outline,
              actionLabel: isJoined ? null : 'Join world',
              onAction: isJoined ? null : onJoin,
            ),
          )
        else
          ...List.generate(
            regularPosts.length,
            (index) => _postTile(
              regularPosts[index] as Post,
              index,
              worldId,
              highlightPostId,
            ),
          ),
      ],
    );
  }
}
