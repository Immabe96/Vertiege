class WorldEvent {
  final String id;
  final String worldId;
  final String title;
  final String description;
  final String createdBy;
  final String createdByName;
  final int startsAt;
  final int endsAt;
  final int createdAt;
  final List<String> rsvpIds;

  const WorldEvent({
    required this.id,
    required this.worldId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.startsAt,
    this.endsAt = 0,
    this.createdAt = 0,
    this.rsvpIds = const [],
  });

  bool get isUpcoming => startsAt > DateTime.now().millisecondsSinceEpoch;

  WorldEvent copyWith({
    String? id,
    String? worldId,
    String? title,
    String? description,
    String? createdBy,
    String? createdByName,
    int? startsAt,
    int? endsAt,
    int? createdAt,
    List<String>? rsvpIds,
  }) =>
      WorldEvent(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        title: title ?? this.title,
        description: description ?? this.description,
        createdBy: createdBy ?? this.createdBy,
        createdByName: createdByName ?? this.createdByName,
        startsAt: startsAt ?? this.startsAt,
        endsAt: endsAt ?? this.endsAt,
        createdAt: createdAt ?? this.createdAt,
        rsvpIds: rsvpIds ?? this.rsvpIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'worldId': worldId,
        'title': title,
        'description': description,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'startsAt': startsAt,
        'endsAt': endsAt,
        'createdAt': createdAt,
        'rsvpIds': rsvpIds,
      };

  static WorldEvent fromJson(Map<String, dynamic> json) => WorldEvent(
        id: json['id'] ?? '',
        worldId: json['worldId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        createdBy: json['createdBy'] ?? '',
        createdByName: json['createdByName'] ?? '',
        startsAt: json['startsAt'] ?? 0,
        endsAt: json['endsAt'] ?? 0,
        createdAt: json['createdAt'] ?? 0,
        rsvpIds: List<String>.from(json['rsvpIds'] ?? []),
      );
}
