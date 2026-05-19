import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/tiers.dart';
import '../models/rank.dart';
import '../services/rank_service.dart';
import '../services/world_service.dart';
import '../state/resident_provider.dart';
import '../theme/v_colors.dart';
import '../theme/design_system.dart';
import '../utils/tier_utils.dart';
import '../services/crash_reporter.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/empty_state.dart';
import '../ui/buttons/v_button.dart';
import '../ui/icons/v_icons.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;
    final currentResidentId = ref.watch(residentProvider).resident?.id;
    final canManageRanks = currentResidentId == widget.sovereignId;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        title: Text('${widget.worldName} — Members'),
        actions: [
          IconButton(
            icon: const Icon(VIcons.search),
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

                    ),
                    child: FadeIn(
                      delayMs: index * 40,
                      child: FCard(


                        child: InkWell(
                          onTap: () => context.push('/residents/$residentId'),

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
                                                  color: isDark
                                                      ? VColors.onSurfaceDark
                                                      : VColors.onSurface,
                                                ),
                                          ),
                                        ),
                                        if (isSovereign) ...[
                                          const SizedBox(width: Spacing.sm),
                                          Container(

                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: VColors.tertiary,

                                                  ),
                                            ),
                                            child: Text(
                                              'SOVEREIGN',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: VColors.onTertiary,
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

                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tierColor.withValues(
                                              alpha: 0.15,
                                            ),

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
                                                color: VColors.tertiary,
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
                                  color: VColors.tertiary,
                                  onPressed: () => _showRankManager(
                                    residentId: residentId,
                                    residentName: name,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.chevron_right,
                                  color: isDark
                                      ? VColors.outlineVariantDark
                                      : VColors.outlineVariant,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark
          ? VColors.surfaceContainerHighDark
          : VColors.surfaceContainerHigh,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(

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
                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
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
                    VButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(ctx),
                      variant: ButtonVariant.text,
                    ),
                    const Spacer(),
                    VButton(
                      label: 'Save',
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
          VButton(
            label: 'Clear',
            onPressed: () {
              setState(() => _search = '');
              Navigator.pop(ctx);
            },
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Done',
            onPressed: () => Navigator.pop(ctx),
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
       vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
       vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.glassBackgroundDark
            : VColors.glassBackground,

        border: Border.all(
          color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
        ),
      ),
      child: Text(
        '+$count',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(
          color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
        ),
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
  return value == null ? VColors.tertiary : Color(value);
}
