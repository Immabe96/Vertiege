import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/achievement.dart';
import '../../config/achievements.dart';
import '../../state/achievement_provider.dart';
import '../../theme/design_system.dart';
import '../../utils/world_assets.dart';
import 'achievement_card.dart';

class AchievementGrid extends ConsumerStatefulWidget {
  const AchievementGrid({super.key});

  @override
  ConsumerState<AchievementGrid> createState() => _AchievementGridState();
}

class _AchievementGridState extends ConsumerState<AchievementGrid> {
  AchievementCategory? _selectedCategory;

  static const _categoryMeta =
      <AchievementCategory, ({String label, IconData icon})>{
        AchievementCategory.education: (label: 'Education', icon: Icons.school),
        AchievementCategory.career: (label: 'Career', icon: Icons.work),
        AchievementCategory.relationships: (
          label: 'Relationships',
          icon: Icons.favorite,
        ),
        AchievementCategory.health: (
          label: 'Health',
          icon: Icons.fitness_center,
        ),
        AchievementCategory.skills: (label: 'Skills', icon: Icons.build),
        AchievementCategory.travel: (label: 'Travel', icon: Icons.flight),
        AchievementCategory.finance: (label: 'Finance', icon: Icons.savings),
        AchievementCategory.community: (
          label: 'Community',
          icon: Icons.volunteer_activism,
        ),
        AchievementCategory.funny: (label: 'Funny', icon: Icons.emoji_emotions),
        AchievementCategory.creative: (label: 'Creative', icon: Icons.palette),
        AchievementCategory.profession: (
          label: 'Profession',
          icon: Icons.verified_user,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(achievementProvider);
    final theme = Theme.of(context);

    final statusMap = <String, AchievementStatus>{};
    for (final ua in state.userAchievements) {
      statusMap[ua.achievementId] = ua.status;
    }

    final allItems = achievements.toList();

    final filtered = _selectedCategory == null
        ? allItems
        : allItems.where((a) => a.category == _selectedCategory).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(achievementProvider.notifier).loadAchievements();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              itemCount: _categoryMeta.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: Spacing.xs),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                    selectedColor: theme.colorScheme.primary.withValues(
                      alpha: 0.18,
                    ),
                    checkmarkColor: theme.colorScheme.primary,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    ),
                  );
                }
                final entry = _categoryMeta.entries.elementAt(index - 1);
                final cat = entry.key;
                final meta = entry.value;
                final imagePath = WorldAssets.achievementCategoryImage(
                  cat.name,
                );
                return FilterChip(
                  avatar: imagePath == null
                      ? Icon(meta.icon, size: IconSizes.sm)
                      : ClipOval(
                          child: Image.asset(
                            imagePath,
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Icon(meta.icon, size: IconSizes.sm),
                          ),
                        ),
                  label: Text(meta.label),
                  selected: _selectedCategory == cat,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = selected ? cat : null);
                  },
                  selectedColor: theme.colorScheme.primary.withValues(
                    alpha: 0.18,
                  ),
                  checkmarkColor: theme.colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Achievement grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No achievements in this category',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(Spacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: Spacing.sm,
                          crossAxisSpacing: Spacing.sm,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final achievement = filtered[index];
                      final status =
                          statusMap[achievement.id] ?? AchievementStatus.locked;
                      return AchievementCard(
                        achievement: achievement,
                        status: status,
                        index: index,
                        onPress: () => context.push(
                          '/achievements/${achievement.category.name}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
