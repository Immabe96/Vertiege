class ArchiveDocument {
  final String id;
  final String worldId;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final int version;
  final List<Map<String, dynamic>> citations;
  final bool isPublished;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArchiveDocument({
    required this.id,
    required this.worldId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    this.category = 'general',
    this.tags = const [],
    this.version = 1,
    this.citations = const [],
    this.isPublished = false,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  static ArchiveDocument fromSupabase(Map<String, dynamic> data) => ArchiveDocument(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    authorId: data['author_id'] ?? '',
    authorName: data['author_name'] ?? '',
    title: data['title'] ?? '',
    content: data['content'] ?? '',
    category: data['category'] ?? 'general',
    tags: data['tags'] is List
        ? (data['tags'] as List).map((e) => e.toString()).toList()
        : [],
    version: (data['version'] as num?)?.toInt() ?? 1,
    citations: data['citations'] is List
        ? (data['citations'] as List).map((e) => e as Map<String, dynamic>).toList()
        : [],
    isPublished: data['is_published'] == true,
    viewCount: (data['view_count'] as num?)?.toInt() ?? 0,
    createdAt: _parseDate(data['created_at']),
    updatedAt: _parseDate(data['updated_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}

class ArchiveCurator {
  final String id;
  final String worldId;
  final String curatorId;
  final String curatorName;
  final String rank;
  final DateTime appointedAt;

  const ArchiveCurator({
    required this.id,
    required this.worldId,
    required this.curatorId,
    required this.curatorName,
    this.rank = 'curator',
    required this.appointedAt,
  });

  static ArchiveCurator fromSupabase(Map<String, dynamic> data) => ArchiveCurator(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    curatorId: data['curator_id'] ?? '',
    curatorName: data['curator_name'] ?? '',
    rank: data['rank'] ?? 'curator',
    appointedAt: _parseDate(data['appointed_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
