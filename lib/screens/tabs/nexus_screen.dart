import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/resident_provider.dart';
import '../../state/post_provider.dart';
import '../../models/post.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/core/notification_bell.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/feed/post_item.dart';
import '../../widgets/profile/luminary_nameplate.dart';
import '../../widgets/nexus/bento_grid.dart';
import '../../widgets/nexus/bento_cards/daily_quest_card.dart';
import '../../widgets/nexus/bento_cards/prestige_progress_card.dart';
import '../../widgets/nexus/bento_cards/season_snapshot_card.dart';
import '../../widgets/nexus/bento_cards/trending_card.dart';
import '../../widgets/nexus/bento_cards/feed_preview_card.dart';
import '../../widgets/nexus/feed_tab_chip.dart';
import '../../widgets/nexus/feed_sort_dropdown.dart';

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
    final greeting = _getGreeting();

    var posts = switch (_tab) {
      _FeedTab.all => allPosts,
      _FeedTab.following =>
        allPosts.where((p) => resident?.following.contains(p.residentId) ?? false).toList(),
      _FeedTab.announcements => allPosts.where((p) => p.isAnnouncement).toList(),
    };

    posts = _sortPosts(posts, _sort);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              toolbarHeight: 56,
              elevation: 0,
              backgroundColor: AppColors.surface.withAlpha(204),
              title: Text(
                'Vertiege',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.headlineMd,
                  fontWeight: FontWeights.bold,
                  color: AppColors.tertiary,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: AppColors.inkSecondary),
                  tooltip: 'Search',
                  onPressed: () => context.push('/search'),
                ),
                NotificationBell(
                  onPress: () => context.push('/notifications'),
                ),
              ],
            ),
          ),
        ),
      ),
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
                  SliverToBoxAdapter(
                    child: FadeIn(
                      delayMs: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Nexus Activity',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: FontSizes.headlineLg,
                                fontWeight: FontWeights.semiBold,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: Spacing.sm),
                            GlassPanel(
                              padding: const EdgeInsets.all(Spacing.lg),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: LuminaryNameplate(
                                            name: '$greeting, ${resident?.name ?? 'Traveler'}',
                                            tier: resident?.tier.value ?? 1,
                                            fontSize: FontSizes.bodyLg,
                                            title: resident?.title,
                                          ),
                                        ),
                                        if (resident != null) ...[
                                          const SizedBox(width: Spacing.sm),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: Spacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryContainer,
                                              borderRadius: BorderRadius.circular(RadiusTokens.pill),
                                            ),
                                            child: Text(
                                              resident.tier.label,
                                              style: const TextStyle(
                                                fontSize: FontSizes.labelSm,
                                                fontWeight: FontWeights.bold,
                                                color: AppColors.onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                          if (resident.streakCount > 0) ...[
                                            const SizedBox(width: Spacing.sm),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: Spacing.sm,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.warning.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(RadiusTokens.pill),
                                                border: Border.all(
                                                  color: AppColors.warning.withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.local_fire_department,
                                                    size: 14,
                                                    color: AppColors.warning,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${resident.streakCount}',
                                                    style: const TextStyle(
                                                      fontSize: FontSizes.labelSm,
                                                      fontWeight: FontWeights.bold,
                                                      color: AppColors.warning,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: FadeIn(
                      delayMs: 10,
                      child: const BentoGrid(
                        cards: [
                          BentoCard(
                            child: PrestigeProgressCard(),
                            size: BentoSize.medium,
                          ),
                          BentoCard(
                            child: DailyQuestCard(),
                            size: BentoSize.small,
                          ),
                          BentoCard(
                            child: SeasonSnapshotCard(),
                            size: BentoSize.small,
                          ),
                          BentoCard(
                            child: TrendingCard(),
                            size: BentoSize.large,
                          ),
                          BentoCard(
                            child: FeedPreviewCard(),
                            size: BentoSize.large,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: FadeIn(
                      delayMs: 30,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            FeedTabChip(
                              label: 'All',
                              selected: _tab == _FeedTab.all,
                              onTap: () => setState(() => _tab = _FeedTab.all),
                            ),
                            const SizedBox(width: 6),
                            FeedTabChip(
                              label: 'Following',
                              selected: _tab == _FeedTab.following,
                              onTap: () => setState(() => _tab = _FeedTab.following),
                            ),
                            const SizedBox(width: 6),
                            FeedTabChip(
                              label: 'Announcements',
                              selected: _tab == _FeedTab.announcements,
                              icon: Icons.campaign,
                              onTap: () => setState(() => _tab = _FeedTab.announcements),
                            ),
                            const Spacer(),
                            FeedSortDropdown(
                              currentSort: _sort,
                              onChanged: (s) => setState(() => _sort = s),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

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
                      backgroundColor: AppColors.glassBackground,
                      foregroundColor: AppColors.primary,
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  List<Post> _sortPosts(List<Post> posts, FeedSort sort) {
    final sorted = List<Post>.from(posts);
    switch (sort) {
      case FeedSort.latest:
        sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case FeedSort.hot:
        sorted.sort((a, b) {
          final aReactions = a.reactions.values.fold<int>(0, (sum, v) => sum + v);
          final bReactions = b.reactions.values.fold<int>(0, (sum, v) => sum + v);
          return bReactions.compareTo(aReactions);
        });
        break;
      case FeedSort.top:
        sorted.sort((a, b) => b.comments.length.compareTo(a.comments.length));
        break;
    }
    return sorted;
  }
}
