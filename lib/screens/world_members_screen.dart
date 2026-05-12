import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/tiers.dart';
import '../models/rank.dart';
import '../services/rank_service.dart';
import '../services/world_service.dart';
import '../state/resident_provider.dart';
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
  List<Rank> _ranks = [];
  Map<String, List<String>> _rankIdsByResident = {};
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await WorldService.getMembers(widget.worldId);
      final ranks = await RankService.fetchWorldRanks(widget.worldId);
      final rankIdsByResident = await RankService.fetchWorldRankAssignments(
        worldId: widget.worldId,
        residentIds: members
            .map((member) => member['resident_id'] as String? ?? '')
            .toList(),
      );
      if (mounted) {
        setState(() {
          _members = members;
          _ranks = ranks;
          _rankIdsByResident = rankIdsByResident;
          _loading = false;
        });
      }
    } catch (e, s) {
      reportError(e, s, hint: 'loadWorldMembers');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load members';
        });
      }
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
    final currentResidentId = ref.watch(residentProvider).resident?.id;
    final canManageRanks = currentResidentId == widget.sovereignId;

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
              title: _search.isNotEmpty ? 'No members found' : 'No members yet',
              description: _search.isNotEmpty
                  ? 'No members match "$_search".'
                  : 'This world has no members yet.',
              icon: _search.isNotEmpty
                  ? Icons.search_off
                  : Icons.people_outline,
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _load();
                await Future<void>.delayed(const Duration(milliseconds: 200));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(Spacing.md),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final m = filtered[index];
                  final residentId = m['resident_id'] as String? ?? '';
                  final name = m['resident_name'] as String? ?? 'Member';
                  final rep = m['rep'] as int? ?? 0;
                  final standing = getStanding(rep);
                  final isSovereign = residentId == widget.sovereignId;
                  final tierColor = tierStandingColor(standing.level);
                  final memberRanks = _ranksForResident(residentId);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < filtered.length - 1 ? Spacing.sm : 0,
                    ),
                    child: FadeIn(
                      delayMs: index * 40,
                      child: GlassPanel(
                        padding: const EdgeInsets.all(Spacing.md),
                        borderRadius: BorderRadius.circular(RadiusTokens.xl),
                        child: InkWell(
                          onTap: () => context.push('/residents/$residentId'),
                          borderRadius: BorderRadius.circular(RadiusTokens.xl),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                child: Text(name.substring(0, 1).toUpperCase()),
                              ),
                              const SizedBox(width: Spacing.md),

                              // Name + badges
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight:
                                                      FontWeights.semiBold,
                                                  color: AppColors.ink,
                                                ),
                                          ),
                                        ),
                                        if (isSovereign) ...[
                                          const SizedBox(width: Spacing.sm),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: Spacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.tertiary,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    RadiusTokens.pill,
                                                  ),
                                            ),
                                            child: Text(
                                              'SOVEREIGN',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: AppColors.onTertiary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: Spacing.xs),
                                    Row(
                                      children: [
                                        // Tier badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: Spacing.sm,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tierColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              RadiusTokens.pill,
                                            ),
                                          ),
                                          child: Text(
                                            standing.title,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(color: tierColor),
                                          ),
                                        ),
                                        const SizedBox(width: Spacing.sm),
                                        // Reputation
                                        Text(
                                          'Rep $rep',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: AppColors.tertiary,
                                              ),
                                        ),
                                      ],
                                    ),
                                    if (memberRanks.isNotEmpty) ...[
                                      const SizedBox(height: Spacing.xs),
                                      Wrap(
                                        spacing: Spacing.xs,
                                        runSpacing: Spacing.xs,
                                        children: [
                                          for (final rank in memberRanks.take(
                                            3,
                                          ))
                                            _RankChip(rank: rank),
                                          if (memberRanks.length > 3)
                                            _MoreRanksChip(
                                              count: memberRanks.length - 3,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              if (canManageRanks)
                                IconButton(
                                  tooltip: 'Manage ranks',
                                  icon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    size: IconSizes.md,
                                  ),
                                  color: AppColors.tertiary,
                                  onPressed: () => _showRankManager(
                                    residentId: residentId,
                                    residentName: name,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.outline,
                                  size: IconSizes.lg,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  List<Rank> _ranksForResident(String residentId) {
    final assigned = _rankIdsByResident[residentId]?.toSet() ?? const {};
    if (assigned.isEmpty) return const [];
    return _ranks.where((rank) => assigned.contains(rank.id)).toList();
  }

  Future<void> _showRankManager({
    required String residentId,
    required String residentName,
  }) async {
    if (_ranks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create ranks in world settings first.')),
      );
      return;
    }

    final selected = (_rankIdsByResident[residentId] ?? const <String>[])
        .toSet();
    final original = Set<String>.from(selected);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceHigh,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              Spacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ranks for $residentName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeights.bold,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final rank in _ranks)
                        CheckboxListTile(
                          value: selected.contains(rank.id),
                          onChanged: (value) {
                            setSheetState(() {
                              if (value == true) {
                                selected.add(rank.id);
                              } else {
                                selected.remove(rank.id);
                              }
                            });
                          },
                          activeColor: _parseRankColor(rank.colorHex),
                          title: Text(rank.name),
                          subtitle: Text(_rankSummary(rank)),
                          secondary: _RankDot(rank: rank),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () async {
                        final toAdd = selected.difference(original);
                        final toRemove = original.difference(selected);
                        for (final rankId in toAdd) {
                          await RankService.assignRank(
                            residentId: residentId,
                            rankId: rankId,
                          );
                        }
                        for (final rankId in toRemove) {
                          await RankService.removeRank(
                            residentId: residentId,
                            rankId: rankId,
                          );
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        await _load();
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _rankSummary(Rank rank) {
    final enabled = rank.edicts.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .take(3)
        .join(', ');
    if (enabled.isEmpty) return 'No edicts enabled';
    return enabled;
  }

  void _showSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search members'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search by name...'),
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

class _RankChip extends StatelessWidget {
  final Rank rank;

  const _RankChip({required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = _parseRankColor(rank.colorHex);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        rank.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _MoreRanksChip extends StatelessWidget {
  final int count;

  const _MoreRanksChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        '+$count',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
      ),
    );
  }
}

class _RankDot extends StatelessWidget {
  final Rank rank;

  const _RankDot({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: _parseRankColor(rank.colorHex),
        shape: BoxShape.circle,
      ),
    );
  }
}

Color _parseRankColor(String hex) {
  final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
  final value = int.tryParse('FF$normalized', radix: 16);
  return value == null ? AppColors.tertiary : Color(value);
}
