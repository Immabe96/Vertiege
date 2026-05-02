import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/tiers.dart';
import '../services/world_service.dart';
import '../widgets/core/fade_in.dart';

class WorldMembersScreen extends ConsumerStatefulWidget {
  final String worldId;
  final String worldName;
  final String sovereignId;

  const WorldMembersScreen({
    super.key,
    required this.worldId,
    required this.worldName,
    required this.sovereignId,
  });

  @override
  ConsumerState<WorldMembersScreen> createState() => _WorldMembersScreenState();
}

class _WorldMembersScreenState extends ConsumerState<WorldMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await WorldService.getMembers(widget.worldId);
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _members;
    final q = _search.toLowerCase();
    return _members.where((m) {
      final name = (m['resident_name'] as String? ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.worldName} — Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Text(
                    _search.isNotEmpty ? 'No members match "$_search"' : 'No members yet',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _load();
                    await Future<void>.delayed(const Duration(milliseconds: 200));
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final m = filtered[index];
                      final residentId = m['resident_id'] as String? ?? '';
                      final name = m['resident_name'] as String? ?? 'Member';
                      final rep = m['rep'] as int? ?? 0;
                      final standing = getStanding(rep);
                      final isSovereign = residentId == widget.sovereignId;

                      return FadeIn(
                        delayMs: index * 40,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(name.substring(0, 1).toUpperCase()),
                          ),
                          title: Row(
                            children: [
                              Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
                              if (isSovereign) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
                              ],
                            ],
                          ),
                          subtitle: Text('${standing.title} · Rep $rep'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/residents/$residentId'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search members'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by name...',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _search = '');
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
