import '../models/season.dart';
import '../models/world.dart';

class SeasonService {
  SeasonService._();

  /// Current season info derived from the available world activity snapshot.
  static Season getCurrentSeason({List<World>? worlds}) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 1);

    final scores = worlds != null && worlds.isNotEmpty
        ? getRankings(worlds)
        : <SeasonWorldScore>[];

    return Season(
      id: 'season-1',
      name: 'Current Season',
      startDate: startDate,
      endDate: endDate,
      isActive: true,
      scores: scores,
    );
  }

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
    final memberGrowth = 0;
    final achievements = 0;
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
    if (scores.isEmpty) return 'Competition is heating up';
    final top3 = scores.take(3).map((s) => s.worldName).toList();
    return 'Top 3 this week: ${top3.join(', ')}';
  }
}
