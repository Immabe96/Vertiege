import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/world_navigation.dart';
import '../models/world.dart';
import '../models/post.dart';
import '../models/resident.dart';
import '../state/world_provider.dart';
import '../state/post_provider.dart';
import '../state/resident_provider.dart';
import '../state/ally_provider.dart';
import '../services/world_service.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/fade_in.dart';
import '../ui/icons/v_icons.dart';
import '../widgets/core/shimmer.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/worlds/world_icon.dart';
import '../widgets/shared/tier_icon.dart';

const _recentSearchesKey = '@recent_searches';
const _maxRecentSearches = 5;

enum _SearchMode { all, following, allies }

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
  bool _appliedRouteQuery = false;
  List<String> _recentSearches = [];
  List<_ResidentEntry> _allResidents = [];
  bool _loadingResidents = true;

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
      final normalized =
          decoded.startsWith('#') ? decoded.substring(1) : decoded;
      _controller.text = normalized;
      _query = normalized;
    }
    final mode = params['mode'] ?? params['tab'];
    if (mode == 'following') {
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
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
    try {
      final worldState = ref.read(worldProvider);
      final worldIds = worldState.worlds.keys.toList();
      final allMembers = <String, _ResidentEntry>{};

      for (final worldId in worldIds) {
        try {
          final members = await WorldService.getMembers(worldId);
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
                  avatarUrl: '',
                ),
                rep: m['rep'] ?? 0,
              );
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _allResidents = allMembers.values.toList();
          _loadingResidents = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingResidents = false);
    }
  }

  _SearchResults _search(String q) {
    final resident = ref.read(residentProvider).resident;
    if (_mode == _SearchMode.following && resident != null && q.length < 2) {
      final followingIds = resident.following.toSet();
      final residents = _allResidents
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
      final residents = _allResidents
          .where((e) => allyIds.contains(e.resident.id))
          .toList()
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

    for (final entry in _allResidents) {
      final r = entry.resident;
      if (r.name.toLowerCase().contains(lower) ||
          (r.profession != null &&
              r.profession!.toLowerCase().contains(lower))) {
        residents.add(entry);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFocused = _focusNode.hasFocus;
    final showRecent =
        isFocused && _controller.text.isEmpty && _recentSearches.isNotEmpty;
    final results = _query.length >= 2 || _mode != _SearchMode.all
        ? _search(_query)
        : null;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          style: TextStyle(
            color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
          ),
          onChanged: (v) {
            setState(() => _query = v);
            if (v.isEmpty) {
              setState(() {});
            }
          },
          onSubmitted: _onSubmitted,
          decoration: InputDecoration(
            hintText: 'Search worlds, people, posts...',
            hintStyle: TextStyle(
              color: isDark
                  ? VColors.onSurfaceVariantDark.withValues(alpha: 0.6)
                  : VColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark
                    ? VColors.outlineVariantDark
                    : VColors.outlineVariant,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark
                    ? VColors.outlineVariantDark
                    : VColors.outlineVariant,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: VColors.primary, width: 2),
            ),
            filled: true,
            fillColor: isDark
                ? VColors.surfaceContainerDark
                : VColors.surfaceContainerLow,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(VIcons.x),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _buildBody(theme, results, showRecent, isDark),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    _SearchResults? results,
    bool showRecent,
    bool isDark,
  ) {
    if (showRecent) {
      return _buildRecentSearches(theme, isDark);
    }

    if (_query.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
            const SizedBox(height: VSpacing.md),
            Text(
              'Search worlds, people, and posts',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              'Type at least 2 characters',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark.withValues(alpha: 0.6)
                    : VColors.onSurfaceVariant.withValues(alpha: 0.6),
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
            Icon(
              Icons.search_off,
              size: VIconSize.xl,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              'No results for "$_query"',
              style: theme.textTheme.bodyLarge,
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
      child: ListView(
        padding: const EdgeInsets.only(bottom: VSpacing.lg),
        children: [
          _SectionHeader(
            icon: Icons.public,
            title: 'Worlds',
            count: results.worlds.length,
            isDark: isDark,
          ),
          if (results.worlds.isEmpty)
            _EmptySection(text: 'No worlds found', isDark: isDark)
          else
            ...results.worlds.map((w) => _WorldTile(world: w)),

          Divider(
            height: 1,
            color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
          ),

          _SectionHeader(
            icon: Icons.people,
            title: 'People',
            count: results.residents.length,
            isDark: isDark,
          ),
          if (_loadingResidents)
            Padding(
              padding: const EdgeInsets.all(VSpacing.md),
              child: const Pulse(width: double.infinity, height: 48),
            )
          else if (results.residents.isEmpty)
            _EmptySection(text: 'No people found', isDark: isDark)
          else
            ...results.residents.take(20).map((r) => _PersonTile(entry: r)),

          Divider(
            height: 1,
            color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
          ),

          _SectionHeader(
            icon: Icons.forum,
            title: 'Posts',
            count: results.posts.length,
            isDark: isDark,
          ),
          if (results.posts.isEmpty)
            _EmptySection(text: 'No posts found', isDark: isDark)
          else
            ...results.posts.take(20).map((p) => _PostTile(post: p)),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            VSpacing.md,
            VSpacing.md,
            VSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: VIconSize.md,
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
              const SizedBox(width: VSpacing.sm),
              Text(
                'Recent searches',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                  fontWeight: VFontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
          child: Wrap(
            spacing: VSpacing.sm,
            runSpacing: VSpacing.xs,
            children: _recentSearches
                .map(
                  (q) => InputChip(
                    label: Text(q, style: theme.textTheme.labelSmall),
                    onPressed: () {
                      _controller.text = q;
                      setState(() => _query = q);
                      _focusNode.unfocus();
                    },
                    onDeleted: () => _removeRecentSearch(q),
                    deleteIcon: const Icon(VIcons.x, size: 14),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.md,
        VSpacing.md,
        VSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: VColors.tertiary,
              borderRadius: BorderRadius.circular(VRadius.sm),
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Icon(icon, size: VIconSize.md, color: VColors.primary),
          const SizedBox(width: VSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: VColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(VRadius.pill),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: VColors.primary,
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
  final bool isDark;

  const _EmptySection({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark
              ? VColors.onSurfaceVariantDark
              : VColors.onSurfaceVariant,
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
    final isDark = theme.brightness == Brightness.dark;

    return FadeIn(
      delayMs: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.xs,
        ),
        child: Material(
          color: isDark
              ? VColors.surfaceContainerDark
              : VColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: InkWell(
            onTap: () => context.push(exploreWorldPath(world.id)),
            borderRadius: BorderRadius.circular(VRadius.lg),
            child: ListTile(
              leading: WorldIcon(
                worldId: world.assetKey,
                size: 36,
                useGlassContainer: false,
              ),
              title: Text(
                world.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              subtitle: Text(
                world.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(VIcons.chevronRight),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final _ResidentEntry entry;

  const _PersonTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = entry.resident;

    return FadeIn(
      delayMs: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.xs,
        ),
        child: Material(
          color: isDark
              ? VColors.surfaceContainerDark
              : VColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: InkWell(
            onTap: () => context.push(residentProfilePath(resident.id)),
            borderRadius: BorderRadius.circular(VRadius.lg),
            child: ListTile(
              leading: CosmeticAvatar(
                imageUrl: resident.avatarUrl,
                seed: resident.id,
                size: 40,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      resident.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: VFontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: VSpacing.xs),
                  TierIcon(tier: resident.tier.value, size: 18),
                ],
              ),
              subtitle: resident.profession != null
                  ? Text(
                      resident.profession!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                    )
                  : null,
              trailing: Text(
                'View',
                style: TextStyle(
                  color: VColors.primary,
                  fontWeight: VFontWeight.medium,
                ),
              ),
            ),
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
    final isDark = theme.brightness == Brightness.dark;

    return FadeIn(
      delayMs: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.xs,
        ),
        child: Material(
          color: isDark
              ? VColors.surfaceContainerDark
              : VColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: InkWell(
            onTap: () => context.push(
              exploreWorldPath(post.worldId, postId: post.id),
            ),
            borderRadius: BorderRadius.circular(VRadius.lg),
            child: ListTile(
              leading: CosmeticAvatar(
                imageUrl: post.residentAvatar,
                seed: post.residentId,
                size: 36,
              ),
              title: Text(
                post.residentName,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              subtitle: Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '#${post.worldId}',
                style: theme.textTheme.labelSmall,
              ),
            ),
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
