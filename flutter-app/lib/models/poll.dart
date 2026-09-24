class WorldPoll {
  final String id;
  final String worldId;
  final String? channelId;
  final String question;
  final List<String> options;
  final Map<int, int> results;
  final String createdBy;
  final int? expiresAt;
  final bool isClosed;
  final DateTime createdAt;

  const WorldPoll({
    required this.id,
    required this.worldId,
    this.channelId,
    required this.question,
    required this.options,
    this.results = const {},
    required this.createdBy,
    this.expiresAt,
    this.isClosed = false,
    required this.createdAt,
  });

  int get totalVotes => results.values.fold(0, (sum, v) => sum + v);

  bool get isActive => !isClosed && (expiresAt == null || DateTime.now().millisecondsSinceEpoch < expiresAt!);

  Map<String, dynamic> toJson() => {
    'id': id,
    'world_id': worldId,
    if (channelId != null) 'channel_id': channelId,
    'question': question,
    'options': options,
    'results': results.map((k, v) => MapEntry(k.toString(), v)),
    'created_by': createdBy,
    if (expiresAt != null) 'expires_at': expiresAt,
    'is_closed': isClosed,
    'created_at': createdAt.toIso8601String(),
  };

  factory WorldPoll.fromJson(Map<String, dynamic> json) =>
      WorldPoll.fromSupabase(json);

  static WorldPoll fromSupabase(Map<String, dynamic> data) => WorldPoll(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    channelId: data['channel_id'],
    question: data['question'] ?? '',
    options: (data['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
    results: _parseResults(data['results']),
    createdBy: data['created_by'] ?? '',
    expiresAt: data['expires_at'],
    isClosed: data['is_closed'] == true,
    createdAt: _parseDate(data['created_at']),
  );

  static Map<int, int> _parseResults(dynamic raw) {
    if (raw is! Map) return {};
    final out = <int, int>{};
    for (final entry in raw.entries) {
      final idx = int.tryParse(entry.key.toString());
      if (idx == null) continue;
      final value = entry.value;
      if (value is num) {
        out[idx] = value.toInt();
      } else if (value is Map) {
        final count = value['count'];
        if (count is num) {
          out[idx] = count.toInt();
        }
      }
    }
    return out;
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
