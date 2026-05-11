import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../../config/achievements.dart';
import '../../state/achievement_provider.dart';
import '../../theme/design_system.dart';
import '../../widgets/achievements/achievement_card.dart';

class AchievementCategoryScreen extends ConsumerWidget {
  final String category;

  const AchievementCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = AchievementCategory.values.firstWhere((c) => c.name == category);
    final catAchievements = achievements.where((a) => a.category == cat).toList();
    final achievementState = ref.watch(achievementProvider);

    return Scaffold(
      appBar: AppBar(title: Text(category[0].toUpperCase() + category.substring(1))),
      body: ListView.builder(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: catAchievements.length,
        itemBuilder: (context, index) {
          final achievement = catAchievements[index];
          final status = ref.read(achievementProvider.notifier).getAchievementStatus(achievement.id);
          final userAch = achievementState.userAchievements
              .where((a) => a.achievementId == achievement.id)
              .firstOrNull;
          return Padding(
            padding: EdgeInsets.only(bottom: index < catAchievements.length - 1 ? Spacing.sm : 0),
            child: AchievementCard(
              achievement: achievement,
              status: status,
              aiConfidence: userAch?.aiConfidence,
              aiNotes: userAch?.aiNotes,
              onPress: () {
                ref.read(achievementProvider.notifier).submitAchievement(achievement.id, 'manual');
              },
            ),
          );
        },
      ),
    );
  }
}
