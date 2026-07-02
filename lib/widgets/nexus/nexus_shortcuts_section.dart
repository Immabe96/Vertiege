import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/world_navigation.dart';
import '../../state/resident_provider.dart';
import '../../services/nexus_bento_order.dart';
import '../../services/nexus_shortcut_prefs.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_context_colors.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/v_motion.dart';
import 'bento_grid.dart';
import 'bento_cards/streak_card.dart';
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
              flat: true,
              cards: [
                const BentoCard(
                  child: PrestigeProgressCard(),
                  size: BentoSize.medium,
                ),
                BentoCard(
                  child: const StreakCard(),
                  onTap: () =>
                      _openShortcut(context, 'streak', '/progress?tab=quests'),
                ),
                BentoCard(
                  child: const DailyQuestCard(),
                  size: BentoSize.medium,
                  onTap: () =>
                      _openShortcut(context, 'quest', '/progress?tab=quests'),
                ),
                if (!hideLeague)
                  BentoCard(
                    child: const LeagueCard(),
                    onTap: () =>
                        _openShortcut(context, 'league', leaguesPath()),
                  ),
                BentoCard(
                  child: const ChallengesCard(),
                  onTap: () =>
                      _openShortcut(context, 'challenges', '/progress?tab=world'),
                ),
                BentoCard(
                  child: const SeasonSnapshotCard(),
                  onTap: () =>
                      _openShortcut(context, 'season', '/progress?tab=season'),
                ),
                const BentoCard(
                  child: SpotlightCard(),
                  size: BentoSize.medium,
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
        onTap: () => context.push('/progress?tab=season'),
      ),
      _ShortcutDef(
        id: 'quest',
        icon: Icons.flag_outlined,
        label: 'Quest',
        onTap: () => context.push('/progress?tab=quests'),
      ),
      _ShortcutDef(
        id: 'challenges',
        icon: Icons.emoji_events_outlined,
        label: 'Challenges',
        onTap: () => context.push('/progress?tab=world'),
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

    const primaryCount = 3;
    final primary = ordered.take(primaryCount).toList();
    final overflow = ordered.skip(primaryCount).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.xs),
      child: Row(
        children: [
          for (final s in primary)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: VSpacing.sm),
                child: _CompactShortcut(
                  icon: s.icon,
                  label: s.label,
                  onTap: () => _go(s.id, s.onTap),
                  expand: true,
                ),
              ),
            ),
          if (overflow.isNotEmpty)
            _ShortcutsOverflowButton(
              shortcuts: overflow,
              onSelect: (s) => _go(s.id, s.onTap),
            ),
        ],
      ),
    );
  }
}

class _ShortcutsOverflowButton extends StatelessWidget {
  final List<_ShortcutDef> shortcuts;
  final ValueChanged<_ShortcutDef> onSelect;

  const _ShortcutsOverflowButton({
    required this.shortcuts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: PrestigeNoir.surfaceRaised,
      borderRadius: BorderRadius.circular(VRadius.lg),
      child: PopupMenuButton<_ShortcutDef>(
        tooltip: 'More shortcuts',
        icon: Icon(Icons.more_horiz, color: context.vOnSurfaceVariant),
        onSelected: onSelect,
        itemBuilder: (context) => [
          for (final s in shortcuts)
            PopupMenuItem(
              value: s,
              child: Row(
                children: [
                  Icon(s.icon, size: VIconSize.sm, color: context.vPrimary),
                  const SizedBox(width: VSpacing.sm),
                  Text(s.label, style: theme.textTheme.bodyMedium),
                ],
              ),
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
  final bool expand;

  const _CompactShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = Material(
      color: PrestigeNoir.surfaceRaised,
      borderRadius: BorderRadius.circular(VRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: expand ? 0 : 96,
            minHeight: 48,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: VSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: VIconSize.md, color: VColors.brand),
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
    );
    return expand ? tile : Padding(padding: const EdgeInsets.only(right: VSpacing.sm), child: tile);
  }
}
