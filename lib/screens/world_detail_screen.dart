import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/world_provider.dart';
import '../widgets/worlds/world_access_guard.dart';
import '../widgets/worlds/world_banner.dart';
import '../widgets/worlds/world_residents.dart';
import '../widgets/feed/post_input.dart';
import '../widgets/feed/post_item.dart';
import '../state/post_provider.dart';

class WorldDetailScreen extends ConsumerWidget {
  final String worldId;

  const WorldDetailScreen({super.key, required this.worldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldProvider).worlds[worldId];
    final posts = ref.watch(postProvider.notifier).getPostsByWorld(worldId);
    final theme = Theme.of(context);

    return WorldAccessGuard(
      worldId: worldId,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(world?.name ?? worldId),
                background: WorldBanner(worldId: worldId),
              ),
            ),
            if (world != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(world.description, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Sovereign: ${world.sovereignName}', style: theme.textTheme.bodyMedium),
                      Text('Prestige: ${world.prestige}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: WorldResidents(world: world),
                ),
              ),
            ],
            SliverToBoxAdapter(child: PostInput(worldId: worldId)),
            if (posts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('No posts in this world yet', style: theme.textTheme.bodyLarge),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostItem(post: posts[index], index: index),
                  childCount: posts.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
