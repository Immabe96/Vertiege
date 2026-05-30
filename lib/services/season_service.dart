import '../config/season_catalog.dart';
import '../models/season.dart';
import '../models/world.dart';

class SeasonService {
  SeasonService._();

  /// Season 1 — The Big Bang: world growth leaderboard (not league brackets).
  static Season getCurrentSeason({List<World>? worlds}) {
    final def = SeasonCatalog.active;
    final startDate = DateTime.utc(2026, 1, 1);
    final endDate = DateTime.utc(2026, 12, 31, 23, 59, 59);

    final eligibleWorlds = worlds
            ?.where((w) => !w.isMarketplace)
            .toList() ??
        <World>[];

    final scores = eligibleWorlds.isNotEmpty
        ? getRankings(eligibleWorlds)
        : <SeasonWorldScore>[];

    return Season(
      id: def.id,
      name: def.name,
      tagline: def.tagline,
      narrative: def.narrative,
      pillars: def.pillars,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
      scores: scores,
    );
  }

  /// Worlds with no sovereign yet — "empty" realms waiting to be claimed.
  static List<World> unclaimedWorlds(List<World> worlds) =>
      worlds.where((w) => !w.isMarketplace && w.isUnclaimed).toList();

  /// Worlds that gained prestige this season snapshot (growth signal).
  static int growingWorldCount(List<World> worlds) =>
      worlds.where((w) => !w.isMarketplace && w.prestige >= 5).length;

  /// Calculate composite score for a world.
  /// Activity is weighted x2, member growth x10, achievements x5.
  static int calculateCompositeScore(
    int activity,
    int memberGrowth,
    int achievements,
  ) {
    return (activity * 2) + (memberGrowth * 10) + (achievements * 5);
  }

  /// Derive seasonal stats from fields already tracked by the app.
  static SeasonWorldScore scoreFromWorld(World world) {
    final activity = world.activityScore;
    final memberGrowth = world.memberCount;
    final achievements = world.prestige;
    final composite = calculateCompositeScore(
      activity,
      memberGrowth,
      achievements,
    );

    return SeasonWorldScore(
      worldId: world.id,
      worldName: world.name,
      activityScore: activity,
      memberGrowth: memberGrowth,
      achievementCount: achievements,
      compositeScore: composite,
      rank: 0, // assigned by getRankings
    );
  }

  /// Get ranked worlds for current season.
  /// Returns top 10 entries sorted by composite score descending.
  static List<SeasonWorldScore> getRankings(List<World> worlds) {
    final scored = worlds.map(scoreFromWorld).toList()
      ..sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

    final top10 = scored.take(10).toList();

    // Assign ranks (1-indexed)
    for (int i = 0; i < top10.length; i++) {
      top10[i] = top10[i].copyWith(rank: i + 1);
    }

    return top10;
  }

  /// Determines the season banner message from top scores.
  static String bannerSubtitle(List<SeasonWorldScore> scores) {
    if (scores.isEmpty) {
      return 'The Big Bang: claim empty worlds and grow your realm';
    }
    final top3 = scores.take(3).map((s) => s.worldName).toList();
    return 'Fastest growing realms: ${top3.join(', ')}';
  }
}
