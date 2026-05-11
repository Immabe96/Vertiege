import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/tiers.dart';
import '../services/world_service.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../utils/tier_utils.dart';
import '../services/crash_reporter.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/core/loading_state.dart';


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
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final members = await WorldService.getMembers(widget.worldId);
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (e, s) {
      reportError(e, s, hint: 'loadWorldMembers');
      if (mounted) setState(() { _loading = false; _error = 'Failed to load members'; });
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
          ? const GlassLoadingList(itemCount: 6)
          : _error != null
              ? AppErrorState(message: _error, onRetry: _load)
              : filtered.isEmpty
              ? AppEmptyState(
                  title: _search.isNotEmpty
                      ? 'No members found'
                      : 'No members yet',
                  description: _search.isNotEmpty
                      ? 'No members match "$_search".'
                      : 'This world has no members yet.',
                  icon: _search.isNotEmpty
                      ? Icons.search_off
                      : Icons.people_outline,
                  variant: EmptyStateVariant.default_,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _load();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 200));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final m = filtered[index];
                      final residentId =
                          m['resident_id'] as String? ?? '';
                      final name =
                          m['resident_name'] as String? ?? 'Member';
                      final rep = m['rep'] as int? ?? 0;
                      final standing = getStanding(rep);
                      final isSovereign =
                          residentId == widget.sovereignId;
                      final tierColor = tierStandingColor(standing.level);

                      return Padding(
                        padding:
                            EdgeInsets.only(bottom: index < filtered.length - 1 ? Spacing.sm : 0),
                        child: FadeIn(
                          delayMs: index * 40,
                          child: GlassPanel(
                            padding: const EdgeInsets.all(Spacing.md),
                            borderRadius: BorderRadius.circular(
                                RadiusTokens.xl),
                            child: InkWell(
                              onTap: () => context
                                  .push('/residents/$residentId'),
                              borderRadius: BorderRadius.circular(
                                  RadiusTokens.xl),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    child: Text(name
                                        .substring(0, 1)
                                        .toUpperCase()),
                                  ),
                                  const SizedBox(width: Spacing.md),

                                  // Name + badges
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                overflow: TextOverflow
                                                    .ellipsis,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight:
                                                      FontWeights.semiBold,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                            ),
                                            if (isSovereign) ...[
                                              const SizedBox(
                                                  width: Spacing.sm),
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: Spacing.sm,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.tertiary,
                                                  borderRadius: BorderRadius
                                                      .circular(RadiusTokens
                                                          .pill),
                                                ),
                                                child: Text(
                                                  'SOVEREIGN',
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: AppColors
                                                        .onTertiary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(
                                            height: Spacing.xs),
                                        Row(
                                          children: [
                                            // Tier badge
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                horizontal: Spacing.sm,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: tierColor
                                                    .withValues(
                                                        alpha: 0.15),
                                                borderRadius: BorderRadius
                                                    .circular(RadiusTokens
                                                        .pill),
                                              ),
                                              child: Text(
                                                standing.title,
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: tierColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                width: Spacing.sm),
                                            // Reputation
                                            Text(
                                              'Rep $rep',
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color: AppColors.tertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  Icon(Icons.chevron_right,
                                      color: AppColors.outline,
                                      size: IconSizes.lg),
                                ],
                              ),
                              // Rank chips — loaded via _loadRanks
                            ),
                          ),
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
