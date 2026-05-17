class WorldRivalry {
  final String id;
  final String world1Id;
  final String world2Id;
  final String challengeType;
  final String status;
  final int world1Score;
  final int world2Score;
  final DateTime startedAt;
  final DateTime? resolvedAt;

  const WorldRivalry({
    required this.id,
    required this.world1Id,
    required this.world2Id,
    this.challengeType = 'general',
    this.status = 'active',
    this.world1Score = 0,
    this.world2Score = 0,
    required this.startedAt,
    this.resolvedAt,
  });

  bool get isResolved => status == 'resolved';
  String get winnerId {
    if (!isResolved) return '';
    if (world1Score > world2Score) return world1Id;
    if (world2Score > world1Score) return world2Id;
    return '';
  }

  static WorldRivalry fromSupabase(Map<String, dynamic> data) => WorldRivalry(
    id: data['id'] ?? '',
    world1Id: data['world_1_id'] ?? '',
    world2Id: data['world_2_id'] ?? '',
    challengeType: data['challenge_type'] ?? 'general',
    status: data['status'] ?? 'active',
    world1Score: (data['world_1_score'] as num?)?.toInt() ?? 0,
    world2Score: (data['world_2_score'] as num?)?.toInt() ?? 0,
    startedAt: _parseDate(data['started_at']),
    resolvedAt: data['resolved_at'] != null ? _parseDate(data['resolved_at']) : null,
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
