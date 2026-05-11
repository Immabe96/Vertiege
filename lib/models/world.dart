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

  Map<String, dynamic> toJson() => {
    'admission': admission,
    if (minTier != null) 'minTier': minTier,
    if (requiredProfession != null) 'requiredProfession': requiredProfession,
    'posting': posting,
    'commenting': commenting,
    'contentTypes': contentTypes,
    'entryFee': entryFee,
  };

  static WorldConstitution fromJson(Map<String, dynamic> json) =>
      WorldConstitution(
        admission: json['admission'] ?? 'open',
        minTier: json['minTier'],
        requiredProfession: json['requiredProfession'],
        posting: json['posting'] ?? 'all-members',
        commenting: json['commenting'] ?? 'all-members',
        contentTypes: List<String>.from(
          json['contentTypes'] ?? ['text', 'image'],
        ),
        entryFee: json['entryFee'] ?? 0,
      );
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
  final int activityScore;

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
    this.activityScore = 0,
  });
}

class World extends WorldBase {
  final int? requiredTier;
  final String? requiredProfession;
  final WorldConstitution constitution;
  final int boostCount;
  final int lastBoostMonth;

  static const int maxBoostsPerMonth = 3;
  static const int boostActivityPoints = 50;

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
    super.activityScore,
    this.requiredTier,
    this.requiredProfession,
    this.constitution = const WorldConstitution(),
    this.boostCount = 0,
    this.lastBoostMonth = 0,
  });

  /// Whether this world has been boosted (any boost count > 0 this month).
  bool get isBoosted => boostCount > 0 && boostsRemaining < maxBoostsPerMonth;

  /// How many boosts remain this month.
  int get boostsRemaining {
    final now = DateTime.now();
    final thisMonth = now.year * 12 + now.month;
    if (lastBoostMonth != thisMonth) return maxBoostsPerMonth;
    return (maxBoostsPerMonth - boostCount).clamp(0, maxBoostsPerMonth);
  }

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
    int? activityScore,
    int? requiredTier,
    String? requiredProfession,
    WorldConstitution? constitution,
    int? boostCount,
    int? lastBoostMonth,
  }) => World(
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
    activityScore: activityScore ?? this.activityScore,
    requiredTier: requiredTier ?? this.requiredTier,
    requiredProfession: requiredProfession ?? this.requiredProfession,
    constitution: constitution ?? this.constitution,
    boostCount: boostCount ?? this.boostCount,
    lastBoostMonth: lastBoostMonth ?? this.lastBoostMonth,
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
    'activityScore': activityScore,
    'boostCount': boostCount,
    'lastBoostMonth': lastBoostMonth,
    'constitution': constitution.toJson(),
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
    activityScore: json['activityScore'] ?? 0,
    boostCount: json['boostCount'] ?? 0,
    lastBoostMonth: json['lastBoostMonth'] ?? 0,
    constitution: json['constitution'] != null
        ? WorldConstitution.fromJson(json['constitution'])
        : const WorldConstitution(),
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
    memberCount: data['member_count'] ?? 0,
    icon: data['icon'] ?? 'earth',
    createdAt: data['created_at'] is int
        ? data['created_at'] as int
        : DateTime.tryParse(
                data['created_at']?.toString() ?? '',
              )?.millisecondsSinceEpoch ??
              0,
    activityScore: data['activity_score'] ?? 0,
    boostCount: data['boost_count'] ?? 0,
    lastBoostMonth: data['last_boost_month'] ?? 0,
    constitution: data['constitution'] != null
        ? WorldConstitution.fromJson(data['constitution'])
        : const WorldConstitution(),
    requiredTier: data['required_tier'],
    requiredProfession: data['required_profession'],
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
    super.activityScore,
    this.constitution = const WorldConstitution(),
    this.memberIds = const [],
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
