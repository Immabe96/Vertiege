class SeasonWorldScore {
  final String worldId;
  final String worldName;
  final int activityScore;
  final int memberGrowth;
  final int achievementCount;
  final int compositeScore;
  final int rank;

  const SeasonWorldScore({
    required this.worldId,
    required this.worldName,
    required this.activityScore,
    required this.memberGrowth,
    required this.achievementCount,
    required this.compositeScore,
    required this.rank,
  });

  /// Trend direction for UI display: >0 trending up, <0 trending down, 0 neutral.
  int get trend => compositeScore > 100 ? 1 : compositeScore > 0 ? 0 : -1;

  SeasonWorldScore copyWith({int? rank}) => SeasonWorldScore(
        worldId: worldId,
        worldName: worldName,
        activityScore: activityScore,
        memberGrowth: memberGrowth,
        achievementCount: achievementCount,
        compositeScore: compositeScore,
        rank: rank ?? this.rank,
      );
}

class Season {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<SeasonWorldScore> scores;

  const Season({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.scores,
  });

  int get totalDays => endDate.difference(startDate).inDays;

  int get daysRemaining =>
      endDate.difference(DateTime.now()).inDays.clamp(0, totalDays);

  int get daysElapsed => totalDays - daysRemaining;

  /// Which week of the season we are in (1-indexed, max 4).
  int get currentWeek => (daysElapsed ~/ 7).clamp(0, 3) + 1;

  double get progress =>
      (daysElapsed / totalDays).clamp(0.0, 1.0);

  /// Whether this season has ended.
  bool get hasEnded => DateTime.now().isAfter(endDate);

  /// Top score, or null if no scores.
  SeasonWorldScore? get topScore =>
      scores.isNotEmpty ? scores.first : null;
}
