import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/resident_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/fade_in.dart';

class WorldLeaderboard extends ConsumerWidget {
  final String worldId;
  final int maxItems;

  const WorldLeaderboard({
    super.key,
    required this.worldId,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentState = ref.watch(residentProvider);
    final theme = Theme.of(context);
    final allResidents = residentState.resident != null
        ? <_RankedResident>[] // populated below when we have real data
        : <_RankedResident>[];

    // For now, build from world standings on the current resident
    // In a full implementation this would come from a world-specific provider
    final standing = residentState.resident?.worldStandings[worldId];
    if (standing != null) {
      allResidents.add(_RankedResident(
        name: residentState.resident!.name,
        avatarUrl: residentState.resident!.avatarUrl,
        rep: standing.rep,
        isCurrentUser: true,
      ));
    }

    if (allResidents.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: [
              Icon(Icons.leaderboard_outlined,
                  size: IconSizes.xl, color: theme.colorScheme.outline),
              const SizedBox(height: Spacing.sm),
              Text('Leaderboard',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: Spacing.xs),
              Text(
                'Be the first to earn reputation in this world',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<_RankedResident>.from(allResidents)
      ..sort((a, b) => b.rep.compareTo(a.rep));
    final display = sorted.take(maxItems).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard, size: IconSizes.md,
                    color: AppColors.beeYellow),
                const SizedBox(width: Spacing.sm),
                Text('Leaderboard',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: Spacing.md),
            ...display.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final resident = entry.value;
              return FadeIn(
                delayMs: rank * 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                  child: Row(
                    children: [
                      _RankBadge(rank: rank),
                      const SizedBox(width: Spacing.sm),
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: resident.avatarUrl != null
                            ? NetworkImage(resident.avatarUrl!)
                            : null,
                        child: resident.avatarUrl == null
                            ? Text(resident.name[0].toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))
                            : null,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          resident.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: resident.isCurrentUser
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: resident.isCurrentUser
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        '${resident.rep} rep',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RankedResident {
  final String name;
  final String? avatarUrl;
  final int rep;
  final bool isCurrentUser;
  const _RankedResident({
    required this.name,
    this.avatarUrl,
    required this.rep,
    this.isCurrentUser = false,
  });
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final IconData icon;
    switch (rank) {
      case 1:
        bg = AppColors.gold;
        icon = Icons.emoji_events;
      case 2:
        bg = AppColors.silver;
        icon = Icons.military_tech;
      case 3:
        bg = AppColors.bronze;
        icon = Icons.workspace_premium;
      default:
        return Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text('$rank',
              style: TextStyle(
                fontSize: FontSizes.caption,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.outline,
              )),
        );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg.withValues(alpha: 0.15),
        border: Border.all(color: bg, width: 1.5),
      ),
      child: Icon(icon, size: IconSizes.sm, color: bg),
    );
  }
}
