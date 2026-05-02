import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/resident_provider.dart';
import '../../state/post_provider.dart';
import '../../widgets/core/notification_bell.dart';
import '../../widgets/feed/post_input.dart';
import '../../widgets/feed/post_item.dart';

class NexusScreen extends ConsumerWidget {
  const NexusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final posts = ref.watch(postProvider).posts;
    final theme = Theme.of(context);

    final greeting = _getGreeting();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$greeting, ${resident?.name ?? 'Traveler'}',
                            style: theme.textTheme.headlineSmall),
                        if (resident != null) ...[
                          const SizedBox(height: 4),
                          Text('Tier: ${resident.tier.label} | Streak: ${resident.streakCount} days',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ],
                    ),
                    NotificationBell(
                      onPress: () {
                        final shell = StatefulNavigationShell.of(context);
                        shell.goBranch(4);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: PostInput(worldId: 'neon-district')),
            if (posts.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No posts yet. Be the first!', style: theme.textTheme.bodyLarge),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
