import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/league_provider.dart';
import '../../../state/resident_provider.dart';
import '../../../services/league_service.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/design_system.dart';
import '../../../ui/buttons/v_button.dart';

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
                size: IconSizes.md,
                color: VColors.secondary,
              ),
              const SizedBox(width: Spacing.xs),
              const Text(
                'LEAGUES',
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.semiBold,
                  color: VColors.onSurfaceVariant,
                  letterSpacing: LetterSpacing.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Text(
            'Loading...',
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
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
      children: [
        Row(
          children: [
            Icon(tierIcon, size: IconSizes.md, color: tierColor),
            const SizedBox(width: Spacing.xs),
            const Text(
              'LEAGUES',
              style: TextStyle(
                fontSize: FontSizes.labelSm,
                fontWeight: FontWeights.semiBold,
                color: VColors.onSurfaceVariant,
                letterSpacing: LetterSpacing.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Text(
              userLeague.tier.toUpperCase(),
              style: TextStyle(
                fontSize: FontSizes.headlineSm,
                fontWeight: FontWeights.bold,
                color: tierColor,
              ),
            ),
            const Spacer(),
            Text(
              '#${userLeague.rank}',
              style: TextStyle(
                fontSize: FontSizes.headlineMd,
                fontWeight: FontWeights.bold,
                color: VColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          '${userLeague.weeklyXp} XP this week',
          style: const TextStyle(
            fontSize: FontSizes.bodySm,
            color: VColors.outline,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        VButton(
          label: 'View Standings',
          onPressed: () => context.push('/leagues'),
          variant: ButtonVariant.outlined,
          isFullWidth: true,
        ),
      ],
    );
  }
}
