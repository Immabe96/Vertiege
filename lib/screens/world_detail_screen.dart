import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/design_system.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../state/channel_provider.dart';
import '../widgets/worlds/world_access_guard.dart';
import '../widgets/worlds/world_banner.dart';
import '../widgets/worlds/world_channel_list.dart';
import '../widgets/worlds/world_residents.dart';
import '../widgets/feed/post_input.dart';
import '../widgets/feed/post_item.dart';
import '../widgets/core/fade_in.dart';
import '../state/post_provider.dart';
import 'package:go_router/go_router.dart';

class WorldDetailScreen extends ConsumerWidget {
  final String worldId;

  const WorldDetailScreen({super.key, required this.worldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldProvider).worlds[worldId];
    final resident = ref.watch(residentProvider).resident;
    final posts = ref.watch(postProvider.notifier).getPostsByWorld(worldId);
    final theme = Theme.of(context);

    // Auto-join world and load channels
    if (world != null && resident != null) {
      if (!resident.joinedWorldIds.contains(worldId)) {
        Future.microtask(() {
          ref.read(residentProvider.notifier).joinWorld(worldId);
          ref.read(channelProvider.notifier).ensureDefaultChannels(worldId);
        });
      } else {
        Future.microtask(() {
          ref.read(channelProvider.notifier).loadChannels(worldId);
        });
      }
    }

    return WorldAccessGuard(
      worldId: worldId,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(postProvider.notifier).loadPosts();
            await Future<void>.delayed(const Duration(milliseconds: 200));
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                actions: [
                  if (world != null && resident?.id == world.sovereignId)
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'World settings',
                      onPressed: () => context.push('/explore/$worldId/settings'),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(world?.name ?? worldId),
                  background: Hero(
                    tag: 'world-icon-$worldId',
                    child: WorldBanner(worldId: worldId),
                  ),
                ),
              ),
              if (world != null) ...[
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 100,
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
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
                ),
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 140,
                    child: WorldChannelList(worldId: worldId),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 180,
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: WorldResidents(world: world),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: 220,
                  child: PostInput(worldId: worldId),
                ),
              ),
              if (posts.isEmpty)
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 260,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 40,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No posts in this world yet',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
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
      ),
    );
  }
}
