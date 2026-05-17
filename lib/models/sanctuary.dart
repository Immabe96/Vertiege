class SanctuaryMood {
  final String id;
  final String worldId;
  final String residentId;
  final int moodLevel;
  final String? moodNote;
  final DateTime createdAt;

  const SanctuaryMood({
    required this.id,
    required this.worldId,
    required this.residentId,
    required this.moodLevel,
    this.moodNote,
    required this.createdAt,
  });

  static SanctuaryMood fromSupabase(Map<String, dynamic> data) => SanctuaryMood(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    residentId: data['resident_id'] ?? '',
    moodLevel: (data['mood_level'] as num?)?.toInt() ?? 3,
    moodNote: data['mood_note'],
    createdAt: _parseDate(data['created_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}

class SanctuaryGratitude {
  final String id;
  final String worldId;
  final String authorId;
  final String authorName;
  final String content;
  final bool isAnonymous;
  final DateTime createdAt;

  const SanctuaryGratitude({
    required this.id,
    required this.worldId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.isAnonymous = false,
    required this.createdAt,
  });

  String get displayName => isAnonymous ? 'Anonymous' : authorName;

  static SanctuaryGratitude fromSupabase(Map<String, dynamic> data) => SanctuaryGratitude(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    authorId: data['author_id'] ?? '',
    authorName: data['author_name'] ?? '',
    content: data['content'] ?? '',
    isAnonymous: data['is_anonymous'] == true,
    createdAt: _parseDate(data['created_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
