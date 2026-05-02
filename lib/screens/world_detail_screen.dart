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
import '../services/permission_service.dart';
import '../state/event_provider.dart';
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

    // Auto-join world and load channels (only on first mount)
    if (world != null && resident != null) {
      final alreadyJoined = resident.joinedWorldIds.contains(worldId);
      if (!alreadyJoined && !resident.bannedWorldIds.contains('$worldId:${resident.id}')) {
        // Use addPostFrameCallback to avoid triggering during build
        Future.microtask(() {
          if (ref.read(residentProvider).resident?.joinedWorldIds.contains(worldId) == false) {
            ref.read(residentProvider.notifier).joinWorld(worldId);
            ref.read(channelProvider.notifier).ensureDefaultChannels(worldId);
          }
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
                  if (world != null && resident != null && WorldPermissions.canManageSettings(resident, worldId, world.sovereignId))
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
                    delayMs: 130,
                    child: _EventsCard(worldId: worldId, sovereignId: world.sovereignId),
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
              if (resident != null && world != null && WorldPermissions.canPost(resident, worldId, world.sovereignId))
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 220,
                    child: PostInput(worldId: worldId, sovereignId: world.sovereignId),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 220,
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Card(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.lock, size: 18, color: theme.colorScheme.outline),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Member+ required to post',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                    (context, index) => PostItem(post: posts[index], index: index, worldId: worldId),
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

class _EventsCard extends ConsumerWidget {
  final String worldId;
  final String sovereignId;

  const _EventsCard({required this.worldId, required this.sovereignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventProvider).eventsByWorld[worldId]?.where((e) => e.isUpcoming).toList() ?? [];
    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;
    final canCreate = resident != null && WorldPermissions.canAnnounce(resident, worldId, sovereignId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('Events', style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              )),
              const Spacer(),
              if (canCreate)
                TextButton.icon(
                  onPressed: () => _showCreateEvent(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create'),
                ),
            ],
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text('No upcoming events', style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            )),
          )
        else
          ...events.take(3).map((event) {
            final isRsvp = resident != null && event.rsvpIds.contains(resident.id);
            return ListTile(
              dense: true,
              leading: Icon(isRsvp ? Icons.event_available : Icons.event, size: 20,
                  color: isRsvp ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              title: Text(event.title, style: theme.textTheme.bodyMedium),
              subtitle: Text(event.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall),
              trailing: TextButton(
                onPressed: () {
                  if (resident != null) {
                    ref.read(eventProvider.notifier).toggleRsvp(worldId, event.id, resident.id);
                  }
                },
                child: Text(isRsvp ? 'Going (${event.rsvpIds.length})' : 'RSVP (${event.rsvpIds.length})',
                    style: TextStyle(fontSize: 12, color: isRsvp ? theme.colorScheme.primary : theme.colorScheme.outline)),
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
              decoration: const InputDecoration(hintText: 'Event title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Description', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                startsAt: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
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
