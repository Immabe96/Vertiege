import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/world_service.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/feedback/v_states.dart';
import '../../utils/v_motion.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/sync_warning_banner.dart';
import '../../widgets/feed/post_item.dart';
import '../../widgets/nexus/feed_sort_dropdown.dart';
import '../../widgets/nexus/nexus_context_strip.dart';
import '../../widgets/nexus/nexus_feed_header.dart';
import '../../widgets/nexus/nexus_inline_compose.dart';
import '../../widgets/nexus/nexus_shortcuts_section.dart';
import 'package:vertiege/l10n/app_localizations.dart';
import '../../screens/tabs/tab_layout.dart';
import '../../utils/nexus_feed_sort.dart';
import '../../utils/verified_moment.dart';

enum _NexusFeedTab { all, verified, following, announcements }

/// Scrollable Nexus feed: sort tabs, posts, pull-to-refresh.
///
/// When [embedded] is true (Commune Home center panel), omits chrome sections
/// and uses [VCommuneColors.surfacePrimary] — Home already supplies the top bar.
class NexusFeedBody extends ConsumerStatefulWidget {
  final bool embedded;

  const NexusFeedBody({super.key, this.embedded = false});

  @override
  ConsumerState<NexusFeedBody> createState() => _NexusFeedBodyState();
}

class _NexusFeedBodyState extends ConsumerState<NexusFeedBody> {
  _NexusFeedTab _tab = _NexusFeedTab.all;
  FeedSort _sort = FeedSort.latest;
  late final ScrollController _scrollController;
  bool _showScrollFab = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFeedWhenReady();
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final show = _scrollController.offset > 400;
    if (show != _showScrollFab) {
      setState(() => _showScrollFab = show);
    }

    final postState = ref.read(postProvider);
    if (!postState.hasMorePosts || postState.isLoadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    if (_scrollController.offset >= maxScroll - 320) {
      unawaited(ref.read(postProvider.notifier).loadMoreNexusPosts());
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: VAnimation.normal,
      curve: VAnimation.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(scrollToTopProvider, (_, next) => _scrollToTop());
    final resident = ref.watch(residentProvider).resident;
    final theme = Theme.of(context);

    final posts = ref.watch(
      postProvider.select((postState) {
        final joinedIds =
            resident?.joinedWorldIds
                .where(WorldService.isRemoteWorldId)
                .toSet() ??
            {};
        var filtered = switch (_tab) {
          _NexusFeedTab.all =>
            postState.posts
                .where(
                  (p) =>
                      isNexusFeedWorld(p.worldId) ||
                      joinedIds.isEmpty ||
                      joinedIds.contains(p.worldId),
                )
                .toList(),
          _NexusFeedTab.verified =>
            postState.posts.where(isVerifiedMomentPost).toList(),
          _NexusFeedTab.following => postState.posts.where((p) {
            if (!joinedIds.contains(p.worldId)) return false;
            final inMutual = postState.mutualWorldResidentIds.contains(
              p.residentId,
            );
            final follows = resident?.following.contains(p.residentId) ?? false;
            return inMutual && follows;
          }).toList(),
          _NexusFeedTab.announcements =>
            postState.posts
                .where(
                  (p) =>
                      p.isAnnouncement &&
                      (joinedIds.isEmpty || joinedIds.contains(p.worldId)),
                )
                .toList(),
        };

        return sortNexusFeedPosts(filtered, _sort);
      }),
    );

    final postError = ref.watch(postProvider.select((s) => s.error));
    final postHasError = ref.watch(postProvider.select((s) => s.hasError));
    final postIsLoading = ref.watch(postProvider.select((s) => s.isLoading));
    final postIsLoadingMore = ref.watch(
      postProvider.select((s) => s.isLoadingMore),
    );
    final postHasMore = ref.watch(postProvider.select((s) => s.hasMorePosts));

    final joinedRemoteIds =
        resident?.joinedWorldIds.where(WorldService.isRemoteWorldId).toList() ??
        [];
    final joinedRemoteWorlds = joinedRemoteIds.length;

    final feed = Stack(
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
                // Standalone Nexus tab uses the shell FAB for compose; inline only when embedded.
                if (widget.embedded)
                  const SliverToBoxAdapter(child: NexusInlineCompose()),
                if (widget.embedded) ...[
                  SliverToBoxAdapter(
                    child: NexusContextStrip(
                      showJoinWorldsCta: joinedRemoteWorlds == 0,
                      useCommuneStyle: true,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: NexusShortcutsSection(),
                  ),
                ] else ...[
                  SliverToBoxAdapter(
                    child: NexusContextStrip(
                      showJoinWorldsCta: joinedRemoteWorlds == 0,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: NexusShortcutsSection(),
                  ),
                ],
                SliverToBoxAdapter(
                  child: NexusFeedHeader(
                    isDark: true,
                    allSelected: _tab == _NexusFeedTab.all,
                    verifiedSelected: _tab == _NexusFeedTab.verified,
                    followingSelected: _tab == _NexusFeedTab.following,
                    announcementsSelected: _tab == _NexusFeedTab.announcements,
                    currentSort: _sort,
                    onSortChanged: (s) => setState(() => _sort = s),
                    onAllTap: () => setState(() => _tab = _NexusFeedTab.all),
                    onVerifiedTap: () =>
                        setState(() => _tab = _NexusFeedTab.verified),
                    onFollowingTap: () =>
                        setState(() => _tab = _NexusFeedTab.following),
                    onAnnouncementsTap: () =>
                        setState(() => _tab = _NexusFeedTab.announcements),
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
                if (postIsLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(VSpacing.md),
                      child: Center(child: VSpinner()),
                    ),
                  )
                else if (posts.isNotEmpty && !postHasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.md),
                      child: Center(
                        child: Text(
                          'You\'re all caught up',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: VCommuneColors.textMutedOf(Brightness.dark),
                          ),
                        ),
                      ),
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
    );

    if (widget.embedded) {
      return ColoredBox(
        color: VCommuneColors.surfacePrimary,
        child: feed,
      );
    }
    return feed;
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final resident = ref.read(residentProvider).resident;
    final hasJoinedWorlds =
        resident?.joinedWorldIds.any(WorldService.isRemoteWorldId) ?? false;

    switch (_tab) {
      case _NexusFeedTab.verified:
        return AppEmptyState(
          title: 'No verified moments yet',
          description:
              'Submit achievement proof. When it\'s verified and shared, '
              'it shows up here.',
          icon: Icons.verified_outlined,
          illustration: EmptyStateIllustration.nexus,
          actionLabel: 'Submit proof',
          onAction: () => context.push('/achievements/submit'),
        );
      case _NexusFeedTab.following:
        return AppEmptyState(
          title: 'Nobody you follow has posted',
          description: 'Find residents in Worlds or Chat, then follow them.',
          icon: Icons.people_outline,
          actionLabel: 'Browse worlds',
          onAction: () => context.go('/worlds'),
        );
      case _NexusFeedTab.announcements:
        return AppEmptyState(
          title: 'No announcements yet',
          description: 'World admins post decrees here when something matters.',
          icon: Icons.campaign_outlined,
          actionLabel: 'Browse worlds',
          onAction: () => context.go('/worlds'),
          secondaryActionLabel: hasJoinedWorlds ? 'Open Chat' : null,
          onSecondaryAction:
              hasJoinedWorlds ? () => context.go('/chat') : null,
        );
      case _NexusFeedTab.all:
        if (!hasJoinedWorlds) {
          return AppEmptyState(
            title: 'Your Nexus is waiting',
            description:
                'Join a world, then submit proof. Your feed fills as you '
                'and your worlds share verified moments.',
            icon: Icons.dynamic_feed_outlined,
            illustration: EmptyStateIllustration.nexus,
            actionLabel: 'Browse worlds',
            onAction: () => context.go('/worlds'),
            secondaryActionLabel: 'Submit proof',
            onSecondaryAction: () => context.push('/achievements/submit'),
          );
        }
        return AppEmptyState(
          title: l10n.emptyFirstPost,
          description:
              'Share standing with the compose button, or submit achievement '
              'proof so verified moments can appear here.',
          icon: Icons.auto_awesome,
          illustration: EmptyStateIllustration.nexus,
          actionLabel: 'Submit proof',
          onAction: () => context.push('/achievements/submit'),
          secondaryActionLabel: 'Open Chat',
          onSecondaryAction: () => context.go('/chat'),
        );
    }
  }
}
