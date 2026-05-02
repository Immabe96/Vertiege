import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../../state/achievement_provider.dart';
import '../../widgets/achievements/achievement_grid.dart';

class AchievementsIndexScreen extends ConsumerWidget {
  const AchievementsIndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text('${achievements.totalXp}', style: theme.textTheme.headlineLarge),
                    Text('Total XP', style: theme.textTheme.labelMedium),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    Text('${achievements.userAchievements.where((a) => a.status == AchievementStatus.verified).length}',
                        style: theme.textTheme.headlineLarge),
                    Text('Earned', style: theme.textTheme.labelMedium),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          const Expanded(child: AchievementGrid()),
        ],
      ),
    );
  }
}
