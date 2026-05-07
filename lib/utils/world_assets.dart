import 'package:flutter/material.dart';
import '../models/world.dart';
import '../theme/colors.dart';

/// Deterministic world asset generator.
/// Every world gets a unique visual identity derived from its ID hash.
class WorldAssets {
  WorldAssets._();

  /// Pool of pre-approved accent colors drawn from AppColors.
  static final _accentPalette = <Color>[
    AppColors.gemPink,
    AppColors.beeYellow,
    AppColors.eelBlue,
    AppColors.mysticBlue,
    AppColors.achievementEducation,
    AppColors.achievementCareer,
    AppColors.achievementSkills,
    AppColors.achievementTravel,
    AppColors.achievementHealth,
    AppColors.achievementCommunity,
    AppColors.achievementFinance,
    AppColors.achievementCreative,
    AppColors.success,
    AppColors.warning,
    const Color(0xFFA78BFA), // violet accent
    const Color(0xFFF472B6), // rose accent
  ];

  /// Pool of Material icons for world identity.
  static final _iconPool = <IconData>[
    Icons.diamond,
    Icons.shield,
    Icons.stars,
    Icons.rocket_launch,
    Icons.auto_awesome,
    Icons.token,
    Icons.workspace_premium,
    Icons.psychology,
    Icons.account_balance,
    Icons.landscape,
    Icons.cloud,
    Icons.water,
    Icons.forest,
    Icons.terrain,
    Icons.storm,
    Icons.local_fire_department,
    Icons.explore,
    Icons.travel_explore,
    Icons.language,
    Icons.public,
    Icons.hub,
    Icons.military_tech,
    Icons.verified,
    Icons.emoji_events,
  ];

  // ── Public API ──────────────────────────────────────────────

  /// Returns a unique accent color for a world based on its ID hash.
  static Color accentForWorld(String worldId) {
    final idx = worldId.hashCode.abs() % _accentPalette.length;
    return _accentPalette[idx];
  }

  /// Returns a unique Material icon for a world based on its ID hash.
  static IconData iconForWorld(String worldId) {
    final idx = worldId.hashCode.abs() % _iconPool.length;
    return _iconPool[idx];
  }

  /// Returns the tier-specific glow color for a given prestige value (0-50 range).
  ///
  /// prestige >= 40  =>  gold (tertiary)
  /// prestige >= 20  =>  violet (primary)
  /// prestige <  20  =>  orange (hustler)
  static Color glowForPrestige(int prestige) {
    if (prestige >= 40) return AppColors.tertiary;
    if (prestige >= 20) return AppColors.primary;
    return AppColors.hustler;
  }

  /// Alias for [glowForPrestige] — clean name for UI-tier coloring.
  static Color colorForPrestige(int prestige) => glowForPrestige(prestige);

  /// Returns a map of pattern parameters for procedural banner generation.
  ///
  /// Varies rotation, density, and accent count deterministically from
  /// [worldId] so every world gets a unique composition.
  static Map<String, dynamic> patternParams(
    String worldId,
    WorldType type,
    int prestige,
  ) {
    final hash = worldId.hashCode.abs();
    return <String, dynamic>{
      'rotation': (worldId.hashCode % 360).toDouble(),
      'density': 3 + (hash % 5),
      'accentCount': 2 + (hash % 8),
      'tierColor': colorForPrestige(prestige),
      'type': type,
    };
  }
}
