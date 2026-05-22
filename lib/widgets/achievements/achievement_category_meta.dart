import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../theme/v_colors.dart';

/// Display metadata for achievement categories (labels, icons, colors).
class AchievementCategoryMeta {
  final String label;
  final IconData icon;
  final Color color;

  const AchievementCategoryMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}

const achievementCategoryMeta =
    <AchievementCategory, AchievementCategoryMeta>{
      AchievementCategory.education: AchievementCategoryMeta(
        label: 'Education',
        icon: Icons.school,
        color: VColors.achievementEducation,
      ),
      AchievementCategory.career: AchievementCategoryMeta(
        label: 'Career',
        icon: Icons.work,
        color: VColors.achievementCareer,
      ),
      AchievementCategory.relationships: AchievementCategoryMeta(
        label: 'Relationships',
        icon: Icons.favorite,
        color: VColors.achievementSocial,
      ),
      AchievementCategory.health: AchievementCategoryMeta(
        label: 'Health',
        icon: Icons.fitness_center,
        color: VColors.achievementHealth,
      ),
      AchievementCategory.skills: AchievementCategoryMeta(
        label: 'Skills',
        icon: Icons.build,
        color: VColors.achievementCreative,
      ),
      AchievementCategory.travel: AchievementCategoryMeta(
        label: 'Travel',
        icon: Icons.flight,
        color: VColors.achievementAdventure,
      ),
      AchievementCategory.finance: AchievementCategoryMeta(
        label: 'Finance',
        icon: Icons.savings,
        color: VColors.achievementFinance,
      ),
      AchievementCategory.community: AchievementCategoryMeta(
        label: 'Community',
        icon: Icons.volunteer_activism,
        color: VColors.achievementLeadership,
      ),
      AchievementCategory.funny: AchievementCategoryMeta(
        label: 'Funny',
        icon: Icons.emoji_emotions,
        color: VColors.tertiary,
      ),
      AchievementCategory.creative: AchievementCategoryMeta(
        label: 'Creative',
        icon: Icons.palette,
        color: VColors.achievementCreative,
      ),
      AchievementCategory.profession: AchievementCategoryMeta(
        label: 'Profession',
        icon: Icons.verified_user,
        color: VColors.primary,
      ),
      AchievementCategory.inApp: AchievementCategoryMeta(
        label: 'In App',
        icon: Icons.apps,
        color: VColors.primary,
      ),
    };

AchievementCategoryMeta metaForCategory(AchievementCategory category) {
  return achievementCategoryMeta[category] ??
      const AchievementCategoryMeta(
        label: 'Other',
        icon: Icons.emoji_events,
        color: VColors.primary,
      );
}

String categoryDisplayName(AchievementCategory category) {
  return metaForCategory(category).label;
}
