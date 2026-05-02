import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../../config/achievements.dart';
import '../../state/achievement_provider.dart';
import 'achievement_card.dart';
import 'package:go_router/go_router.dart';

class AchievementGrid extends ConsumerWidget {
  const AchievementGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementProvider);

    final statusMap = <String, AchievementStatus>{};
    for (final ua in state.userAchievements) {
      statusMap[ua.achievementId] = ua.status;
    }

    final items = achievements.where((a) => a.category != AchievementCategory.profession).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(achievementProvider.notifier).loadAchievements();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final achievement = items[index];
          final status = statusMap[achievement.id] ?? AchievementStatus.locked;

          return AchievementCard(
            achievement: achievement,
            status: status,
            index: index,
            onPress: () => context.push('/achievements/${achievement.category.name}'),
          );
        },
      ),
    );
  }
}
