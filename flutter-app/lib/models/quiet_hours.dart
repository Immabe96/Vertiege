class QuietHours {
  final String worldId;
  final int startHour;
  final int endHour;
  final bool enabled;

  const QuietHours({
    required this.worldId,
    this.startHour = 22,
    this.endHour = 8,
    this.enabled = false,
  });

  QuietHours copyWith({
    String? worldId,
    int? startHour,
    int? endHour,
    bool? enabled,
  }) => QuietHours(
    worldId: worldId ?? this.worldId,
    startHour: startHour ?? this.startHour,
    endHour: endHour ?? this.endHour,
    enabled: enabled ?? this.enabled,
  );

  Map<String, dynamic> toJson() => {
    'world_id': worldId,
    'start_hour': startHour,
    'end_hour': endHour,
    'enabled': enabled,
  };

  static QuietHours fromJson(Map<String, dynamic> json) => QuietHours(
    worldId: json['world_id'] as String,
    startHour: (json['start_hour'] as int?) ?? 22,
    endHour: (json['end_hour'] as int?) ?? 8,
    enabled: (json['enabled'] as bool?) ?? false,
  );

  static QuietHours fromSupabase(Map<String, dynamic> data) => QuietHours(
    worldId: data['world_id'] as String,
    startHour: (data['start_hour'] as int?) ?? 22,
    endHour: (data['end_hour'] as int?) ?? 8,
    enabled: (data['enabled'] as bool?) ?? false,
  );
}
