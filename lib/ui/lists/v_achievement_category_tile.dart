import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_assets.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/shared/badge_asset_image.dart';

/// Achievement category row for the achievements index.
class VAchievementCategoryTile extends FTile {
  VAchievementCategoryTile({
    required AchievementCategory category,
    required AchievementCategoryMeta meta,
    required ({int earned, int total, int xp}) progress,
    required VoidCallback onTap,
    super.key,
  }) : super(
         onPress: onTap,
         prefix: _CategoryAvatar(
           categoryName: category.name,
           icon: meta.icon,
           color: meta.color,
           accentRing:
               category == AchievementCategory.funny ||
               category == AchievementCategory.creative,
         ),
         title: Text(
           meta.label,
           style:
               category == AchievementCategory.funny ||
                   category == AchievementCategory.creative
               ? const TextStyle(color: VColors.tertiary)
               : null,
         ),
         subtitle: Text(
           '${progress.earned} of ${progress.total} verified · ${progress.xp} XP earned',
           maxLines: 1,
           overflow: TextOverflow.ellipsis,
         ),
         suffix: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           crossAxisAlignment: CrossAxisAlignment.end,
           children: [
             Text(
               progress.total > 0
                   ? '${((progress.earned / progress.total) * 100).round()}%'
                   : '0%',
               style: const TextStyle(
                 fontWeight: VFontWeight.bold,
                 fontSize: VFontSize.labelMd,
               ),
             ),
             const SizedBox(height: 4),
             SizedBox(
               width: 48,
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(VRadius.sm),
                 child: LinearProgressIndicator(
                   value: progress.total > 0
                       ? (progress.earned / progress.total).clamp(0.0, 1.0)
                       : 0,
                   minHeight: 4,
                   valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                 ),
               ),
             ),
           ],
         ),
       );
}

class _CategoryAvatar extends StatelessWidget {
  final String categoryName;
  final IconData icon;
  final Color color;
  final bool accentRing;

  const _CategoryAvatar({
    required this.categoryName,
    required this.icon,
    required this.color,
    this.accentRing = false,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = WorldAssets.achievementCategoryImage(categoryName);
    const avatarSize = VBadgeSize.categoryAvatar;

    Widget emblem() => Icon(
      icon,
      color: accentRing ? VColors.tertiary : color,
      size: avatarSize * VBadgeSize.fallbackIconFraction,
    );

    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Center(
        child: imagePath != null
            ? BadgeAssetImage(
                imagePath: imagePath,
                size: avatarSize,
                errorBuilder: (_, _, _) => emblem(),
              )
            : emblem(),
      ),
    );
  }
}
