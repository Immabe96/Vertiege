class SeasonCohortSummary {
  final String id;
  final String seasonId;
  final String worldId;
  final String displayName;
  final int memberCount;
  final String? matchBand;

  const SeasonCohortSummary({
    required this.id,
    required this.seasonId,
    required this.worldId,
    required this.displayName,
    required this.memberCount,
    this.matchBand,
  });

  factory SeasonCohortSummary.fromJson(Map<String, dynamic> json) {
    return SeasonCohortSummary(
      id: json['id'] as String,
      seasonId: json['season_id'] as String,
      worldId: json['world_id'] as String,
      displayName: json['display_name'] as String? ?? 'Cohort',
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      matchBand: json['match_band'] as String?,
    );
  }
}
