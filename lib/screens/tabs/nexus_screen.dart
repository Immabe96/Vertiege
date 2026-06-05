import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import '../../state/resident_provider.dart';
import '../../services/world_service.dart';
import '../../state/post_provider.dart';
import '../../widgets/core/tab_aware_sheet.dart';
import '../../state/notification_provider.dart';
import '../../models/post.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_context_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/v_motion.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/sync_warning_banner.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/feed/post_item.dart';
import '../../widgets/nexus/feed_sort_dropdown.dart';
import '../../services/onboarding_funnel_prefs.dart';
import '../../services/onboarding_funnel_sync.dart';
import '../../widgets/core/v_feedback.dart';
import '../../widgets/nexus/nexus_context_strip.dart';
import '../../widgets/nexus/season_nexus_banner.dart';
import '../../widgets/nexus/nexus_feed_header.dart';
import '../../widgets/nexus/nexus_shortcuts_section.dart';
import '../tabs/tab_layout.dart';
import 'nexus_notifications_sheet.dart';
import '../../services/notification_onboarding_prefs.dart';
import '../../widgets/onboarding/notification_permission_sheet.dart';
import '../../router/search_navigation.dart';

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
  bool _shortcutsExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadFeedWhenReady());
      unawaited(_onNexusOpened());
    });
  }

  Future<void> _loadFeedWhenReady() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    final postState = ref.read(postProvider);
    if (postState.posts.isEmpty && !postState.isLoading) {
      await ref.read(postProvider.notifier).loadPosts();
    }
  }

  Future<void> _onNexusOpened() async {
    final residentId = ref.read(residentProvider).resident?.id;
    if (residentId != null) {
      await OnboardingFunnelSync.markOpenedNexus(residentId);
    } else {
      await OnboardingFunnelPrefs.markOpenedNexus();
    }
    if (!mounted) return;
    final welcome = await OnboardingFunnelPrefs.consumeJustFinishedOnboarding();
    if (welcome && mounted) {
      VFeedback.showMessage(
        context,
        'Welcome! Your Nexus feed fills as you join worlds and submit proof.',
      );
    }
    if (!mounted) return;
    if (await NotificationOnboardingPrefs.shouldPrompt()) {
      await showNotificationPermissionSheet(context);
    }
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
      duration: VAnimation.normal,
      curve: VAnimation.standard,
    );
  }

  void _showNotifications() {
    showTabAwareModalBottomSheet(
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
        final joinedIds =
            resident?.joinedWorldIds
                .where(WorldService.isRemoteWorldId)
                .toSet() ??
            {};
        var filtered = switch (_tab) {
          _FeedTab.all =>
            postState.posts
                .where(
                  (p) => joinedIds.isEmpty || joinedIds.contains(p.worldId),
                )
                .toList(),
          _FeedTab.following => postState.posts.where((p) {
            if (!joinedIds.contains(p.worldId)) return false;
            final inMutual = postState.mutualWorldResidentIds.contains(
              p.residentId,
            );
            final follows = resident?.following.contains(p.residentId) ?? false;
            return inMutual && follows;
          }).toList(),
          _FeedTab.announcements =>
            postState.posts
                .where(
                  (p) =>
                      p.isAnnouncement &&
                      (joinedIds.isEmpty || joinedIds.contains(p.worldId)),
                )
                .toList(),
        };

        return _sortPosts(filtered, _sort);
      }),
    );

    final postError = ref.watch(postProvider.select((s) => s.error));
    final postHasError = ref.watch(postProvider.select((s) => s.hasError));
    final postIsLoading = ref.watch(postProvider.select((s) => s.isLoading));

    final joinedRemoteWorlds =
        resident?.joinedWorldIds.where(WorldService.isRemoteWorldId).length ??
        0;

    final headerActions = <Widget>[
      VAccessibleHeaderAction(
        label: 'Search residents and worlds',
        icon: Icon(VIcons.search),
        onPress: () => openGlobalSearch(context),
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
                Icon(VIcons.bell),
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
      header: VHeader(
        title: Text(
          'Vertiege',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
        suffixes: headerActions,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(postProvider.notifier).loadPosts();
                await Future<void>.delayed(const Duration(milliseconds: 200));
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: NexusContextStrip(
                      showJoinWorldsCta: joinedRemoteWorlds == 0,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SeasonNexusBanner()),
                  SliverToBoxAdapter(
                    child: NexusShortcutsSection(
                      expanded: _shortcutsExpanded,
                      onExpandedChanged: (v) =>
                          setState(() => _shortcutsExpanded = v),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: NexusFeedHeader(
                      isDark: isDark,
                      allSelected: _tab == _FeedTab.all,
                      followingSelected: _tab == _FeedTab.following,
                      announcementsSelected: _tab == _FeedTab.announcements,
                      currentSort: _sort,
                      onSortChanged: (s) => setState(() => _sort = s),
                      onAllTap: () => setState(() => _tab = _FeedTab.all),
                      onFollowingTap: () =>
                          setState(() => _tab = _FeedTab.following),
                      onAnnouncementsTap: () =>
                          setState(() => _tab = _FeedTab.announcements),
                    ),
                  ),

                  if (postHasError && posts.isEmpty)
                    SliverToBoxAdapter(
                      child: AppErrorState(
                        message: postError ?? 'Something went wrong',
                        onRetry: () =>
                            ref.read(postProvider.notifier).loadPosts(),
                      ),
                    )
                  else if (postHasError && posts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          VSpacing.md,
                          VSpacing.sm,
                          VSpacing.md,
                          0,
                        ),
                        child: SyncWarningBanner(
                          message: postError!,
                          onRetry: () =>
                              ref.read(postProvider.notifier).loadPosts(),
                        ),
                      ),
                    )
                  else if (postIsLoading && posts.isEmpty)
                    const SliverToBoxAdapter(child: ScreenLoading.feed())
                  else if (posts.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            PostItem(post: posts[index], index: index),
                        childCount: posts.length,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          VSpacing.xxl + MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              ),
            ),
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
    );
  }

  Widget _buildEmptyState() {
    final resident = ref.read(residentProvider).resident;
    final hasJoinedWorlds =
        resident?.joinedWorldIds.any(WorldService.isRemoteWorldId) ?? false;

    switch (_tab) {
      case _FeedTab.following:
        return const AppEmptyState(
          title: 'No posts from people you follow',
          description: 'Follow members in your worlds to see their posts here',
          icon: Icons.people_outline,
        );
      case _FeedTab.announcements:
        return const AppEmptyState(
          title: 'No announcements yet',
          description: 'Admin announcements from your worlds will appear here',
          icon: Icons.campaign_outlined,
        );
      case _FeedTab.all:
        if (!hasJoinedWorlds) {
          return AppEmptyState(
            title: 'Join a world to fill your feed',
            description:
                'Browse worlds to submit achievement proof, earn reputation, '
                'and see posts from communities you join.',
            icon: Icons.explore_outlined,
            actionLabel: 'Browse worlds',
            onAction: () => context.go('/explore'),
          );
        }
        return const AppEmptyState(
          title: 'No posts in your worlds yet',
          description:
              'Share an update or visit a world feed to start the conversation.',
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
        sorted.sort((a, b) => b.comments.length.compareTo(a.comments.length));
        break;
    }
    return sorted;
  }
}
