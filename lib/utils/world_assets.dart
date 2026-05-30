import 'package:flutter/material.dart';
import '../config/core_achievement_badge_ids.dart';
import '../models/achievement.dart';
import '../models/world.dart';
import '../theme/v_colors.dart';

/// Deterministic world asset generator.
/// Every world gets a unique visual identity derived from its ID hash.
class WorldAssets {
  WorldAssets._();

  static const _worldIconPaths = <String, String>{
    'aetheria': 'assets/generated/world-icon-aetheria.png',
    'arts-pavilion': 'assets/generated/world-icon-arts-pavilion.png',
    'aviation-heights': 'assets/generated/world-icon-aviation-heights.png',
    'azure-coast': 'assets/generated/world-icon-azure-coast.png',
    'crimson-court': 'assets/generated/world-icon-crimson-court.png',
    'crystal-shore': 'assets/generated/world-icon-crystal-shore.png',
    'financial-district': 'assets/generated/world-icon-financial-district.png',
    'golden-estate': 'assets/generated/world-icon-golden-estate.png',
    'legal-plaza': 'assets/generated/world-icon-legal-plaza.png',
    'medical-nexus': 'assets/generated/world-icon-medical-nexus.png',
    'neon-district': 'assets/generated/world-icon-neon-district.png',
    'nova-station': 'assets/generated/world-icon-nova-station.png',
    'quantum-core': 'assets/generated/world-icon-quantum-core.png',
    'silver-page': 'assets/generated/world-icon-silver-page.png',
    'sovereign-city': 'assets/generated/world-icon-sovereign-city.png',
    'tech-sprawl': 'assets/generated/world-icon-tech-sprawl.png',
  };

  static const _worldImagePaths = <String, String>{
    'aetheria': 'assets/generated/world-aetheria.jpg',
    'arts-pavilion': 'assets/generated/world-arts-pavilion.jpg',
    'aviation-heights': 'assets/generated/world-aviation-heights.jpg',
    'azure-coast': 'assets/generated/world-azure-coast.jpg',
    'crimson-court': 'assets/generated/world-crimson-court.jpg',
    'crystal-shore': 'assets/generated/world-crystal-shore.jpg',
    'financial-district': 'assets/generated/world-financial-district.jpg',
    'golden-estate': 'assets/generated/world-golden-estate.jpg',
    'legal-plaza': 'assets/generated/world-legal-plaza.jpg',
    'medical-nexus': 'assets/generated/world-medical-nexus.jpg',
    'neon-district': 'assets/generated/world-neon-district.jpg',
    'nova-station': 'assets/generated/world-nova-station.jpg',
    'quantum-core': 'assets/generated/world-quantum-core.jpg',
    'silver-page': 'assets/generated/world-silver-page.jpg',
    'sovereign-city': 'assets/generated/world-sovereign-city.jpg',
    'tech-sprawl': 'assets/generated/world-tech-sprawl.jpg',
  };

  /// Alpha: single bundled default avatar; [avatarForSeed] maps all seeds to it.
  static const _defaultAvatarPath = 'assets/generated/avatar-1.png';

  static const _avatarPaths = <String>[
    _defaultAvatarPath,
  ];

  static const _badgeImagePaths = <String, String>{
    'Medical_badge': 'assets/generated/badge-doctor.png',
    'Engineering_badge': 'assets/generated/badge-engineer.png',
    'Legal_badge': 'assets/generated/badge-attorney.png',
    'Finance_badge': 'assets/generated/badge-finance.png',
    'Arts_badge': 'assets/generated/badge-artist.png',
    'Aviation_badge': 'assets/generated/badge-pilot.png',
    'badge-marathon': 'assets/generated/badge-marathon.png',
    'badge-author': 'assets/generated/badge-author.png',
    'badge-founder': 'assets/generated/badge-founder.png',
    'badge-explorer': 'assets/generated/badge-explorer.png',
    'badge-debtfree': 'assets/generated/badge-debtfree.png',
    'badge-leader': 'assets/generated/badge-leader.png',
    'badge-polyglot': 'assets/generated/badge-polyglot.png',
    'badge-doctor': 'assets/generated/badge-doctor.png',
    'badge-engineer': 'assets/generated/badge-engineer.png',
    'badge-attorney': 'assets/generated/badge-attorney.png',
    'badge-finance': 'assets/generated/badge-finance.png',
    'badge-artist': 'assets/generated/badge-artist.png',
    'badge-pilot': 'assets/generated/badge-pilot.png',
    'prof-doctor': 'assets/generated/prof-doctor.png',
    'prof-engineer': 'assets/generated/prof-engineer.png',
    'prof-attorney': 'assets/generated/prof-attorney.png',
    'prof-finance': 'assets/generated/prof-finance.png',
    'prof-artist': 'assets/generated/prof-artist.png',
    'prof-pilot': 'assets/generated/prof-pilot.png',
    'prof-nurse': 'assets/generated/prof-doctor.png',
    'prof-teacher': 'assets/generated/badge-author.png',
    'prof-architect': 'assets/generated/prof-engineer.png',
    'prof-scientist': 'assets/generated/prof-engineer.png',
    'prof-chef': 'assets/generated/prof-artist.png',
    'prof-realtor': 'assets/generated/prof-finance.png',
    'prof-therapist': 'assets/generated/prof-doctor.png',
    'prof-journalist': 'assets/generated/prof-artist.png',
  };

  /// Earned profession medallions (distinct from [professionCatalogIcon] prof-* emblems).
  static const _professionEarnedBadgePaths = <String, String>{
    'prof-doctor': 'assets/generated/badge-doctor.png',
    'prof-engineer': 'assets/generated/badge-engineer.png',
    'prof-attorney': 'assets/generated/badge-attorney.png',
    'prof-finance': 'assets/generated/badge-finance.png',
    'prof-artist': 'assets/generated/badge-artist.png',
    'prof-pilot': 'assets/generated/badge-pilot.png',
    'prof-nurse': 'assets/generated/badge-doctor.png',
    'prof-teacher': 'assets/generated/badge-author.png',
    'prof-architect': 'assets/generated/badge-engineer.png',
    'prof-scientist': 'assets/generated/badge-engineer.png',
    'prof-chef': 'assets/generated/badge-artist.png',
    'prof-realtor': 'assets/generated/badge-finance.png',
    'prof-therapist': 'assets/generated/badge-doctor.png',
    'prof-journalist': 'assets/generated/badge-artist.png',
  };

  static const _tierImagePaths = <int, String>{
    1: 'assets/generated/tier-hustler.png',
    2: 'assets/generated/tier-high-roller.png',
    3: 'assets/generated/tier-elite.png',
    4: 'assets/generated/tier-old-money.png',
    5: 'assets/generated/tier-apex.png',
  };

  static const _achievementCategoryPaths = <String, String>{
    'education': 'assets/generated/ach-education.png',
    'career': 'assets/generated/ach-career.png',
    'relationships': 'assets/generated/ach-relationships.png',
    'health': 'assets/generated/ach-health.png',
    'skills': 'assets/generated/ach-skills.png',
    'travel': 'assets/generated/ach-travel.png',
    'finance': 'assets/generated/ach-finance.png',
    'community': 'assets/generated/ach-community.png',
    'funny': 'assets/generated/ach-funny.png',
    'creative': 'assets/generated/ach-creative.png',
    'life': 'assets/generated/ach-life.png',
    'profession': 'assets/generated/ach-profession.png',
    'inApp': 'assets/generated/ach-community.png',
  };

  /// Pool of pre-approved accent colors drawn from AppColors.
  static final _accentPalette = <Color>[
    VColors.achievementSocial,
    VColors.achievementFinance,
    VColors.achievementAdventure,
    VColors.primary,
    VColors.achievementEducation,
    VColors.achievementCareer,
    VColors.achievementKnowledge,
    VColors.achievementAdventure,
    VColors.achievementHealth,
    VColors.achievementSocial,
    VColors.achievementFinance,
    VColors.achievementCreative,
    VColors.success,
    VColors.warning,
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

  static String? imageForWorld(String worldId) {
    final normalized = _normalizeWorldKey(worldId);
    return _worldImagePaths[normalized] ?? _worldImagePaths[worldId];
  }

  /// Square raster emblem for preset worlds (falls back to [iconForWorld]).
  static String? iconImageForWorld(String worldId, {String? assetKey}) {
    for (final key in _worldLookupKeys(worldId, assetKey)) {
      final path = _worldIconPaths[key];
      if (path != null) return path;
    }
    return null;
  }

  static Iterable<String> _worldLookupKeys(String worldId, String? assetKey) sync* {
    if (assetKey != null && assetKey.isNotEmpty) {
      yield _normalizeWorldKey(assetKey);
    }
    yield _normalizeWorldKey(worldId);
  }

  static String _normalizeWorldKey(String worldId) {
    if (worldId.startsWith('world-')) {
      return worldId.substring('world-'.length);
    }
    return worldId;
  }

  static String avatarForSeed(String seed) {
    final normalized = seed.trim().isEmpty ? 'resident' : seed.trim();
    final idx = normalized.hashCode.abs() % _avatarPaths.length;
    return _avatarPaths[idx];
  }

  static String? badgeImageForId(String badgeId) => _badgeImagePaths[badgeId];

  /// Core catalog badge: `assets/generated/achievements/<id>.png`.
  ///
  /// Generated assets use **two on-disk locations** (see `docs/achievements/CATALOG.md`):
  /// flat `assets/generated/*` via [_badgeImagePaths], and per-id files under
  /// `assets/generated/achievements/`. Lookup order is map → per-id folder → category PNG.
  static String? coreAchievementBadgeImage(String achievementId) {
    if (!coreAchievementBadgeIds.contains(achievementId)) return null;
    return 'assets/generated/achievements/$achievementId.png';
  }

  /// Flat-map legacy path, then per-id folder for core catalog achievements.
  static String? achievementBadgeImage(String achievementId) =>
      badgeImageForId(achievementId) ?? coreAchievementBadgeImage(achievementId);

  /// Catalog / in-progress emblem — category `ach-*.png` for all non-profession achievements.
  static String? achievementCatalogEmblem(
    String achievementId,
    AchievementCategory category,
  ) {
    if (category == AchievementCategory.profession) {
      return professionCatalogIcon(achievementId);
    }
    return achievementCategoryImage(category.name);
  }

  /// Unique earned badge when verified — per-id / legacy map; never category fallback.
  static String? achievementEarnedEmblem(
    String achievementId,
    AchievementCategory category,
  ) {
    if (category == AchievementCategory.profession) {
      return professionEarnedBadge(achievementId);
    }
    return achievementBadgeImage(achievementId);
  }

  /// Profession row icon (`prof-*.png`), not the generic profession category emblem.
  static String? professionCatalogIcon(String achievementId) =>
      badgeImageForId(achievementId);

  /// Profession earned medallion (`badge-*.png` or per-id achievements PNG).
  static String? professionEarnedBadge(String achievementId) =>
      _professionEarnedBadgePaths[achievementId] ??
      coreAchievementBadgeImage(achievementId);

  /// Resolves catalog vs earned emblem for UI.
  static String? achievementEmblemForDisplay({
    required String achievementId,
    required AchievementCategory category,
    required bool showEarnedBadge,
  }) {
    if (showEarnedBadge) {
      return achievementEarnedEmblem(achievementId, category) ??
          achievementCatalogEmblem(achievementId, category);
    }
    return achievementCatalogEmblem(achievementId, category);
  }

  /// @deprecated Prefer [achievementCatalogEmblem] or [achievementEarnedEmblem].
  static String? achievementDisplayImage(
    String achievementId,
    AchievementCategory category,
  ) =>
      achievementEmblemForDisplay(
        achievementId: achievementId,
        category: category,
        showEarnedBadge: true,
      );

  static String? tierImageForValue(int tier) => _tierImagePaths[tier];

  static String? achievementCategoryImage(String categoryName) =>
      _achievementCategoryPaths[categoryName];

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
    if (prestige >= 40) return VColors.tertiary;
    if (prestige >= 20) return VColors.primary;
    return VColors.tierHustler;
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
