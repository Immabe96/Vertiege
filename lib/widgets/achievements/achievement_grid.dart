import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../../config/achievements.dart';
import '../../state/achievement_provider.dart';
import 'package:go_router/go_router.dart';

class AchievementGrid extends ConsumerWidget {
  const AchievementGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = AchievementCategory.values.where((c) => c != AchievementCategory.profession);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(achievementProvider.notifier).loadAchievements();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories.elementAt(index);
          final progress = ref.watch(achievementProvider.notifier).getCategoryProgress(category.name);
          final catAchievements = achievements.where((a) => a.category == category).toList();
          final icon = catAchievements.firstOrNull?.icon ?? 'star';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(category.name[0].toUpperCase() + category.name.substring(1)),
              subtitle: Text('${progress.earned}/${progress.total} | ${progress.xp} XP'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/achievements/${category.name}'),
            ),
          );
        },
      ),
    );
  }
}
