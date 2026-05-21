import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../../models/resident.dart';
import '../../services/permission_service.dart';
import '../core/empty_state.dart';
import '../core/glass_panel.dart';
import '../feed/post_input.dart';
import '../feed/post_item.dart';
import 'event_card.dart';

class WorldFeedTab extends ConsumerWidget {
  final String worldId;
  final dynamic world;
  final Resident? resident;
  final List<dynamic> posts;
  final ColorScheme cs;

  const WorldFeedTab({
    super.key,
    required this.worldId,
    required this.world,
    required this.resident,
    required this.posts,
    required this.cs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventPosts = posts
        .where((p) => (p as dynamic).isEvent == true)
        .toList();
    final regularPosts = posts
        .where((p) => (p as dynamic).isEvent != true)
        .toList();

    return Column(
      children: [
        if (resident != null &&
            world != null &&
            WorldPermissions.canPost(resident!, worldId, world.sovereignId))
          PostInput(worldId: worldId, sovereignId: world.sovereignId)
        else
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: VSurfacePanel(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    size: IconSizes.md,
                    color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.sm + 4),
                  Expanded(
                    child: Text(
                      'Member+ required to post',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Event posts section (before regular posts)
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
        // Posts list
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
                  itemBuilder: (context, index) => PostItem(
                    post: regularPosts[index],
                    index: index,
                    worldId: worldId,
                  ),
                ),
        ),
      ],
    );
  }
}
