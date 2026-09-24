class WorldTemplate {
  final String id;
  final String creatorId;
  final String name;
  final String description;
  final String dominionType;
  final Map<String, dynamic> templateData;
  final int usesCount;
  final bool isPublic;
  final DateTime createdAt;

  const WorldTemplate({
    required this.id,
    required this.creatorId,
    required this.name,
    this.description = '',
    this.dominionType = '',
    required this.templateData,
    this.usesCount = 0,
    this.isPublic = true,
    required this.createdAt,
  });

  static WorldTemplate fromSupabase(Map<String, dynamic> data) => WorldTemplate(
    id: data['id'] ?? '',
    creatorId: data['creator_id'] ?? '',
    name: data['name'] ?? '',
    description: data['description'] ?? '',
    dominionType: data['dominion_type'] ?? '',
    templateData: data['template_data'] as Map<String, dynamic>? ?? {},
    usesCount: (data['uses_count'] as num?)?.toInt() ?? 0,
    isPublic: data['is_public'] != false,
    createdAt: _parseDate(data['created_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
