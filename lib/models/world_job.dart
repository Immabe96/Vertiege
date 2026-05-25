enum WorldJobStatus { open, filled, closed }

class WorldJob {
  final String id;
  final String worldId;
  final String title;
  final String description;
  final String roleLabel;
  final int minStandingLevel;
  final int minTier;
  final WorldJobStatus status;
  final String createdBy;
  final DateTime createdAt;

  const WorldJob({
    required this.id,
    required this.worldId,
    required this.title,
    required this.description,
    required this.roleLabel,
    required this.minStandingLevel,
    required this.minTier,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isOpen => status == WorldJobStatus.open;

  factory WorldJob.fromSupabase(Map<String, dynamic> row) {
    return WorldJob(
      id: row['id'] as String,
      worldId: row['world_id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      roleLabel: row['role_label'] as String? ?? 'Contributor',
      minStandingLevel: (row['min_standing_level'] as num?)?.toInt() ?? 1,
      minTier: (row['min_tier'] as num?)?.toInt() ?? 1,
      status: _parseStatus(row['status'] as String?),
      createdBy: row['created_by'] as String? ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static WorldJobStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'filled':
        return WorldJobStatus.filled;
      case 'closed':
        return WorldJobStatus.closed;
      default:
        return WorldJobStatus.open;
    }
  }
}
