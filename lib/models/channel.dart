enum ChannelType { text, announcement, feed }

class WorldChannel {
  final String id;
  final String worldId;
  final String name;
  final String? description;
  final ChannelType channelType;
  final int position;
  final bool isDefault;
  final int createdAt;

  const WorldChannel({
    required this.id,
    required this.worldId,
    required this.name,
    this.description,
    this.channelType = ChannelType.text,
    this.position = 0,
    this.isDefault = false,
    this.createdAt = 0,
  });

  WorldChannel copyWith({
    String? id,
    String? worldId,
    String? name,
    String? description,
    ChannelType? channelType,
    int? position,
    bool? isDefault,
    int? createdAt,
  }) =>
      WorldChannel(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        name: name ?? this.name,
        description: description ?? this.description,
        channelType: channelType ?? this.channelType,
        position: position ?? this.position,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'worldId': worldId,
        'name': name,
        'description': description,
        'channelType': channelType.name,
        'position': position,
        'isDefault': isDefault,
        'createdAt': createdAt,
      };

  static WorldChannel fromJson(Map<String, dynamic> json) => WorldChannel(
        id: json['id'] ?? '',
        worldId: json['worldId'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        channelType: ChannelType.values.firstWhere(
          (c) => c.name == json['channelType'],
          orElse: () => ChannelType.text,
        ),
        position: json['position'] ?? 0,
        isDefault: json['isDefault'] ?? false,
        createdAt: json['createdAt'] ?? 0,
      );
}
