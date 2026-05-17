enum ChannelType { text, announcement, feed, voice }

class District {
  final String id;
  final String worldId;
  final String name;
  final int position;

  const District({
    required this.id,
    required this.worldId,
    required this.name,
    this.position = 0,
  });

  factory District.fromSupabase(Map<String, dynamic> data) => District(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    name: data['name'] ?? '',
    position: data['position'] ?? 0,
  );

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'world_id': worldId,
    'name': name,
    'position': position,
  };
}

class ChannelRead {
  final String residentId;
  final String channelId;
  final DateTime lastReadAt;

  const ChannelRead({
    required this.residentId,
    required this.channelId,
    required this.lastReadAt,
  });

  factory ChannelRead.fromSupabase(Map<String, dynamic> data) => ChannelRead(
    residentId: data['resident_id'] ?? '',
    channelId: data['channel_id'] ?? '',
    lastReadAt: DateTime.tryParse(data['last_read_at'] ?? '') ?? DateTime(2000),
  );

  Map<String, dynamic> toSupabase() => {
    'resident_id': residentId,
    'channel_id': channelId,
    'last_read_at': lastReadAt.toIso8601String(),
  };
}

class WorldChannel {
  final String id;
  final String worldId;
  final String name;
  final String? description;
  final ChannelType channelType;
  final String? wardId;
  final String? wardName;
  final int position;
  final bool isDefault;
  final int createdAt;

  const WorldChannel({
    required this.id,
    required this.worldId,
    required this.name,
    this.description,
    this.channelType = ChannelType.text,
    this.wardId,
    this.wardName,
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
    String? wardId,
    String? wardName,
    int? position,
    bool? isDefault,
    int? createdAt,
  }) => WorldChannel(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    name: name ?? this.name,
    description: description ?? this.description,
    channelType: channelType ?? this.channelType,
    wardId: wardId ?? this.wardId,
    wardName: wardName ?? this.wardName,
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
    'wardId': wardId,
    'wardName': wardName,
    'position': position,
    'isDefault': isDefault,
    'createdAt': createdAt,
  };

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'world_id': worldId,
    'name': name,
    'description': description,
    'channel_type': channelType.name,
    'ward_id': wardId,
    'ward_name': wardName,
    'position': position,
    'is_default': isDefault,
    'created_at': DateTime.fromMillisecondsSinceEpoch(
      createdAt,
    ).toIso8601String(),
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
    wardId: json['wardId'],
    wardName: json['wardName'],
    position: json['position'] ?? 0,
    isDefault: json['isDefault'] ?? false,
    createdAt: json['createdAt'] ?? 0,
  );

  static WorldChannel fromSupabase(Map<String, dynamic> data) => WorldChannel(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    name: data['name'] ?? '',
    description: data['description'],
    channelType: ChannelType.values.firstWhere(
      (c) => c.name == data['channel_type'],
      orElse: () => ChannelType.text,
    ),
    wardId: data['ward_id'],
    wardName: data['ward_name'],
    position: data['position'] ?? 0,
    isDefault: data['is_default'] ?? false,
    createdAt:
        DateTime.tryParse(data['created_at'] ?? '')?.millisecondsSinceEpoch ??
        0,
  );
}
