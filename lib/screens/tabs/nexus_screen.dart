import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../forui/v_tab_page.dart';
import '../../state/resident_provider.dart';
import '../../services/world_service.dart';
import '../../state/post_provider.dart';
import '../../state/notification_provider.dart';
import '../../models/post.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/v_motion.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/feed/post_item.dart';
import '../../widgets/nexus/bento_grid.dart';
import '../../widgets/nexus/bento_cards/daily_quest_card.dart';
import '../../widgets/nexus/bento_cards/prestige_progress_card.dart';
import '../../widgets/nexus/bento_cards/season_snapshot_card.dart';
import '../../widgets/nexus/bento_cards/trending_card.dart';
import '../../widgets/nexus/bento_cards/spotlight_card.dart';
import '../../widgets/nexus/bento_cards/challenges_card.dart';
import '../../widgets/nexus/bento_cards/league_card.dart';
import '../../widgets/nexus/feed_tab_chip.dart';
import '../../widgets/nexus/feed_sort_dropdown.dart';
import '../tabs/tab_layout.dart';
import 'nexus_notifications_sheet.dart';

enum _FeedTab { all, following, announcements }

class NexusScreen extends ConsumerStatefulWidget {
  const NexusScreen({super.key});

  @override
  ConsumerState<NexusScreen> createState() => _NexusScreenState();
}

class _NexusScreenState extends ConsumerState<NexusScreen> {
  _FeedTab _tab = _FeedTab.all;
  FeedSort _sort = FeedSort.latest;
  late final ScrollController _scrollController;
  bool _showScrollFab = false;
  bool _searchExpanded = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final postState = ref.read(postProvider);
      if (postState.posts.isEmpty && !postState.isLoading) {
        ref.read(postProvider.notifier).loadPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
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
      duration: VAnimation.normal,
      curve: VAnimation.standard,
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchExpanded = !_searchExpanded;
      if (!_searchExpanded) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
    if (_searchExpanded) {
      FocusScope.of(context).unfocus();
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NexusNotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(scrollToTopProvider, (_, next) => _scrollToTop());
    final resident = ref.watch(residentProvider).resident;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final posts = ref.watch(
      postProvider.select((postState) {
        final joinedIds = resident?.joinedWorldIds
                .where(WorldService.isRemoteWorldId)
                .toSet() ??
            {};
        var filtered = switch (_tab) {
          _FeedTab.all => postState.posts
              .where((p) => joinedIds.isEmpty || joinedIds.contains(p.worldId))
              .toList(),
          _FeedTab.following => postState.posts.where((p) {
            if (!joinedIds.contains(p.worldId)) return false;
            final inMutual =
                postState.mutualWorldResidentIds.contains(p.residentId);
            final follows =
                resident?.following.contains(p.residentId) ?? false;
            return inMutual && follows;
          }).toList(),
          _FeedTab.announcements => postState.posts
              .where(
                (p) =>
                    p.isAnnouncement &&
                    (joinedIds.isEmpty || joinedIds.contains(p.worldId)),
              )
              .toList(),
        };

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filtered = filtered
              .where(
                (p) =>
                    p.content.toLowerCase().contains(q) ||
                    p.residentName.toLowerCase().contains(q),
              )
              .toList();
        }

        return _sortPosts(filtered, _sort);
      }),
    );

    final postError = ref.watch(
      postProvider.select((s) => s.error),
    );
    final postHasError = ref.watch(
      postProvider.select((s) => s.hasError),
    );
    final postIsLoading = ref.watch(
      postProvider.select((s) => s.isLoading),
    );

    final headerActions = <Widget>[
      VAccessibleHeaderAction(
        label: _searchExpanded ? 'Close search' : 'Search',
        icon: Icon(_searchExpanded ? FIcons.x : FIcons.search),
        onPress: _toggleSearch,
      ),
      VAccessibleHeaderAction(
        label: 'Notifications',
        icon: Consumer(
          builder: (context, ref, _) {
            final unread = ref.watch(
              notificationProvider.select(
                (s) => s.notifications.where((n) => !n.read).length,
              ),
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(FIcons.bell),
                if (unread > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: VColors.error,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: VColors.onError,
                          fontSize: VFontSize.labelSm,
                          fontWeight: VFontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        onPress: _showNotifications,
      ),
    ];

    return VTabPage(
      header: FHeader(
        title: _searchExpanded
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search posts, residents...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(
                'Vertiege',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
        suffixes: headerActions,
      ),
      body: RefreshIndicator(
            onRefresh: () async {
              await ref.read(postProvider.notifier).loadPosts();
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(VSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Nexus',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: VFontWeight.semiBold,
                                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: VSpacing.xs),
                            Text(
                              'Progress and shortcuts — your feed is below.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: BentoGrid(
                        cards: [
                          const BentoCard(
                            child: PrestigeProgressCard(),
                            size: BentoSize.medium,
                          ),
                          BentoCard(
                            child: const DailyQuestCard(),
                            size: BentoSize.small,
                            onTap: () => context.push('/daily-quests'),
                          ),
                          const BentoCard(
                            child: SeasonSnapshotCard(),
                            size: BentoSize.small,
                          ),
                          const BentoCard(
                            child: SpotlightCard(),
                            size: BentoSize.medium,
                          ),
                          BentoCard(
                            child: const ChallengesCard(),
                            size: BentoSize.small,
                            onTap: () => context.push('/challenges'),
                          ),
                          const BentoCard(
                            child: LeagueCard(),
                            size: BentoSize.small,
                          ),
                          const BentoCard(
                            child: TrendingCard(),
                            size: BentoSize.large,
                          ),
                        ],
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        FeedTabChip(
                                          label: 'All',
                                          selected: _tab == _FeedTab.all,
                                          onTap: () => setState(
                                            () => _tab = _FeedTab.all,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        FeedTabChip(
                                          label: 'Following',
                                          selected:
                                              _tab == _FeedTab.following,
                                          onTap: () => setState(
                                            () => _tab = _FeedTab.following,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        FeedTabChip(
                                          label: 'Announcements',
                                          selected:
                                              _tab == _FeedTab.announcements,
                                          icon: Icons.campaign,
                                          onTap: () => setState(
                                            () =>
                                                _tab = _FeedTab.announcements,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: VSpacing.sm),
                                FeedSortDropdown(
                                  currentSort: _sort,
                                  onChanged: (s) => setState(() => _sort = s),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (postHasError)
                      SliverToBoxAdapter(
                        child: AppErrorState(
                          message: postError ?? 'Something went wrong',
                          onRetry: () =>
                              ref.read(postProvider.notifier).loadPosts(),
                        ),
                      )
                    else if (postIsLoading && posts.isEmpty)
                      const SliverToBoxAdapter(
                        child: ScreenLoading.feed(),
                      )
                    else if (posts.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              PostItem(post: posts[index], index: index),
                          childCount: posts.length,
                        ),
                      ),
                  ],
                ),

                if (_showScrollFab)
                  Positioned(
                    right: VSpacing.md,
                    bottom: VSpacing.md,
                    child: AnimatedScale(
                      scale: _showScrollFab ? 1.0 : 0.0,
                      duration: context.motionDuration(VAnimation.fast),
                      curve: context.motionCurve,
                      child: FloatingActionButton.small(
                        onPressed: _scrollToTop,
                        tooltip: 'Scroll to top',
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          size: VIconSize.lg,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return AppEmptyState(
        title: 'No results for "$_searchQuery"',
        description: 'Try a different search term',
        icon: Icons.search_off,
      );
    }
    switch (_tab) {
      case _FeedTab.following:
        return const AppEmptyState(
          title: 'No posts from people you follow',
          description:
              'Follow residents in your worlds to see their posts here',
          icon: Icons.people_outline,
        );
      case _FeedTab.announcements:
        return const AppEmptyState(
          title: 'No announcements yet',
          description:
              'Announcements from world moderators will appear here',
          icon: Icons.campaign_outlined,
        );
      case _FeedTab.all:
        return const AppEmptyState(
          title: 'No posts yet',
          description: 'Be the first to share something with the community!',
          icon: Icons.auto_awesome,
        );
    }
  }

  List<Post> _sortPosts(List<Post> posts, FeedSort sort) {
    final sorted = List<Post>.from(posts);
    switch (sort) {
      case FeedSort.latest:
        sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case FeedSort.hot:
        sorted.sort((a, b) {
          final aReactions = a.reactions.values.fold<int>(
            0,
            (sum, v) => sum + v,
          );
          final bReactions = b.reactions.values.fold<int>(
            0,
            (sum, v) => sum + v,
          );
          return bReactions.compareTo(aReactions);
        });
        break;
      case FeedSort.top:
        sorted.sort(
          (a, b) => b.comments.length.compareTo(a.comments.length),
        );
        break;
    }
    return sorted;
  }
}
