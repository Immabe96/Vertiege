import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/world.dart';
import '../models/post.dart';
import '../models/resident.dart';
import '../state/world_provider.dart';
import '../state/post_provider.dart';
import '../services/world_service.dart';
import '../theme/design_system.dart';
import '../theme/colors.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/core/shimmer.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/worlds/world_icon.dart';

const _recentSearchesKey = '@recent_searches';
const _maxRecentSearches = 5;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  List<String> _recentSearches = [];
  List<_ResidentEntry> _allResidents = [];
  bool _loadingResidents = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadAllResidents();
    _focusNode.addListener(() {
      if (mounted) setState(() {}); // Rebuild to show/hide recent searches
    });
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

  /// Loads all known residents by fetching members from all worlds and deduplicating.
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
        } catch (_) {
          // Skip worlds where member fetch fails
        }
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
    if (q.length < 2) return const _SearchResults();
    final lower = q.toLowerCase();

    final worlds = <World>[];
    final residents = <_ResidentEntry>[];
    final posts = <Post>[];

    // Worlds
    final allWorlds = ref.read(worldProvider).worlds.values;
    for (final w in allWorlds) {
      if (w.name.toLowerCase().contains(lower) ||
          w.description.toLowerCase().contains(lower)) {
        worlds.add(w);
      }
    }
    worlds.sort((a, b) => a.name.compareTo(b.name));

    // Residents (by name and profession)
    for (final entry in _allResidents) {
      final r = entry.resident;
      if (r.name.toLowerCase().contains(lower) ||
          (r.profession != null &&
              r.profession!.toLowerCase().contains(lower))) {
        residents.add(entry);
      }
    }
    residents.sort((a, b) => a.resident.name.compareTo(b.resident.name));

    // Posts
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
    final isFocused = _focusNode.hasFocus;
    final showRecent =
        isFocused && _controller.text.isEmpty && _recentSearches.isNotEmpty;
    final results = _query.length >= 2 ? _search(_query) : null;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          style: const TextStyle(color: AppColors.ink),
          onChanged: (v) {
            setState(() => _query = v);
            if (v.isEmpty) {
              setState(() {}); // Re-show recent searches
            }
          },
          onSubmitted: _onSubmitted,
          decoration: const InputDecoration(
            hintText: 'Search worlds, people, posts...',
            hintStyle: TextStyle(color: AppColors.inkMuted),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.glassBackground,
            suffixIcon: null, // handled dynamically
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _buildBody(theme, results, showRecent),
    );
  }

  Widget _buildBody(ThemeData theme, _SearchResults? results, bool showRecent) {
    // Recent searches (when field is focused and empty)
    if (showRecent) {
      return _buildRecentSearches(theme);
    }

    // Empty query prompt
    if (_query.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: IconSizes.hero, color: AppColors.inkMuted),
            const SizedBox(height: Spacing.md),
            Text(
              'Search worlds, people, and posts',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Type at least 2 characters',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      );
    }

    // Results
    if (results == null || results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: IconSizes.xl,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: Spacing.sm + 4),
            Text('No results for "$_query"', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(worldProvider.notifier).loadWorlds();
        await ref.read(postProvider.notifier).loadPosts();
        setState(() {}); // re-run search after data reloads
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        children: [
          // ── Worlds Section ─────────────────
          _SectionHeader(
            icon: Icons.public,
            title: 'Worlds',
            count: results.worlds.length,
          ),
          if (results.worlds.isEmpty)
            _EmptySection(text: 'No worlds found')
          else
            ...results.worlds.map((w) => _WorldTile(world: w)),

          const Divider(height: 1, color: AppColors.glassBorder),

          // ── People Section ─────────────────
          _SectionHeader(
            icon: Icons.people,
            title: 'People',
            count: results.residents.length,
          ),
          if (_loadingResidents)
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: const Pulse(width: double.infinity, height: 48),
            )
          else if (results.residents.isEmpty)
            _EmptySection(text: 'No people found')
          else
            ...results.residents.take(20).map((r) => _PersonTile(entry: r)),

          const Divider(height: 1, color: AppColors.glassBorder),

          // ── Posts Section ─────────────────
          _SectionHeader(
            icon: Icons.forum,
            title: 'Posts',
            count: results.posts.length,
          ),
          if (results.posts.isEmpty)
            _EmptySection(text: 'No posts found')
          else
            ...results.posts.take(20).map((p) => _PostTile(post: p)),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.md,
            Spacing.md,
            Spacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: IconSizes.md,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Recent searches',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeights.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
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
                    deleteIcon: const Icon(Icons.close, size: IconSizes.xs + 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.glassBackground,
                    side: const BorderSide(color: AppColors.glassBorder),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Section Header — gold bar style like explore_screen
// ──────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.xs,
      ),
      child: Row(
        children: [
          // Gold bar
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Icon(icon, size: IconSizes.md, color: AppColors.primary),
          const SizedBox(width: Spacing.sm),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeights.bold,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeights.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Empty Section
// ──────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final String text;

  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// World Tile — glass container
// ──────────────────────────────────────────────────────────

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
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        child: GlassPanel(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: WorldIcon(worldId: world.id, size: 36),
            title: Text(
              world.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeights.bold,
              ),
            ),
            subtitle: Text(
              world.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/explore/${world.id}'),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Person Tile — glass container
// ──────────────────────────────────────────────────────────

class _PersonTile extends StatelessWidget {
  final _ResidentEntry entry;

  const _PersonTile({required this.entry});

  IconData _tierIcon(ResidentTier tier) {
    return switch (tier) {
      ResidentTier.apex => Icons.diamond,
      ResidentTier.oldMoney => Icons.workspace_premium,
      ResidentTier.elite => Icons.military_tech,
      ResidentTier.highRollers => Icons.stars,
      ResidentTier.hustlers => Icons.person,
    };
  }

  Color _tierColor(ResidentTier tier) {
    return switch (tier) {
      ResidentTier.apex => AppColors.gemPink,
      ResidentTier.oldMoney => AppColors.gold,
      ResidentTier.elite => AppColors.silver,
      ResidentTier.highRollers => AppColors.bronze,
      ResidentTier.hustlers => AppColors.offline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resident = entry.resident;

    return FadeIn(
      delayMs: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        child: GlassPanel(
          padding: EdgeInsets.zero,
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
                      fontWeight: FontWeights.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Icon(
                  _tierIcon(resident.tier),
                  size: IconSizes.xs + 4,
                  color: _tierColor(resident.tier),
                ),
              ],
            ),
            subtitle: resident.profession != null
                ? Text(
                    resident.profession!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  )
                : null,
            trailing: TextButton(
              onPressed: () => context.push('/residents/${resident.id}'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('View Profile'),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Post Tile — glass container
// ──────────────────────────────────────────────────────────

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
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        child: GlassPanel(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: CosmeticAvatar(
              imageUrl: post.residentAvatar,
              seed: post.residentId,
              size: 36,
            ),
            title: Text(
              post.residentName,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeights.bold,
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
            onTap: () => context.push('/explore/${post.worldId}'),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Data types
// ──────────────────────────────────────────────────────────

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
