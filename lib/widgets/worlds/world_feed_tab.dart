import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/post.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
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

  const WorldFeedTab({
    super.key,
    required this.worldId,
    required this.world,
    required this.resident,
    required this.posts,
    required this.cs,
    this.primaryScroll = false,
    this.highlightPostId,
  });

  @override
  ConsumerState<WorldFeedTab> createState() => _WorldFeedTabState();
}

class _WorldFeedTabState extends ConsumerState<WorldFeedTab> {
  final _highlightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.highlightPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlight());
    }
  }

  void _scrollToHighlight() {
    final ctx = _highlightKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        alignment: 0.2,
      );
    }
  }

  Widget _postTile(Post post, int index, String worldId, String? highlightId) {
    final highlighted = highlightId != null && post.id == highlightId;
    return Container(
      key: highlighted ? _highlightKey : null,
      margin: highlighted
          ? const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            )
          : null,
      decoration: highlighted
          ? BoxDecoration(
              border: Border.all(color: VColors.primary, width: 2),
              borderRadius: BorderRadius.circular(RadiusTokens.md),
            )
          : null,
      child: PostItem(post: post, index: index, worldId: worldId),
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
            padding: const EdgeInsets.all(Spacing.md),
            child: VSurfacePanel(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    size: IconSizes.md,
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.sm + 4),
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
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                scrollDirection: Axis.horizontal,
                itemCount: eventPosts.length,
                itemBuilder: (context, index) => SizedBox(
                  width: 300,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < eventPosts.length - 1 ? Spacing.sm : 0,
                    ),
                    child: EventCard(post: eventPosts[index]),
                  ),
                ),
              ),
            ),
          Expanded(
            child: regularPosts.isEmpty && eventPosts.isEmpty
                ? const AppEmptyState(
                    title: 'No posts yet',
                    description: 'Be the first to post in this world',
                    icon: Icons.auto_awesome,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: Spacing.xxl + Spacing.xxl,
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
      padding: const EdgeInsets.only(bottom: Spacing.xxl + Spacing.xxl),
      children: [
        postHeader,
        if (eventPosts.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              scrollDirection: Axis.horizontal,
              itemCount: eventPosts.length,
              itemBuilder: (context, index) => SizedBox(
                width: 300,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < eventPosts.length - 1 ? Spacing.sm : 0,
                  ),
                  child: EventCard(post: eventPosts[index]),
                ),
              ),
            ),
          ),
        if (regularPosts.isEmpty && eventPosts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(Spacing.xl),
            child: AppEmptyState(
              title: 'No posts yet',
              description: 'Be the first to post in this world',
              icon: Icons.auto_awesome,
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
