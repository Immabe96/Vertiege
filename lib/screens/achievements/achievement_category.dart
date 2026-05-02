import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../../config/achievements.dart';
import '../../state/achievement_provider.dart';
import '../../widgets/achievements/achievement_card.dart';

class AchievementCategoryScreen extends ConsumerWidget {
  final String category;

  const AchievementCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = AchievementCategory.values.firstWhere((c) => c.name == category);
    final catAchievements = achievements.where((a) => a.category == cat).toList();

    return Scaffold(
      appBar: AppBar(title: Text(category[0].toUpperCase() + category.substring(1))),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: catAchievements.length,
        itemBuilder: (context, index) {
          final achievement = catAchievements[index];
          final status = ref.watch(achievementProvider.notifier).getAchievementStatus(achievement.id);
          return AchievementCard(
            achievement: achievement,
            status: status,
            onPress: () {
              ref.read(achievementProvider.notifier).submitAchievement(achievement.id, 'manual');
            },
          );
        },
      ),
    );
  }
}
