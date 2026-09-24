import '../models/resident.dart';
import '../models/world.dart';
import '../services/admin_access_service.dart';
import 'tiers.dart';

/// Global tier × world standing gates for economy and creation.
///
/// See [docs/vision/world-capability-matrix.md].
class WorldCapabilityMatrix {
  WorldCapabilityMatrix._();

  static const int minTierCreateWorld = 2;
  static const int minTierCreateListing = 2;
  static const int minTierDonateTreasury = 1;
  static const int minWorldPrestigeMarketplace = 30;
  static const int minWorldPrestigeTreasury = 25;
  static const int minStandingCreateListing = 3;
  static const int minStandingBrowseMarketplace = 2;
  static const int minStandingManageTreasury = 7;

  static bool canCreateWorld(Resident? resident) {
    if (resident == null) return false;
    if (AdminAccessService.isCurrentSessionSuperuser()) return true;
    return resident.tier.value >= minTierCreateWorld;
  }

  static String createWorldRequirementLabel() =>
      '${tierNames[minTierCreateWorld] ?? 'High Roller'}+ tier';

  static bool worldHasMarketplace(World world) =>
      world.type == WorldType.dominion ||
      world.prestige >= minWorldPrestigeMarketplace;

  static bool worldHasTreasury(World world) =>
      world.prestige >= minWorldPrestigeTreasury;

  static int standingLevel(
    Resident resident,
    String worldId,
    String? sovereignId,
  ) {
    if (resident.id == sovereignId) return standingLevels.length;
    final rep = resident.worldStandings[worldId]?.rep ?? 0;
    return getStanding(rep).level;
  }

  static bool canCreateListing(
    Resident? resident,
    World world, {
    required bool isJoined,
  }) {
    if (resident == null || !isJoined) return false;
    if (!worldHasMarketplace(world)) return false;
    if (resident.tier.value < minTierCreateListing) return false;
    return standingLevel(resident, world.id, world.sovereignId) >=
        minStandingCreateListing;
  }

  static bool canDonateTreasury(
    Resident? resident,
    World world, {
    required bool isJoined,
  }) {
    if (resident == null || !isJoined) return false;
    if (!worldHasTreasury(world)) return false;
    return resident.tier.value >= minTierDonateTreasury;
  }

  static bool canManageTreasury(
    Resident? resident,
    World world,
  ) {
    if (resident == null) return false;
    if (!worldHasTreasury(world)) return false;
    if (resident.id == world.sovereignId) return true;
    return standingLevel(resident, world.id, world.sovereignId) >=
        minStandingManageTreasury;
  }

  static String? blockReasonBrowseMarketplace(
    Resident? resident,
    World world, {
    required bool isJoined,
  }) {
    if (resident == null) return 'Sign in to browse the marketplace.';
    if (!isJoined) return 'Join this world to browse listings.';
    if (!worldHasMarketplace(world)) {
      return 'Marketplace unlocks at world prestige $minWorldPrestigeMarketplace.';
    }
    final standing = getStanding(
      resident.worldStandings[world.id]?.rep ?? 0,
    );
    if (standing.level < minStandingBrowseMarketplace) {
      final needed = standingLevels[minStandingBrowseMarketplace - 1];
      return 'Reach ${needed.title} standing (${needed.minRep} rep) to browse.';
    }
    return null;
  }

  static String? blockReasonCreateListing(
    Resident? resident,
    World world, {
    required bool isJoined,
  }) {
    if (resident == null) return 'Sign in to list items.';
    if (!isJoined) return 'Join this world to create listings.';
    if (!worldHasMarketplace(world)) {
      return 'Marketplace unlocks at world prestige $minWorldPrestigeMarketplace.';
    }
    if (resident.tier.value < minTierCreateListing) {
      return '${tierNames[minTierCreateListing] ?? 'High Roller'}+ tier required to sell.';
    }
    final standing = getStanding(
      resident.worldStandings[world.id]?.rep ?? 0,
    );
    if (standing.level < minStandingCreateListing) {
      final needed = standingLevels[minStandingCreateListing - 1];
      return 'Reach ${needed.title} standing (${needed.minRep} rep) to list items.';
    }
    return null;
  }

  /// Shown on marketplace / treasury screens (G3 tooltips).
  static String marketplaceRepHint() =>
      'Creating a listing: +2 rep. Buying: +3 rep for you, +5 for the seller.';

  static String createListingGateHint() =>
      'Requires ${tierNames[minTierCreateListing] ?? 'High Roller'}+ tier and '
      '${standingLevels[minStandingCreateListing - 1].title} standing '
      '(${standingLevels[minStandingCreateListing - 1].minRep} rep). World prestige '
      '$minWorldPrestigeMarketplace+ for marketplace.';

  static String? blockReasonTreasuryDonate(
    Resident? resident,
    World world, {
    required bool isJoined,
  }) {
    if (resident == null) return 'Sign in to donate.';
    if (!isJoined) return 'Join this world to donate.';
    if (!worldHasTreasury(world)) {
      return 'Treasury unlocks at world prestige $minWorldPrestigeTreasury.';
    }
    return null;
  }

  static ({int level, int activityScore, int progress, int range, double fraction, bool isMax})
      worldGrowth(World world) {
    final level = world.type == WorldType.dominion
        ? getWorldLevel(world.activityScore)
        : world.prestige.clamp(1, 10);
    final isDominion = world.type == WorldType.dominion;
    if (!isDominion) {
      return (
        level: level,
        activityScore: world.activityScore,
        progress: world.prestige,
        range: 50,
        fraction: (world.prestige / 50).clamp(0.0, 1.0),
        isMax: world.prestige >= 50,
      );
    }
    final nextLevel = (level + 1).clamp(1, 10);
    final nextThreshold = worldLevelThresholds[nextLevel] ?? 10000;
    final currentThreshold = worldLevelThresholds[level] ?? 0;
    final progress = world.activityScore - currentThreshold;
    final range = nextThreshold - currentThreshold;
    final fraction =
        range > 0 ? (progress / range).clamp(0.0, 1.0) : 1.0;
    return (
      level: level,
      activityScore: world.activityScore,
      progress: progress,
      range: range,
      fraction: fraction,
      isMax: level >= 10,
    );
  }
}
