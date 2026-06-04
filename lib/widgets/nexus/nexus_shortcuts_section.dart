import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/world_navigation.dart';
import '../../state/resident_provider.dart';
import '../../services/nexus_bento_order.dart';
import '../../services/nexus_shortcut_prefs.dart';
import '../../theme/v_context_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/v_motion.dart';
import 'bento_grid.dart';
import 'bento_cards/challenges_card.dart';
import 'bento_cards/daily_quest_card.dart';
import 'bento_cards/league_card.dart';
import 'bento_cards/prestige_progress_card.dart';
import 'bento_cards/season_snapshot_card.dart';
import 'bento_cards/spotlight_card.dart';
import 'bento_cards/trending_card.dart';

/// Collapsible Nexus shortcuts — compact row by default so the feed stays near the top.
class NexusShortcutsSection extends ConsumerWidget {
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  const NexusShortcutsSection({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hideLeague =
        ref.watch(residentProvider).resident?.leaderboardOptOut == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.xs,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onExpandedChanged(!expanded),
              borderRadius: BorderRadius.circular(VRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: VSpacing.xs,
                  horizontal: VSpacing.xs,
                ),
                child: Row(
                  children: [
                    Text(
                      'Progress shortcuts',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: VFontWeight.semiBold,
                        color: context.vOnSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      expanded ? 'Less' : 'More',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: context.vOnSurfaceVariant,
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: context.vOnSurfaceVariant,
                      size: VIconSize.md,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: context.motionDuration(VAnimation.fast),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _CompactShortcutsRow(hideLeague: hideLeague),
            secondChild: BentoGrid(
              cards: [
                const BentoCard(
                  child: PrestigeProgressCard(),
                  size: BentoSize.medium,
                ),
                BentoCard(
                  child: const DailyQuestCard(),
                  size: BentoSize.small,
                  onTap: () => _openShortcut(context, 'quest', '/daily-quests'),
                ),
                BentoCard(
                  child: const SeasonSnapshotCard(),
                  size: BentoSize.small,
                  onTap: () => _openShortcut(context, 'season', '/season'),
                ),
                const BentoCard(
                  child: SpotlightCard(),
                  size: BentoSize.medium,
                ),
                BentoCard(
                  child: const ChallengesCard(),
                  size: BentoSize.small,
                  onTap: () => _openShortcut(context, 'challenges', '/challenges'),
                ),
                if (!hideLeague)
                  BentoCard(
                    child: const LeagueCard(),
                    size: BentoSize.small,
                    onTap: () =>
                        _openShortcut(context, 'league', leaguesPath()),
                  ),
                const BentoCard(
                  child: TrendingCard(),
                  size: BentoSize.medium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _openShortcut(BuildContext context, String id, String route) {
    unawaited(NexusShortcutPrefs.recordVisit(id));
    context.push(route);
  }
}

class _CompactShortcutsRow extends StatefulWidget {
  final bool hideLeague;

  const _CompactShortcutsRow({this.hideLeague = false});

  @override
  State<_CompactShortcutsRow> createState() => _CompactShortcutsRowState();
}

class _CompactShortcutsRowState extends State<_CompactShortcutsRow> {
  static final _defaultOrder = NexusBentoOrder.defaultOrder;

  List<String> _order = _defaultOrder;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final segmentOrder = NexusBentoOrder.compactShortcutOrder(_defaultOrder);
    final ordered = await NexusShortcutPrefs.orderByRecency(segmentOrder);
    if (mounted) setState(() => _order = ordered);
  }

  void _go(String id, VoidCallback onTap) {
    unawaited(NexusShortcutPrefs.recordVisit(id));
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = <_ShortcutDef>[
      _ShortcutDef(
        id: 'season',
        icon: Icons.auto_awesome,
        label: 'Season 1',
        onTap: () => context.push('/season'),
      ),
      _ShortcutDef(
        id: 'quest',
        icon: Icons.flag_outlined,
        label: 'Quest',
        onTap: () => context.push('/daily-quests'),
      ),
      _ShortcutDef(
        id: 'challenges',
        icon: Icons.emoji_events_outlined,
        label: 'Challenges',
        onTap: () => context.push('/challenges'),
      ),
      _ShortcutDef(
        id: 'league',
        icon: Icons.trending_up,
        label: 'League',
        onTap: () => context.push(leaguesPath()),
      ),
      _ShortcutDef(
        id: 'prestige',
        icon: Icons.bolt_outlined,
        label: 'Prestige',
        onTap: () => context.push('/hall-of-ascension'),
      ),
      _ShortcutDef(
        id: 'trending',
        icon: Icons.public,
        label: 'Trending',
        onTap: () => context.push(exploreDiscoverPath()),
      ),
    ];

    final byId = {for (final s in shortcuts) s.id: s};
    final ordered = [
      for (final id in _order)
        if (byId.containsKey(id) && !(widget.hideLeague && id == 'league'))
          byId[id]!,
    ];

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: VSpacing.xs),
        children: [
          for (final s in ordered)
            _CompactShortcut(
              icon: s.icon,
              label: s.label,
              onTap: () => _go(s.id, s.onTap),
            ),
        ],
      ),
    );
  }
}

class _ShortcutDef {
  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutDef({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _CompactShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: VSpacing.sm),
      child: Material(
        color: context.vSurfaceContainer,
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96, minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.sm,
                vertical: VSpacing.sm,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: VIconSize.md, color: context.vPrimary),
                  const SizedBox(height: VSpacing.xxs),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: VFontWeight.semiBold,
                        color: context.vOnSurface,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
