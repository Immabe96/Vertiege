import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/world_navigation.dart';
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
class NexusShortcutsSection extends StatelessWidget {
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  const NexusShortcutsSection({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            firstChild: const _CompactShortcutsRow(),
            secondChild: BentoGrid(
              cards: [
                const BentoCard(
                  child: PrestigeProgressCard(),
                  size: BentoSize.medium,
                ),
                BentoCard(
                  child: const DailyQuestCard(),
                  size: BentoSize.small,
                  onTap: () => context.push('/daily-quests'),
                ),
                BentoCard(
                  child: const SeasonSnapshotCard(),
                  size: BentoSize.small,
                  onTap: () => context.push('/season'),
                ),
                const BentoCard(
                  child: SpotlightCard(),
                  size: BentoSize.medium,
                ),
                BentoCard(
                  child: const ChallengesCard(),
                  size: BentoSize.small,
                  onTap: () => context.push('/challenges'),
                ),
                BentoCard(
                  child: const LeagueCard(),
                  size: BentoSize.small,
                  onTap: () => context.push(leaguesPath()),
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
}

class _CompactShortcutsRow extends StatelessWidget {
  const _CompactShortcutsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: VSpacing.xs),
        children: [
          _CompactShortcut(
            icon: Icons.auto_awesome,
            label: 'Season 1',
            onTap: () => context.push('/season'),
          ),
          _CompactShortcut(
            icon: Icons.flag_outlined,
            label: 'Quest',
            onTap: () => context.push('/daily-quests'),
          ),
          _CompactShortcut(
            icon: Icons.emoji_events_outlined,
            label: 'Challenges',
            onTap: () => context.push('/challenges'),
          ),
          _CompactShortcut(
            icon: Icons.trending_up,
            label: 'League',
            onTap: () => context.push(leaguesPath()),
          ),
          _CompactShortcut(
            icon: Icons.bolt_outlined,
            label: 'Prestige',
            onTap: () => context.push('/hall-of-ascension'),
          ),
          _CompactShortcut(
            icon: Icons.public,
            label: 'Trending',
            onTap: () => context.push(exploreDiscoverPath()),
          ),
        ],
      ),
    );
  }
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
          child: SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.sm,
                vertical: VSpacing.xs,
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
