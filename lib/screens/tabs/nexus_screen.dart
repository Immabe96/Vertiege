import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/resident_provider.dart';
import '../../state/post_provider.dart';
import '../../state/quest_provider.dart';
import '../../models/post.dart';
import '../../models/resident.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/notification_bell.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/feed/post_item.dart';
import '../../widgets/feed/post_input.dart';

enum _FeedTab { all, following, announcements }

enum _FeedSort { latest, hot, top }

class NexusScreen extends ConsumerStatefulWidget {
  const NexusScreen({super.key});

  @override
  ConsumerState<NexusScreen> createState() => _NexusScreenState();
}

class _NexusScreenState extends ConsumerState<NexusScreen> {
  _FeedTab _tab = _FeedTab.all;
  _FeedSort _sort = _FeedSort.latest;
  late final ScrollController _scrollController;
  bool _showScrollFab = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.hasClients && _scrollController.offset > 400;
    if (show != _showScrollFab) {
      setState(() => _showScrollFab = show);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: AnimDurations.normal,
      curve: AnimCurves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final postState = ref.watch(postProvider);
    final allPosts = postState.posts;
    final theme = Theme.of(context);
    final greeting = _getGreeting();

    // Filter posts based on tab
    var posts = switch (_tab) {
      _FeedTab.all => allPosts,
      _FeedTab.following =>
        allPosts.where((p) => resident?.following.contains(p.residentId) ?? false).toList(),
      _FeedTab.announcements => allPosts.where((p) => p.isAnnouncement).toList(),
    };

    // Sort posts
    posts = _sortPosts(posts, _sort);

    // Compute story residents (unique recent posters from followed list)
    final storyUsers = _getStoryUsers(resident, allPosts);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(postProvider.notifier).loadPosts();
            await Future<void>.delayed(const Duration(milliseconds: 200));
          },
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // ── Greeting header ──
                  SliverToBoxAdapter(
                    child: FadeIn(
                      delayMs: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting, ${resident?.name ?? 'Traveler'}',
                                    style: theme.textTheme.headlineSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (resident != null) ...[
                                    const SizedBox(height: Spacing.xs),
                                    Text(
                                      'Tier: ${resident.tier.label} | Streak: ${resident.streakCount} days',
                                      style: theme.textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
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

                  // ── Stories / Status row ──
                  if (storyUsers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 20,
                        child: _StoryRow(
                          storyUsers: storyUsers,
                          onTap: (residentId) {
                            // Navigate to the resident's latest post or profile
                            if (residentId == resident?.id) {
                              _showCreatePost(context, resident);
                            } else {
                              context.push('/residents/$residentId');
                            }
                          },
                        ),
                      ),
                    ),

                  // ── Create Post card ──
                  SliverToBoxAdapter(
                    child: FadeIn(
                      delayMs: 30,
                      child: _CreatePostCard(
                        resident: resident,
                        onTap: () => _showCreatePost(context, resident),
                      ),
                    ),
                  ),

                  // ── Feed tabs + sort ──
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
                            const Spacer(),
                            _SortDropdown(
                              currentSort: _sort,
                              onChanged: (s) => setState(() => _sort = s),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Daily Quests ──
                  SliverToBoxAdapter(
                    child: FadeIn(delayMs: 60, child: _QuestCard()),
                  ),

                  // ── Posts or empty state ──
                  if (postState.hasError)
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 160,
                        child: AppErrorState(
                          message: postState.error,
                          onRetry: () => ref.read(postProvider.notifier).loadPosts(),
                        ),
                      ),
                    )
                  else if (posts.isEmpty)
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 160,
                        child: _buildEmptyState(),
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

              // ── Quick scroll FAB ──
              if (_showScrollFab)
                Positioned(
                  right: Spacing.md,
                  bottom: Spacing.md,
                  child: AnimatedScale(
                    scale: _showScrollFab ? 1.0 : 0.0,
                    duration: AnimDurations.fast,
                    curve: AnimCurves.easeOut,
                    child: FloatingActionButton.small(
                      onPressed: _scrollToTop,
                      tooltip: 'Scroll to top',
                      child: const Icon(Icons.keyboard_arrow_up, size: IconSizes.lg),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    switch (_tab) {
      case _FeedTab.following:
        return AppEmptyState(
          title: 'No posts from followed residents',
          description: 'Follow residents to see their posts here',
          icon: Icons.people_outline,
        );
      case _FeedTab.announcements:
        return AppEmptyState(
          title: 'No announcements yet',
          description: 'Announcements from world moderators will appear here',
          icon: Icons.campaign_outlined,
        );
      case _FeedTab.all:
        return AppEmptyState(
          title: 'No posts yet',
          description: 'Be the first to share something with the community!',
          icon: Icons.auto_awesome,
        );
    }
  }

  void _showCreatePost(BuildContext context, Resident? resident) {
    final worldId = resident?.joinedWorldIds.isNotEmpty == true
        ? resident!.joinedWorldIds.first
        : 'nexus';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PostInput(worldId: worldId, showWorldSelector: true),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// Sort posts by the selected sort mode.
  List<Post> _sortPosts(List<Post> posts, _FeedSort sort) {
    final sorted = List<Post>.from(posts);
    switch (sort) {
      case _FeedSort.latest:
        sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case _FeedSort.hot:
        sorted.sort((a, b) {
          final aReactions = a.reactions.values.fold<int>(0, (sum, v) => sum + v);
          final bReactions = b.reactions.values.fold<int>(0, (sum, v) => sum + v);
          return bReactions.compareTo(aReactions);
        });
        break;
      case _FeedSort.top:
        sorted.sort((a, b) => b.comments.length.compareTo(a.comments.length));
        break;
    }
    return sorted;
  }

  /// Build the list of story users from recent posts.
  ///
  /// First item is always "My Story" (current resident).
  /// Remaining items are unique residents from posts within the last 24 hours.
  List<_StoryUser> _getStoryUsers(Resident? resident, List<Post> allPosts) {
    final result = <_StoryUser>[];

    // My Story always present when resident exists
    if (resident != null) {
      result.add(_StoryUser(
        residentId: resident.id,
        name: 'My Story',
        avatarUrl: resident.avatarUrl,
        isMyStory: true,
      ));
    }

    // Find unique recent posters (last 24 hours)
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneDayAgo = now - (24 * 60 * 60 * 1000);

    final seenIds = <String>{};
    if (resident != null) seenIds.add(resident.id);

    for (final post in allPosts) {
      if (post.timestamp < oneDayAgo) continue;
      if (seenIds.contains(post.residentId)) continue;

      seenIds.add(post.residentId);
      final name = post.residentName.length > 10
          ? '${post.residentName.substring(0, 9)}...'
          : post.residentName;
      result.add(_StoryUser(
        residentId: post.residentId,
        name: name,
        avatarUrl: post.residentAvatar,
      ));

      // Limit to 10 stories total (1 my story + 9 others)
      if (result.length >= 10) break;
    }

    return result;
  }
}

// ────────────────────────────────────────────────────────────────────
// Story / Status row
// ────────────────────────────────────────────────────────────────────

class _StoryUser {
  final String residentId;
  final String name;
  final String avatarUrl;
  final bool isMyStory;

  const _StoryUser({
    required this.residentId,
    required this.name,
    required this.avatarUrl,
    this.isMyStory = false,
  });
}

class _StoryRow extends StatelessWidget {
  final List<_StoryUser> storyUsers;
  final void Function(String residentId) onTap;

  const _StoryRow({required this.storyUsers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: SizedBox(
        height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          itemCount: storyUsers.length,
          itemBuilder: (context, index) {
            final user = storyUsers[index];
            return Padding(
              padding: EdgeInsets.only(
                right: index < storyUsers.length - 1 ? Spacing.md : 0,
              ),
              child: _StoryCircle(
                user: user,
                onTap: () => onTap(user.residentId),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final _StoryUser user;
  final VoidCallback onTap;

  const _StoryCircle({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient border ring around a 64px circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: AppColors.gradientPrimary,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              // Inner padding creates the 2px border effect
              padding: const EdgeInsets.all(BorderWidth.thick),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.avatarUrl),
                      radius: 30,
                    ),
                    // "+" overlay for My Story
                    if (user.isMyStory)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.seed,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            // Resident name
            Text(
              user.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: FontSizes.caption,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Create Post card (mini composer)
// ────────────────────────────────────────────────────────────────────

class _CreatePostCard extends StatelessWidget {
  final Resident? resident;
  final VoidCallback onTap;

  const _CreatePostCard({required this.resident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = resident?.avatarUrl ?? 'https://via.placeholder.com/150';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm + 4,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl),
                  radius: 20,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    "What's on your mind?",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Icon(
                  Icons.image_outlined,
                  size: IconSizes.md,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: Spacing.sm),
                Icon(
                  Icons.send_outlined,
                  size: IconSizes.md,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Tab chip
// ────────────────────────────────────────────────────────────────────

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
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
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

// ────────────────────────────────────────────────────────────────────
// Sort dropdown
// ────────────────────────────────────────────────────────────────────

class _SortDropdown extends StatelessWidget {
  final _FeedSort currentSort;
  final ValueChanged<_FeedSort> onChanged;

  const _SortDropdown({required this.currentSort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final label = switch (currentSort) {
      _FeedSort.latest => 'Latest',
      _FeedSort.hot => 'Hot',
      _FeedSort.top => 'Top',
    };

    return PopupMenuButton<_FeedSort>(
      initialValue: currentSort,
      onSelected: onChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _FeedSort.latest,
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: IconSizes.sm,
                color: currentSort == _FeedSort.latest
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: Spacing.sm),
              Text('Latest'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _FeedSort.hot,
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: IconSizes.sm,
                color: currentSort == _FeedSort.hot
                    ? AppColors.streakOrange
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: Spacing.sm),
              Text('Hot'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _FeedSort.top,
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                size: IconSizes.sm,
                color: currentSort == _FeedSort.top
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: Spacing.sm),
              Text('Top'),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Daily Quests card
// ────────────────────────────────────────────────────────────────────

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
      color:
          allDone ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
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
                Text(
                  '${questState.completedCount}/${quests.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
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
                      color: done
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
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
                    Text(
                      '${q.progress}/${q.target}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    if (done && !claimed) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () =>
                            ref.read(questProvider.notifier).claimQuest(q.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${q.xpReward} XP',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
