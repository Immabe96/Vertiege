enum WorldType { wealth, profession, dominion }

class WorldConstitution {
  final String admission;
  final int? minTier;
  final String? requiredProfession;
  final String posting;
  final String commenting;
  final List<String> contentTypes;
  final int entryFee;

  const WorldConstitution({
    this.admission = 'open',
    this.minTier,
    this.requiredProfession,
    this.posting = 'all-members',
    this.commenting = 'all-members',
    this.contentTypes = const ['text', 'image'],
    this.entryFee = 0,
  });
}

class WorldBase {
  final String id;
  final String name;
  final WorldType type;
  final String description;
  final String sovereignId;
  final String sovereignName;
  final int prestige;
  final int memberCount;
  final String icon;
  final int createdAt;

  const WorldBase({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.sovereignId,
    required this.sovereignName,
    this.prestige = 1,
    this.memberCount = 0,
    this.icon = 'earth',
    this.createdAt = 0,
  });
}

class World extends WorldBase {
  final int? requiredTier;
  final String? requiredProfession;

  const World({
    required super.id,
    required super.name,
    required super.type,
    required super.description,
    required super.sovereignId,
    required super.sovereignName,
    super.prestige,
    super.memberCount,
    super.icon,
    super.createdAt,
    this.requiredTier,
    this.requiredProfession,
  });

  World copyWith({
    String? id,
    String? name,
    WorldType? type,
    String? description,
    String? sovereignId,
    String? sovereignName,
    int? prestige,
    int? memberCount,
    String? icon,
    int? createdAt,
    int? requiredTier,
    String? requiredProfession,
  }) =>
      World(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        description: description ?? this.description,
        sovereignId: sovereignId ?? this.sovereignId,
        sovereignName: sovereignName ?? this.sovereignName,
        prestige: prestige ?? this.prestige,
        memberCount: memberCount ?? this.memberCount,
        icon: icon ?? this.icon,
        createdAt: createdAt ?? this.createdAt,
        requiredTier: requiredTier ?? this.requiredTier,
        requiredProfession: requiredProfession ?? this.requiredProfession,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'description': description,
        'sovereignId': sovereignId,
        'sovereignName': sovereignName,
        'prestige': prestige,
        'memberCount': memberCount,
        'icon': icon,
        'createdAt': createdAt,
        if (requiredTier != null) 'requiredTier': requiredTier,
        if (requiredProfession != null) 'requiredProfession': requiredProfession,
      };

  static World fromJson(Map<String, dynamic> json) => World(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        type: _parseType(json['type']),
        description: json['description'] ?? '',
        sovereignId: json['sovereignId'] ?? '',
        sovereignName: json['sovereignName'] ?? '',
        prestige: json['prestige'] ?? 1,
        memberCount: json['memberCount'] ?? 0,
        icon: json['icon'] ?? 'earth',
        createdAt: json['createdAt'] ?? 0,
        requiredTier: json['requiredTier'],
        requiredProfession: json['requiredProfession'],
      );

  static World fromSupabase(Map<String, dynamic> data) => World(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        type: _parseType(data['type']),
        description: data['description'] ?? '',
        sovereignId: data['sovereign_id'] ?? '',
        sovereignName: data['sovereign_name'] ?? '',
        prestige: data['prestige'] ?? 1,
        icon: data['icon'] ?? 'earth',
        createdAt: DateTime.tryParse(data['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0,
      );

  static WorldType _parseType(String? type) {
    return WorldType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => WorldType.wealth,
    );
  }
}

class DominionWorld extends WorldBase {
  final WorldConstitution constitution;
  final List<String> memberIds;
  final int activityScore;

  const DominionWorld({
    required super.id,
    required super.name,
    required super.type,
    required super.description,
    required super.sovereignId,
    required super.sovereignName,
    super.prestige,
    super.memberCount,
    super.icon,
    super.createdAt,
    this.constitution = const WorldConstitution(),
    this.memberIds = const [],
    this.activityScore = 0,
  });

  @override
  WorldType get type => WorldType.dominion;
}

class WorldFeatures {
  final bool lounge;
  final bool events;
  final bool vault;
  final bool audioRooms;
  final bool marketplace;
  final bool treasury;
  final bool alliances;
  final bool landmarks;
  final bool governance;

  const WorldFeatures({
    this.lounge = false,
    this.events = false,
    this.vault = false,
    this.audioRooms = false,
    this.marketplace = false,
    this.treasury = false,
    this.alliances = false,
    this.landmarks = false,
    this.governance = false,
  });
}
