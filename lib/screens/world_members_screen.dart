import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../router/world_navigation.dart';
import '../config/tiers.dart';
import '../models/rank.dart';
import '../services/rank_service.dart';
import '../services/world_service.dart';
import '../state/resident_provider.dart';
import '../theme/v_colors.dart';
import '../forui/v_hub_page.dart';
import '../theme/v_tokens.dart';
import '../utils/tier_utils.dart';
import '../services/crash_reporter.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/empty_state.dart';
import '../ui/buttons/v_button.dart';
import '../ui/icons/v_icons.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/core/v_feedback.dart';

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

    return VHubPage(
      title: 'Members',
      showBack: true,
      headerActions: [
        FHeaderAction(
          icon: const Icon(VIcons.search),
          onPress: () => _showSearch(context),
        ),
      ],
      body: _loading
          ? const ScreenLoading.list()
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
                padding: const EdgeInsets.all(VSpacing.md),
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
                      bottom: index < filtered.length - 1 ? VSpacing.sm : 0,
                    ),
                    child: FadeIn(
                      delayMs: index * 40,
                      child: _Card(
                        padding: const EdgeInsets.all(VSpacing.md),
                        borderRadius: BorderRadius.circular(VRadius.xl),
                        child: InkWell(
                          onTap: () => context.push(residentProfilePath(residentId)),
                          borderRadius: BorderRadius.circular(VRadius.xl),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                child: Text(name.substring(0, 1).toUpperCase()),
                              ),
                              const SizedBox(width: VSpacing.md),

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
                                                      VFontWeight.semiBold,
                                                  color: isDark
                                                      ? VColors.onSurfaceDark
                                                      : VColors.onSurface,
                                                ),
                                          ),
                                        ),
                                        if (isSovereign) ...[
                                          const SizedBox(width: VSpacing.sm),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: VSpacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: VColors.tertiary,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    VRadius.pill,
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
                                    const SizedBox(height: VSpacing.xs),
                                    Row(
                                      children: [
                                        // Tier badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: VSpacing.sm,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tierColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              VRadius.pill,
                                            ),
                                          ),
                                          child: Text(
                                            standing.title,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(color: tierColor),
                                          ),
                                        ),
                                        const SizedBox(width: VSpacing.sm),
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
                                      const SizedBox(height: VSpacing.xs),
                                      Wrap(
                                        spacing: VSpacing.xs,
                                        runSpacing: VSpacing.xs,
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
                              const SizedBox(width: VSpacing.sm),
                              if (canManageRanks)
                                IconButton(
                                  tooltip: 'Manage ranks',
                                  icon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    size: VIconSize.md,
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
                                  size: VIconSize.lg,
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
      VFeedback.showMessage(context, 'Create ranks in world settings first.');
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
            padding: const EdgeInsets.fromLTRB(
              VSpacing.lg,
              VSpacing.sm,
              VSpacing.lg,
              VSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Ranks for $residentName',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                  fontWeight: VFontWeight.bold,
                ),
              ),
                const SizedBox(height: VSpacing.md),
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
                const SizedBox(height: VSpacing.md),
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
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(VRadius.pill),
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
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.glassBackgroundDark
            : VColors.glassBackground,
        borderRadius: BorderRadius.circular(VRadius.pill),
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

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;

  const _Card({required this.child, this.padding, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: borderRadius ?? BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}
