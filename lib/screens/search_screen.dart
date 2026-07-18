import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import '../utils/provider_errors.dart';
import '../utils/world_resident_count_label.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/sync_warning_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/world_navigation.dart';
import '../models/world.dart';
import '../models/post.dart';
import '../models/resident.dart';
import '../state/world_provider.dart';
import '../state/post_provider.dart';
import '../state/resident_provider.dart';
import '../state/chat_provider.dart';
import '../models/message.dart';
import '../state/ally_provider.dart';
import '../services/resident_search_service.dart';
import '../services/world_service.dart';
import '../theme/prestige_noir.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/shimmer.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/worlds/world_icon.dart';
import '../widgets/shared/tier_icon.dart';
import '../services/chat_service.dart';

const _recentSearchesKey = '@recent_searches';
const _maxRecentSearches = 5;

enum _SearchMode { all, following, allies }

enum _SearchCategory { all, worlds, people, posts }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  _SearchMode _mode = _SearchMode.all;
  _SearchCategory _category = _SearchCategory.all;
  bool _appliedRouteQuery = false;
  List<String> _recentSearches = [];
  List<_ResidentEntry> _allResidents = [];
  List<_ResidentEntry> _globalFtsResidents = [];
  bool _loadingResidents = true;
  bool _loadingGlobalSearch = false;
  String? _residentsLoadError;
  Timer? _ftsDebounce;
  bool _channelMode = false;
  String? _channelId;
  String? _channelName;
  String? _channelWorldId;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadAllResidents();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedRouteQuery) return;
    _appliedRouteQuery = true;
    final params = GoRouterState.of(context).uri.queryParameters;
    final q = params['q'];
    if (q != null && q.isNotEmpty) {
      final decoded = Uri.decodeComponent(q);
      final normalized = decoded.startsWith('#')
          ? decoded.substring(1)
          : decoded;
      _controller.text = normalized;
      _query = normalized;
    }
    final mode = params['mode'] ?? params['tab'];
    if (mode == 'channel') {
      _channelMode = true;
      _channelId = params['channelId'];
      _channelName = params['channelName'];
      _channelWorldId = params['worldId'];
      if (_channelId != null) {
        ref
            .read(chatProvider.notifier)
            .loadChannelMessages(_channelId!);
      }
    } else if (mode == 'following') {
      _mode = _SearchMode.following;
    } else if (mode == 'allies') {
      _mode = _SearchMode.allies;
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        ref.read(allyProvider.notifier).loadAll(resident.id);
      }
    }
  }

  @override
  void dispose() {
    _ftsDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleGlobalResidentSearch(String q) {
    _ftsDebounce?.cancel();
    if (_mode != _SearchMode.all || q.trim().length < 2) {
      if (_globalFtsResidents.isNotEmpty || _loadingGlobalSearch) {
        setState(() {
          _globalFtsResidents = [];
          _loadingGlobalSearch = false;
        });
      }
      return;
    }
    _ftsDebounce = Timer(const Duration(milliseconds: 320), () async {
      if (!mounted) return;
      setState(() => _loadingGlobalSearch = true);
      final hits = await ResidentSearchService.search(q.trim());
      if (!mounted) return;
      setState(() {
        _loadingGlobalSearch = false;
        _globalFtsResidents = hits
            .map(
              (h) => _ResidentEntry(
                resident: Resident(
                  id: h.id,
                  name: h.name,
                  profession: h.bioSnippet,
                  avatarUrl: h.avatarUrl ?? '',
                ),
                rep: 0,
              ),
            )
            .toList();
      });
    });
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentSearchesKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        setState(() => _recentSearches = list.cast<String>());
      } catch (_) {}
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final trimmed = query.trim();
    final updated = [trimmed, ..._recentSearches.where((s) => s != trimmed)];
    if (updated.length > _maxRecentSearches) {
      updated.removeRange(_maxRecentSearches, updated.length);
    }
    setState(() => _recentSearches = updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentSearchesKey, jsonEncode(updated));
  }

  Future<void> _removeRecentSearch(String query) async {
    final updated = _recentSearches.where((s) => s != query).toList();
    setState(() => _recentSearches = updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentSearchesKey, jsonEncode(updated));
  }

  Future<void> _loadAllResidents() async {
    setState(() {
      _loadingResidents = true;
      _residentsLoadError = null;
    });
    try {
      final worldState = ref.read(worldProvider);
      final worldIds = worldState.worlds.keys.toList();

      // Parallelize member fetches across all worlds.
      final results = await Future.wait([
        for (final worldId in worldIds)
          WorldService.getMembers(worldId).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final allMembers = <String, _ResidentEntry>{};
      for (final members in results) {
        for (final m in members) {
          final id = m['resident_id'] as String?;
          final name = m['resident_name'] as String?;
          final profession = m['profession'] as String?;
          final tierValue = m['standing'] as int?;
          if (id != null && name != null && !allMembers.containsKey(id)) {
            allMembers[id] = _ResidentEntry(
              resident: Resident(
                id: id,
                name: name,
                tier: ResidentTier.fromValue(tierValue ?? 1),
                profession: profession,
              ),
              rep: m['rep'] ?? 0,
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _allResidents = allMembers.values.toList();
          _loadingResidents = false;
          if (allMembers.isEmpty && worldIds.isNotEmpty) {
            _residentsLoadError =
                'Could not load residents from worlds. Try again.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingResidents = false;
          _residentsLoadError = userFacingLoadError(
            e,
            fallback: 'Could not load residents. Pull to refresh.',
          );
        });
      }
    }
  }

  List<ChannelMessage> _searchChannelMessages(String q) {
    if (_channelId == null) return [];
    final messages =
        ref.read(chatProvider).channelMessages[_channelId!] ?? [];
    if (q.trim().length < 2) return [];
    final lower = q.toLowerCase();
    return messages
        .where(
          (m) =>
              m.content.toLowerCase().contains(lower) ||
              m.senderName.toLowerCase().contains(lower),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  _SearchResults _search(String q) {
    final resident = ref.read(residentProvider).resident;
    if (_mode == _SearchMode.following && resident != null && q.length < 2) {
      final followingIds = resident.following.toSet();
      final residents =
          _allResidents
              .where((e) => followingIds.contains(e.resident.id))
              .toList()
            ..sort((a, b) => a.resident.name.compareTo(b.resident.name));
      return _SearchResults(residents: residents);
    }
    if (_mode == _SearchMode.allies && q.length < 2) {
      final allies = ref.read(allyProvider).allies;
      final allyIds = <String>{};
      for (final a in allies) {
        if (resident != null) {
          allyIds.add(
            a.requesterId == resident.id ? a.receiverId : a.requesterId,
          );
        }
      }
      final residents =
          _allResidents.where((e) => allyIds.contains(e.resident.id)).toList()
            ..sort((a, b) => a.resident.name.compareTo(b.resident.name));
      return _SearchResults(residents: residents);
    }

    if (q.length < 2) return const _SearchResults();
    final lower = q.toLowerCase();

    final worlds = <World>[];
    final residents = <_ResidentEntry>[];
    final posts = <Post>[];

    final allWorlds = ref.read(worldProvider).worlds.values;
    for (final w in allWorlds) {
      if (w.name.toLowerCase().contains(lower) ||
          w.description.toLowerCase().contains(lower)) {
        worlds.add(w);
      }
    }
    worlds.sort((a, b) => a.name.compareTo(b.name));

    final seenIds = <String>{};
    if (_mode == _SearchMode.all) {
      for (final entry in _globalFtsResidents) {
        seenIds.add(entry.resident.id);
        residents.add(entry);
      }
    }
    for (final entry in _allResidents) {
      final r = entry.resident;
      if (seenIds.contains(r.id)) continue;
      if (r.name.toLowerCase().contains(lower) ||
          (r.profession != null &&
              r.profession!.toLowerCase().contains(lower))) {
        residents.add(entry);
        seenIds.add(r.id);
      }
    }
    residents.sort((a, b) => a.resident.name.compareTo(b.resident.name));

    final allPosts = ref.read(postProvider).posts;
    for (final p in allPosts) {
      if (p.content.toLowerCase().contains(lower) ||
          p.residentName.toLowerCase().contains(lower)) {
        posts.add(p);
      }
    }
    posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return _SearchResults(
      worlds: worlds.take(10).toList(),
      residents: residents.take(10).toList(),
      posts: posts.take(10).toList(),
    );
  }

  void _onSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      _saveRecentSearch(query.trim());
    }
  }

  List<World> _trendingWorlds() {
    final worlds = ref.read(worldProvider).worlds.values.toList()
      ..sort((a, b) => b.activityScore.compareTo(a.activityScore));
    return worlds.where((w) => w.activityScore > 0).take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channelHits = _channelMode && _query.length >= 2
        ? _searchChannelMessages(_query)
        : <ChannelMessage>[];
    final results = !_channelMode &&
            (_query.length >= 2 || _mode != _SearchMode.all)
        ? _search(_query)
        : null;

    return VHubPage(
      title: '',
      titleWidget: _PrestigeSearchPill(
        controller: _controller,
        focusNode: _focusNode,
        hintText: _channelMode
            ? 'Search in #${_channelName ?? 'channel'}…'
            : 'Search worlds, residents, posts…',
        onChanged: (v) {
          setState(() => _query = v);
          _scheduleGlobalResidentSearch(v);
        },
        onSubmitted: _onSubmitted,
        onClear: () {
          _controller.clear();
          setState(() => _query = '');
        },
      ),
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_channelMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.md,
                VSpacing.sm,
                VSpacing.md,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.sm,
                  vertical: VSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: PrestigeNoir.surfaceRaised,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                  border: Border.all(color: PrestigeNoir.border),
                ),
                child: Text(
                  'in:#${_channelName ?? 'channel'}',
                  style: const TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: PrestigeNoir.accent,
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
              ),
            )
          else
            _buildFilterChips(),
          if (_residentsLoadError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.md,
                VSpacing.sm,
                VSpacing.md,
                0,
              ),
              child: SyncWarningBanner(
                message: _residentsLoadError!,
                onRetry: _loadAllResidents,
              ),
            ),
          Expanded(
            child: _channelMode
                ? _buildChannelBody(theme, channelHits)
                : _buildBody(theme, results),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PrestigeNoir.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.md,
          VSpacing.sm,
          VSpacing.md,
          VSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PrestigeFilterChip(
                    label: 'All',
                    selected: _mode == _SearchMode.all,
                    onTap: () => setState(() => _mode = _SearchMode.all),
                  ),
                  const SizedBox(width: 6),
                  _PrestigeFilterChip(
                    label: 'Following',
                    selected: _mode == _SearchMode.following,
                    onTap: () {
                      setState(() => _mode = _SearchMode.following);
                      final resident = ref.read(residentProvider).resident;
                      if (resident != null) {
                        ref.read(allyProvider.notifier).loadAll(resident.id);
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  _PrestigeFilterChip(
                    label: 'Allies',
                    selected: _mode == _SearchMode.allies,
                    onTap: () {
                      setState(() => _mode = _SearchMode.allies);
                      final resident = ref.read(residentProvider).resident;
                      if (resident != null) {
                        ref.read(allyProvider.notifier).loadAll(resident.id);
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_query.length >= 2) ...[
              const SizedBox(height: VSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PrestigeFilterChip(
                      label: 'Everything',
                      selected: _category == _SearchCategory.all,
                      onTap: () =>
                          setState(() => _category = _SearchCategory.all),
                    ),
                    const SizedBox(width: 6),
                    _PrestigeFilterChip(
                      label: 'Worlds',
                      selected: _category == _SearchCategory.worlds,
                      onTap: () =>
                          setState(() => _category = _SearchCategory.worlds),
                    ),
                    const SizedBox(width: 6),
                    _PrestigeFilterChip(
                      label: 'Residents',
                      selected: _category == _SearchCategory.people,
                      onTap: () =>
                          setState(() => _category = _SearchCategory.people),
                    ),
                    const SizedBox(width: 6),
                    _PrestigeFilterChip(
                      label: 'Posts',
                      selected: _category == _SearchCategory.posts,
                      onTap: () =>
                          setState(() => _category = _SearchCategory.posts),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChannelBody(
    ThemeData theme,
    List<ChannelMessage> hits,
  ) {
    if (_query.length < 2) {
      return Center(
        child: Text(
          'Type to search messages in #${_channelName ?? 'channel'}',
          style: const TextStyle(color: PrestigeNoir.muted),
        ),
      );
    }
    if (hits.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off,
        title: 'No messages found',
        description: 'Try different keywords',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(VSpacing.md),
      itemCount: hits.length,
      separatorBuilder: (_, _) => const SizedBox(height: VSpacing.sm),
      itemBuilder: (context, index) {
        final msg = hits[index];
        return VPrestigeCard(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          onTap: () {
            if (_channelWorldId != null && _channelId != null) {
              context.push(
                worldChannelPathFromParts(
                  _channelWorldId!,
                  channelId: _channelId!,
                  channelName: _channelName ?? '',
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.senderName,
                style: const TextStyle(
                  fontWeight: VFontWeight.semiBold,
                  color: PrestigeNoir.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                msg.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: VFontSize.bodySm,
                  color: PrestigeNoir.muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ThemeData theme, _SearchResults? results) {
    if (_query.length < 2 && _mode == _SearchMode.all) {
      return _buildExploreIdle(theme);
    }

    if (_query.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search,
              size: 64,
              color: PrestigeNoir.mutedDim,
            ),
            const SizedBox(height: VSpacing.md),
            Text(
              'Search worlds, residents, and posts',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: PrestigeNoir.muted,
              ),
            ),
            const SizedBox(height: VSpacing.xs),
            const Text(
              'Type at least 2 characters',
              style: TextStyle(
                fontSize: VFontSize.bodySm,
                color: PrestigeNoir.mutedDim,
              ),
            ),
          ],
        ),
      );
    }

    if (results == null || results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: VIconSize.xl,
              color: PrestigeNoir.mutedDim,
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              'No results for "$_query"',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: PrestigeNoir.foreground,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(worldProvider.notifier).loadWorlds();
        await ref.read(postProvider.notifier).loadPosts();
        setState(() {});
      },
      child: CustomScrollView(
        slivers: [
          if (_category == _SearchCategory.all ||
              _category == _SearchCategory.worlds) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.public,
                title: 'Worlds',
                count: results.worlds.length,
              ),
            ),
            if (results.worlds.isEmpty)
              SliverToBoxAdapter(
                child: _EmptySection(text: 'No worlds found'),
              )
            else
              SliverList.builder(
                itemCount: results.worlds.length,
                itemBuilder: (context, index) =>
                    _WorldTile(world: results.worlds[index]),
              ),
            if (_category == _SearchCategory.all)
              const SliverToBoxAdapter(
                child: SizedBox(height: VSpacing.sm),
              ),
          ],
          if (_category == _SearchCategory.all ||
              _category == _SearchCategory.people) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.people,
                title: 'Residents',
                count: results.residents.length,
              ),
            ),
            if (_loadingResidents)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(VSpacing.md),
                  child: Pulse(height: 48),
                ),
              )
            else if (results.residents.isEmpty)
              SliverToBoxAdapter(
                child: _EmptySection(text: 'No residents found'),
              )
            else
              SliverList.builder(
                itemCount: results.residents.length > 20
                    ? 20
                    : results.residents.length,
                itemBuilder: (context, index) =>
                    _PersonTile(entry: results.residents[index]),
              ),
            if (_category == _SearchCategory.all)
              const SliverToBoxAdapter(
                child: SizedBox(height: VSpacing.sm),
              ),
          ],
          if (_category == _SearchCategory.all ||
              _category == _SearchCategory.posts) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.forum,
                title: 'Posts',
                count: results.posts.length,
              ),
            ),
            if (results.posts.isEmpty)
              SliverToBoxAdapter(
                child: _EmptySection(text: 'No posts found'),
              )
            else
              SliverList.builder(
                itemCount: results.posts.length > 20
                    ? 20
                    : results.posts.length,
                itemBuilder: (context, index) =>
                    _PostTile(post: results.posts[index]),
              ),
          ],
          SliverToBoxAdapter(
            child: const SizedBox(height: VSpacing.lg),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreIdle(ThemeData theme) {
    final trending = _trendingWorlds();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.md,
        VSpacing.md,
        VSpacing.lg,
      ),
      children: [
        if (trending.isNotEmpty) ...[
          const VPrestigeSectionLabel(title: 'Trending now'),
          ...trending.map((world) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: VPrestigeCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.md,
                  vertical: 10,
                ),
                onTap: () => context.push(exploreWorldPath(world.id)),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            world.name,
                            style: const TextStyle(
                              fontSize: VFontSize.bodySm,
                              fontWeight: VFontWeight.semiBold,
                              color: PrestigeNoir.foreground,
                            ),
                          ),
                          Text(
                            'World · ${worldMemberCountLabel(world.memberCount)}',
                            style: const TextStyle(
                              fontSize: VFontSize.labelSm,
                              color: PrestigeNoir.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatActivity(world.activityScore),
                      style: const TextStyle(
                        fontSize: VFontSize.bodySm,
                        color: PrestigeNoir.mutedDim,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        if (_recentSearches.isNotEmpty) ...[
          const SizedBox(height: VSpacing.md),
          const VPrestigeSectionLabel(title: 'Recent searches'),
          ..._recentSearches.map(
            (q) => _RecentSearchRow(
              query: q,
              onTap: () {
                _controller.text = q;
                setState(() => _query = q);
                _scheduleGlobalResidentSearch(q);
                _focusNode.unfocus();
              },
              onRemove: () => _removeRecentSearch(q),
            ),
          ),
        ],
        if (trending.isEmpty && _recentSearches.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: VSpacing.xxl),
            child: Column(
              children: [
                const Icon(
                  Icons.search,
                  size: 64,
                  color: PrestigeNoir.mutedDim,
                ),
                const SizedBox(height: VSpacing.md),
                Text(
                  'Search worlds, residents, and posts',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: PrestigeNoir.muted,
                  ),
                ),
                const SizedBox(height: VSpacing.xs),
                const Text(
                  'Type at least 2 characters',
                  style: TextStyle(
                    fontSize: VFontSize.bodySm,
                    color: PrestigeNoir.mutedDim,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatActivity(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return '$score';
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.md,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: VIconSize.md, color: PrestigeNoir.accent),
          const SizedBox(width: VSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              fontWeight: VFontWeight.bold,
              color: PrestigeNoir.foreground,
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: PrestigeNoir.accentSoft,
              borderRadius: BorderRadius.circular(VRadius.pill),
              border: Border.all(color: PrestigeNoir.accent.withValues(alpha: 0.35)),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: VFontSize.labelSm,
                color: PrestigeNoir.accent,
                fontWeight: VFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;

  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: VFontSize.bodySm,
          color: PrestigeNoir.muted,
        ),
      ),
    );
  }
}

class _WorldTile extends StatelessWidget {
  final World world;

  const _WorldTile({required this.world});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeIn(
      delayMs: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.xs,
        ),
        child: VPrestigeCard(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          onTap: () => context.push(exploreWorldPath(world.id)),
          child: Row(
            children: [
              WorldIcon(
                worldId: world.assetKey,
                size: VWorldIconSize.dense,
                useGlassContainer: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: VFontWeight.bold,
                        color: PrestigeNoir.foreground,
                      ),
                    ),
                    Text(
                      world.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: VFontSize.bodySm,
                        color: PrestigeNoir.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                VIcons.chevronRight,
                size: VIconSize.sm,
                color: PrestigeNoir.mutedDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonTile extends ConsumerWidget {
  final _ResidentEntry entry;

  const _PersonTile({required this.entry});

  Future<void> _openDm(BuildContext context, WidgetRef ref) async {
    final me = ref.read(residentProvider).resident;
    final resident = entry.resident;
    if (me == null || me.id == resident.id) return;
    final room = await ChatService.getOrCreateRoom(me.id, resident.id);
    if (!context.mounted || room == null) return;
    final roomId = room['id'] as String?;
    if (roomId == null) return;
    context.push(chatRoomPath(roomId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resident = entry.resident;
    final me = ref.watch(residentProvider).resident;
    final canDm = me != null && me.id != resident.id;

    return FadeIn(
      delayMs: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.xs,
        ),
        child: VPrestigeCard(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          onTap: canDm
              ? () => _openDm(context, ref)
              : () => context.push(residentProfilePath(resident.id)),
          child: Row(
            children: [
              CosmeticAvatar(
                imageUrl: resident.avatarUrl,
                seed: resident.id,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            resident.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: VFontWeight.bold,
                              color: PrestigeNoir.foreground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: VSpacing.xs),
                        TierIcon(tier: resident.tier.value, size: VIconSize.base),
                      ],
                    ),
                    if (resident.profession != null)
                      Text(
                        resident.profession!,
                        style: const TextStyle(
                          fontSize: VFontSize.bodySm,
                          color: PrestigeNoir.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (canDm)
                VButton(
                  label: 'Message',
                  onPressed: () => _openDm(context, ref),
                  variant: ButtonVariant.text,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final Post post;

  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeIn(
      delayMs: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.xs,
        ),
        child: VPrestigeCard(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          onTap: () =>
              context.push(exploreWorldPath(post.worldId, postId: post.id)),
          child: Row(
            children: [
              CosmeticAvatar(
                imageUrl: post.residentAvatar,
                seed: post.residentId,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.residentName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: VFontWeight.bold,
                        color: PrestigeNoir.foreground,
                      ),
                    ),
                    Text(
                      post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: VFontSize.bodySm,
                        color: PrestigeNoir.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PrestigeNoir.surface,
                  borderRadius: BorderRadius.circular(VRadius.xs),
                  border: Border.all(color: PrestigeNoir.borderLight),
                ),
                child: Text(
                  '#${post.worldId}',
                  style: const TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: PrestigeNoir.mutedDim,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrestigeSearchPill extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  const _PrestigeSearchPill({
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  State<_PrestigeSearchPill> createState() => _PrestigeSearchPillState();
}

class _PrestigeSearchPillState extends State<_PrestigeSearchPill> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});
  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PrestigeNoir.surfaceRaised,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(
          color: widget.focusNode?.hasFocus == true
              ? PrestigeNoir.accent
              : PrestigeNoir.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
      child: Row(
        children: [
          const Icon(
            VIcons.search,
            size: VIconSize.md,
            color: PrestigeNoir.mutedDim,
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: true,
              cursorColor: PrestigeNoir.accent,
              style: const TextStyle(
                fontSize: VFontSize.bodySm,
                color: PrestigeNoir.foreground,
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: PrestigeNoir.mutedDim),
                // Kill theme fill + outline so only the pill gold border shows.
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty && widget.onClear != null)
            GestureDetector(
              onTap: widget.onClear,
              child: const Icon(
                VIcons.x,
                size: VIconSize.md,
                color: PrestigeNoir.mutedDim,
              ),
            ),
        ],
      ),
    );
  }
}

class _PrestigeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PrestigeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? PrestigeNoir.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? PrestigeNoir.accent : PrestigeNoir.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            fontWeight: selected ? VFontWeight.semiBold : VFontWeight.medium,
            color: selected ? PrestigeNoir.accent : PrestigeNoir.muted,
          ),
        ),
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchRow({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.history,
                size: VIconSize.denseSm,
                color: PrestigeNoir.mutedDim,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  query,
                  style: const TextStyle(
                    fontSize: VFontSize.bodySm,
                    color: PrestigeNoir.muted,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  VIcons.x,
                  size: VIconSize.denseSm,
                  color: PrestigeNoir.mutedDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults {
  final List<World> worlds;
  final List<_ResidentEntry> residents;
  final List<Post> posts;

  const _SearchResults({
    this.worlds = const [],
    this.residents = const [],
    this.posts = const [],
  });

  bool get isEmpty => worlds.isEmpty && residents.isEmpty && posts.isEmpty;
}

class _ResidentEntry {
  final Resident resident;
  final int rep;

  const _ResidentEntry({required this.resident, required this.rep});
}
