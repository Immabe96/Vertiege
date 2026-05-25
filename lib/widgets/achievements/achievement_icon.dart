import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_assets.dart';
import '../shared/badge_asset_image.dart';
import 'achievement_avatar_surface.dart';

IconData achievementIconData(String iconName) {
  return switch (iconName) {
    'school' => Icons.school_outlined,
    'translate' => Icons.translate,
    'verified' => Icons.verified_outlined,
    'work' => Icons.work_outline,
    'trending_up' => Icons.trending_up,
    'swap_horiz' => Icons.swap_horiz,
    'store' => Icons.storefront_outlined,
    'corporate_fare' => Icons.corporate_fare,
    'payments' => Icons.payments_outlined,
    'home_work' => Icons.home_work_outlined,
    'beach_access' => Icons.beach_access_outlined,
    'favorite' => Icons.favorite_border,
    'ring_volume' => Icons.diamond_outlined,
    'home' => Icons.home_outlined,
    'child_care' => Icons.child_care_outlined,
    'people' => Icons.people_outline,
    'directions_run' => Icons.directions_run,
    'monitor_weight' => Icons.monitor_weight_outlined,
    'fitness_center' => Icons.fitness_center,
    'pool' => Icons.pool,
    'directions_bike' => Icons.directions_bike,
    'block' => Icons.block,
    'self_improvement' => Icons.self_improvement,
    'code' => Icons.code,
    'music_note' => Icons.music_note,
    'restaurant' => Icons.restaurant_outlined,
    'directions_car' => Icons.directions_car_outlined,
    'surfing' => Icons.surfing,
    'mic' => Icons.mic_none,
    'construction' => Icons.construction,
    'flight' => Icons.flight,
    'flight_takeoff' => Icons.flight_takeoff,
    'public' => Icons.public,
    'language' => Icons.language,
    'star' => Icons.star_border,
    'savings' => Icons.savings_outlined,
    'shield' => Icons.shield_outlined,
    'check_circle' => Icons.check_circle_outline,
    'volunteer_activism' => Icons.volunteer_activism_outlined,
    'bloodtype' => Icons.bloodtype_outlined,
    'diversity_3' => Icons.diversity_3,
    'forest' => Icons.forest_outlined,
    'event' => Icons.event_outlined,
    'nightlight' => Icons.nightlight_outlined,
    'groups' => Icons.groups_outlined,
    'local_pizza' => Icons.local_pizza_outlined,
    'toys' => Icons.toys_outlined,
    'pets' => Icons.pets,
    'phone_in_talk' => Icons.phone_in_talk_outlined,
    'tv' => Icons.tv,
    'question_mark' => Icons.question_mark,
    'chair' => Icons.chair_outlined,
    'menu_book' => Icons.menu_book_outlined,
    'palette' => Icons.palette_outlined,
    'lyrics' => Icons.lyrics_outlined,
    'play_circle' => Icons.play_circle_outline,
    'theater_comedy' => Icons.theater_comedy_outlined,
    'edit_note' => Icons.edit_note,
    'record_voice_over' => Icons.record_voice_over_outlined,
    'history_edu' => Icons.history_edu,
    'auto_stories' => Icons.auto_stories_outlined,
    'explore' => Icons.explore_outlined,
    'hiking' => Icons.hiking,
    'terrain' => Icons.terrain,
    'local_fire_department' => Icons.local_fire_department_outlined,
    'spa' => Icons.spa_outlined,
    'nightlife' => Icons.nightlife_outlined,
    'yard' => Icons.yard_outlined,
    'psychology' => Icons.psychology_outlined,
    'bolt' => Icons.bolt_outlined,
    'auto_awesome' => Icons.auto_awesome_outlined,
    'coffee' => Icons.coffee_outlined,
    'mood' => Icons.mood_outlined,
    'movie' => Icons.movie_outlined,
    _ => Icons.workspace_premium_outlined,
  };
}

/// Badge avatar with asset fallback for achievements.
class AchievementBadgeAvatar extends StatelessWidget {
  final Achievement achievement;
  final Color accentColor;
  final double size;

  const AchievementBadgeAvatar({
    super.key,
    required this.achievement,
    required this.accentColor,
    this.size = VBadgeSize.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final imagePath =
        WorldAssets.achievementBadgeImage(achievement.id) ??
        WorldAssets.achievementCategoryImage(achievement.category.name);
    final icon = achievementIconData(achievement.icon);
    final hasRaster = imagePath != null;
    final fill = achievementBadgeContainerColor(
      hasRasterAsset: hasRaster,
      accent: accentColor,
      brightness: brightness,
    );

    Widget fallback() => Icon(icon, size: size * 0.45, color: accentColor);

    if (!hasRaster) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
        child: Center(child: fallback()),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: BadgeAssetImage(
        imagePath: imagePath,
        size: size,
        adaptDarkBackground: false,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: achievementAvatarFill(accentColor, brightness),
          ),
          child: Center(child: fallback()),
        ),
      ),
    );
  }
}

String statusLabel(AchievementStatus status) {
  return switch (status) {
    AchievementStatus.verified => 'Verified',
    AchievementStatus.submitted => 'Pending',
    AchievementStatus.rejected => 'Rejected',
    AchievementStatus.locked => 'Available',
  };
}

Color statusColor(AchievementStatus status) {
  return switch (status) {
    AchievementStatus.verified => VColors.success,
    AchievementStatus.submitted => VColors.warning,
    AchievementStatus.rejected => VColors.error,
    AchievementStatus.locked => VColors.tertiary,
  };
}

bool hasProofThumbnail(String? proofUri) {
  if (proofUri == null || proofUri.isEmpty || proofUri == 'manual') {
    return false;
  }
  return proofUri.startsWith('http') || proofUri.startsWith('file');
}
