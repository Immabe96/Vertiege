import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/world.dart';
import '../models/post.dart';
import '../state/world_provider.dart';
import '../state/post_provider.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/worlds/world_icon.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_SearchResult> _search(String q) {
    if (q.length < 2) return [];
    final lower = q.toLowerCase();

    final results = <_SearchResult>[];

    // Worlds
    final worlds = ref.read(worldProvider).worlds.values;
    for (final w in worlds) {
      if (w.name.toLowerCase().contains(lower) || w.description.toLowerCase().contains(lower)) {
        results.add(_SearchResult(type: _ResultType.world, world: w));
      }
    }

    // Posts
    final posts = ref.read(postProvider).posts;
    for (final p in posts) {
      if (p.content.toLowerCase().contains(lower) || p.residentName.toLowerCase().contains(lower)) {
        results.add(_SearchResult(type: _ResultType.post, post: p));
      }
    }

    // Sort: worlds first, then posts by recency
    results.sort((a, b) {
      if (a.type != b.type) return a.type == _ResultType.world ? -1 : 1;
      if (a.type == _ResultType.post) {
        return (b.post?.timestamp ?? 0).compareTo(a.post?.timestamp ?? 0);
      }
      return a.world!.name.compareTo(b.world!.name);
    });

    return results.take(20).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _query.length >= 2 ? _search(_query) : <_SearchResult>[];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search worlds, posts...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _query.length < 2
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('Search worlds and posts', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text('Type at least 2 characters', style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  )),
                ],
              ),
            )
          : results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 12),
                      Text('No results for "$_query"', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final r = results[index];
                    return FadeIn(
                      delayMs: index * 30,
                      child: r.type == _ResultType.world ? _worldTile(theme, r.world!) : _postTile(theme, r.post!),
                    );
                  },
                ),
    );
  }

  Widget _worldTile(ThemeData theme, World world) {
    return ListTile(
      leading: WorldIcon(worldId: world.id, size: 36),
      title: Text(world.name, style: theme.textTheme.bodyLarge),
      subtitle: Text(world.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/explore/${world.id}'),
    );
  }

  Widget _postTile(ThemeData theme, Post post) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(post.residentAvatar),
        radius: 18,
      ),
      title: Text(post.residentName, style: theme.textTheme.labelLarge),
      subtitle: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text('#${post.worldId}', style: theme.textTheme.labelSmall),
      onTap: () => context.push('/explore/${post.worldId}'),
    );
  }
}

enum _ResultType { world, post }

class _SearchResult {
  final _ResultType type;
  final World? world;
  final Post? post;

  const _SearchResult({required this.type, this.world, this.post});
}
