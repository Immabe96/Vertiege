import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../../config/achievements.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/achievements/achievement_card.dart';
import '../../widgets/core/empty_state.dart';

class AchievementCategoryScreen extends ConsumerWidget {
  final String category;

  const AchievementCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = AchievementCategory.values
        .where((c) => c.name == category)
        .firstOrNull;
    if (cat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Achievements')),
        body: const AppEmptyState(
          title: 'Category not found',
          description: 'This achievement category is no longer available.',
          icon: Icons.emoji_events_outlined,
          variant: EmptyStateVariant.error,
        ),
      );
    }
    final catAchievements = achievements
        .where((a) => a.category == cat)
        .toList();
    final achievementState = ref.watch(achievementProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(category[0].toUpperCase() + category.substring(1)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(VSpacing.md),
        itemCount: catAchievements.length,
        itemBuilder: (context, index) {
          final achievement = catAchievements[index];
          final status = ref
              .read(achievementProvider.notifier)
              .getAchievementStatus(achievement.id);
          final userAch = achievementState.userAchievements
              .where((a) => a.achievementId == achievement.id)
              .firstOrNull;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < catAchievements.length - 1 ? VSpacing.sm : 0,
            ),
            child: AchievementCard(
              achievement: achievement,
              status: status,
              aiConfidence: userAch?.aiConfidence,
              aiNotes: userAch?.aiNotes,
              onPress: () {
                ref
                    .read(achievementProvider.notifier)
                    .submitAchievement(achievement.id, 'manual');
              },
            ),
          );
        },
      ),
    );
  }
}
