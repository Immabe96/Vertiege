import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/league_provider.dart';
import '../../../state/resident_provider.dart';
import '../../../services/league_service.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/v_tokens.dart';
class LeagueCard extends ConsumerWidget {
  const LeagueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueState = ref.watch(leagueProvider);
    final userLeague = leagueState.userLeague;
    final resident = ref.read(residentProvider).resident;

    if (userLeague == null && resident != null && !leagueState.isLoading) {
      Future.microtask(() => ref.read(leagueProvider.notifier).loadLeague());
    }

    if (userLeague == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                size: VIconSize.md,
                color: VColors.secondary,
              ),
              const SizedBox(width: VSpacing.xs),
              const Text(
                'LEAGUES',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  color: VColors.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          const Text(
            'Loading...',
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              color: VColors.outline,
            ),
          ),
        ],
      );
    }

    final tierColor = LeagueService.getTierColor(userLeague.tier);
    final tierIcon = LeagueService.getTierIcon(userLeague.tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(tierIcon, size: VIconSize.md, color: tierColor),
            const SizedBox(width: VSpacing.xs),
            const Expanded(
              child: Text(
                'LEAGUES',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  color: VColors.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        Row(
          children: [
            Flexible(
              child: Text(
                userLeague.tier.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: VFontSize.headlineSm,
                  fontWeight: VFontWeight.bold,
                  color: tierColor,
                ),
              ),
            ),
            const SizedBox(width: VSpacing.xs),
            Text(
              '#${userLeague.rank}',
              style: const TextStyle(
                fontSize: VFontSize.headlineMd,
                fontWeight: VFontWeight.bold,
                color: VColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          '${userLeague.weeklyXp} XP this week',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: VFontSize.bodySm,
            color: VColors.outline,
          ),
        ),
      ],
    );
  }
}
