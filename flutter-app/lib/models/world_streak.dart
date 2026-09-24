class WorldStreak {
  final String residentId;
  final String worldId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActiveDate;

  const WorldStreak({
    required this.residentId,
    required this.worldId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastActiveDate,
  });

  WorldStreak copyWith({
    String? residentId,
    String? worldId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
  }) => WorldStreak(
    residentId: residentId ?? this.residentId,
    worldId: worldId ?? this.worldId,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    lastActiveDate: lastActiveDate ?? this.lastActiveDate,
  );

  Map<String, dynamic> toJson() => {
    'resident_id': residentId,
    'world_id': worldId,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'last_active_date': lastActiveDate.toIso8601String(),
  };

  static WorldStreak fromJson(Map<String, dynamic> json) => WorldStreak(
    residentId: json['resident_id'] as String,
    worldId: json['world_id'] as String,
    currentStreak: (json['current_streak'] as int?) ?? 0,
    longestStreak: (json['longest_streak'] as int?) ?? 0,
    lastActiveDate: DateTime.parse(json['last_active_date'] as String),
  );

  static WorldStreak fromSupabase(Map<String, dynamic> data) => WorldStreak(
    residentId: data['resident_id'] as String,
    worldId: data['world_id'] as String,
    currentStreak: (data['current_streak'] as int?) ?? 0,
    longestStreak: (data['longest_streak'] as int?) ?? 0,
    lastActiveDate: DateTime.parse(data['last_active_date'] as String),
  );
}
