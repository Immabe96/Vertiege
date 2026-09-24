class Alliance {
  final String id;
  final String worldId1;
  final String worldId2;
  final String worldName1;
  final String worldName2;
  final DateTime formedAt;

  const Alliance({
    required this.id,
    required this.worldId1,
    required this.worldId2,
    required this.worldName1,
    required this.worldName2,
    required this.formedAt,
  });

  /// Returns the "other" world ID given one of the two allied worlds.
  String allieOf(String worldId) {
    if (worldId == worldId1) return worldId2;
    return worldId1;
  }

  /// Returns the name of the allied world from the perspective of [worldId].
  String allyName(String worldId) {
    if (worldId == worldId1) return worldName2;
    return worldName1;
  }

  Alliance copyWith({
    String? id,
    String? worldId1,
    String? worldId2,
    String? worldName1,
    String? worldName2,
    DateTime? formedAt,
  }) => Alliance(
    id: id ?? this.id,
    worldId1: worldId1 ?? this.worldId1,
    worldId2: worldId2 ?? this.worldId2,
    worldName1: worldName1 ?? this.worldName1,
    worldName2: worldName2 ?? this.worldName2,
    formedAt: formedAt ?? this.formedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldId1': worldId1,
    'worldId2': worldId2,
    'worldName1': worldName1,
    'worldName2': worldName2,
    'formedAt': formedAt.toIso8601String(),
  };

  factory Alliance.fromJson(Map<String, dynamic> json) => Alliance(
    id: json['id'] ?? '',
    worldId1: json['worldId1'] ?? '',
    worldId2: json['worldId2'] ?? '',
    worldName1: json['worldName1'] ?? '',
    worldName2: json['worldName2'] ?? '',
    formedAt: DateTime.tryParse(json['formedAt'] ?? '') ?? DateTime.now(),
  );
}
