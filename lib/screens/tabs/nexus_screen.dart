import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/resident_provider.dart';
import '../../state/post_provider.dart';
import '../../state/quest_provider.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/notification_bell.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/feed/post_input.dart';
import '../../widgets/feed/post_item.dart';

enum _FeedTab { all, following, announcements }

class NexusScreen extends ConsumerStatefulWidget {
  const NexusScreen({super.key});

  @override
  ConsumerState<NexusScreen> createState() => _NexusScreenState();
}

class _NexusScreenState extends ConsumerState<NexusScreen> {
  _FeedTab _tab = _FeedTab.all;

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final allPosts = ref.watch(postProvider).posts;
    final theme = Theme.of(context);
    final greeting = _getGreeting();

    // Filter posts based on tab
    final posts = switch (_tab) {
      _FeedTab.all => allPosts,
      _FeedTab.following => allPosts.where((p) => resident?.following.contains(p.residentId) ?? false).toList(),
      _FeedTab.announcements => allPosts.where((p) => p.isAnnouncement).toList(),
    };

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(postProvider.notifier).loadPosts();
            await Future<void>.delayed(const Duration(milliseconds: 200));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$greeting, ${resident?.name ?? 'Traveler'}',
                                style: theme.textTheme.headlineSmall),
                            if (resident != null) ...[
                              const SizedBox(height: Spacing.xs),
                              Text('Tier: ${resident.tier.label} | Streak: ${resident.streakCount} days',
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'Search',
                              onPressed: () => context.push('/search'),
                            ),
                            NotificationBell(
                              onPress: () {
                                final shell = StatefulNavigationShell.of(context);
                                shell.goBranch(4);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Feed tabs
              SliverToBoxAdapter(
                child: FadeIn(
                  delayMs: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        _TabChip(
                          label: 'All',
                          selected: _tab == _FeedTab.all,
                          onTap: () => setState(() => _tab = _FeedTab.all),
                        ),
                        const SizedBox(width: 6),
                        _TabChip(
                          label: 'Following',
                          selected: _tab == _FeedTab.following,
                          onTap: () => setState(() => _tab = _FeedTab.following),
                        ),
                        const SizedBox(width: 6),
                        _TabChip(
                          label: 'Announcements',
                          selected: _tab == _FeedTab.announcements,
                          icon: Icons.campaign,
                          onTap: () => setState(() => _tab = _FeedTab.announcements),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Daily Quests
              SliverToBoxAdapter(child: FadeIn(delayMs: 60, child: _QuestCard())),
              SliverToBoxAdapter(child: FadeIn(delayMs: 80, child: PostInput(worldId: 'neon-district'))),
              if (posts.isEmpty)
                SliverToBoxAdapter(
                  child: FadeIn(
                    delayMs: 160,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _tab == _FeedTab.following ? Icons.people_outline : Icons.auto_awesome,
                              size: 48,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _tab == _FeedTab.following
                                  ? 'Follow residents to see their posts here'
                                  : _tab == _FeedTab.announcements
                                      ? 'No announcements yet'
                                      : 'No posts yet. Be the first!',
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? theme.colorScheme.primary : theme.colorScheme.outline),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questState = ref.watch(questProvider);
    final quests = questState.quests;
    final theme = Theme.of(context);
    final allDone = quests.isNotEmpty && quests.every((q) => q.isComplete);

    if (quests.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: allDone ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Daily Quests', style: theme.textTheme.labelLarge),
                const Spacer(),
                Text('${questState.completedCount}/${quests.length}',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
            ...quests.map((q) {
              final done = q.isComplete;
              final claimed = q.claimed;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: done ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          decoration: claimed ? TextDecoration.lineThrough : null,
                          color: claimed ? theme.colorScheme.outline : null,
                        ),
                      ),
                    ),
                    Text('${q.progress}/${q.target}',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                    if (done && !claimed) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => ref.read(questProvider.notifier).claimQuest(q.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('+${q.xpReward} XP',
                              style: TextStyle(fontSize: 10, color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
