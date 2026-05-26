enum WorldType { wealth, profession, dominion }

enum DominionType {
  marketplace,
  academy,
  sanctuary,
  archive;

  String get displayName {
    switch (this) {
      case DominionType.marketplace:
        return 'Marketplace';
      case DominionType.academy:
        return 'Academy';
      case DominionType.sanctuary:
        return 'Sanctuary';
      case DominionType.archive:
        return 'Archive';
    }
  }

  String get icon {
    switch (this) {
      case DominionType.marketplace:
        return 'storefront';
      case DominionType.academy:
        return 'school';
      case DominionType.sanctuary:
        return 'self_improvement';
      case DominionType.archive:
        return 'menu_book';
    }
  }

  String get lore {
    switch (this) {
      case DominionType.marketplace:
        return 'The Grand Bazaar — ancient trading crossroads where commerce flows like rivers.';
      case DominionType.academy:
        return 'The Athenaeum — where knowledge is forged and wisdom is shared.';
      case DominionType.sanctuary:
        return 'A community space for residents to connect and grow together.';
      case DominionType.archive:
        return 'The Vault of Ages — keeper of all knowledge and truth.';
    }
  }

  String get defaultCurrencyName {
    switch (this) {
      case DominionType.marketplace:
        return 'Credits';
      case DominionType.academy:
        return 'Scholar Coins';
      case DominionType.sanctuary:
        return 'Harmony Points';
      case DominionType.archive:
        return 'Quills';
    }
  }

  List<String> get defaultTags {
    switch (this) {
      case DominionType.marketplace:
        return ['trading', 'commerce', 'economy'];
      case DominionType.academy:
        return ['education', 'learning', 'courses'];
      case DominionType.sanctuary:
        return ['social', 'community', 'wellness'];
      case DominionType.archive:
        return ['knowledge', 'research', 'documents'];
    }
  }
}

class WorldConstitution {
  final String admission;
  final int? minTier;
  final String? requiredProfession;
  final String posting;
  final String commenting;
  final List<String> contentTypes;
  final int entryFee;
  final bool allowAnonymous;
  final bool requireApproval;
  final String language;

  const WorldConstitution({
    this.admission = 'open',
    this.minTier,
    this.requiredProfession,
    this.posting = 'all-members',
    this.commenting = 'all-members',
    this.contentTypes = const ['text', 'image'],
    this.entryFee = 0,
    this.allowAnonymous = false,
    this.requireApproval = false,
    this.language = 'en',
  });

  Map<String, dynamic> toJson() => {
    'admission': admission,
    if (minTier != null) 'minTier': minTier,
    if (requiredProfession != null) 'requiredProfession': requiredProfession,
    'posting': posting,
    'commenting': commenting,
    'contentTypes': contentTypes,
    'entryFee': entryFee,
    'allowAnonymous': allowAnonymous,
    'requireApproval': requireApproval,
    'language': language,
  };

  static WorldConstitution fromJson(Map<String, dynamic> json) {
    final rawContentTypes = json['contentTypes'];
    List<String> contentTypes;
    if (rawContentTypes is List) {
      contentTypes = rawContentTypes.map((e) => e.toString()).toList();
      if (contentTypes.isEmpty) contentTypes = ['text', 'image'];
    } else {
      contentTypes = ['text', 'image'];
    }

    return WorldConstitution(
      admission: json['admission'] is String ? json['admission'] as String : 'open',
      minTier: json['minTier'] is int ? json['minTier'] as int : null,
      requiredProfession: json['requiredProfession'] is String
          ? json['requiredProfession'] as String
          : null,
      posting: json['posting'] is String ? json['posting'] as String : 'all-members',
      commenting: json['commenting'] is String
          ? json['commenting'] as String
          : 'all-members',
      contentTypes: contentTypes,
      entryFee: json['entryFee'] is num ? (json['entryFee'] as num).toInt() : 0,
      allowAnonymous: json['allowAnonymous'] == true,
      requireApproval: json['requireApproval'] == true,
      language: json['language'] is String ? json['language'] as String : 'en',
    );
  }
}

class WorldBase {
  final String id;
  final String slug;
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
    this.slug = '',
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

  bool get isUnclaimed => sovereignId.isEmpty;

  bool get hasSovereign => sovereignId.isNotEmpty;

  String get sovereignDisplayName =>
      hasSovereign ? sovereignName : 'Unclaimed';

  String get sovereignStatusLabel => hasSovereign
      ? 'Sovereign: $sovereignName'
      : 'Unclaimed — first member becomes Sovereign';
}

class World extends WorldBase {
  final int? requiredTier;
  final String? requiredProfession;
  final WorldConstitution constitution;
  final int boostCount;
  final int lastBoostMonth;
  final bool isDefault;
  final int sortOrder;
  final String? bannerKey;
  final String motto;
  final String accentColor;
  final String lore;
  final List<Map<String, dynamic>> lineage;
  final List<String> tags;
  final String worldCurrencyName;
  final int taxRate;
  final int landmarkLevel;
  final DominionType? dominionType;
  final String welcomeMessage;

  static const int maxBoostsPerMonth = 3;
  static const int boostActivityPoints = 50;

  const World({
    required super.id,
    super.slug,
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
    this.isDefault = false,
    this.sortOrder = 0,
    this.bannerKey,
    this.motto = '',
    this.accentColor = '',
    this.lore = '',
    this.lineage = const [],
    this.tags = const [],
    this.worldCurrencyName = 'Coins',
    this.taxRate = 0,
    this.landmarkLevel = 1,
    this.dominionType,
    this.welcomeMessage = '',
  });

  String get assetKey => bannerKey ?? (slug.isNotEmpty ? slug : id);

  bool get isBoosted => boostCount > 0 && boostsRemaining > 0;

  int get boostsRemaining {
    final now = DateTime.now();
    final thisMonth = now.year * 12 + now.month;
    if (lastBoostMonth != thisMonth) return maxBoostsPerMonth;
    return (maxBoostsPerMonth - boostCount).clamp(0, maxBoostsPerMonth);
  }

  bool get isSanctuary => type == WorldType.dominion && dominionType == DominionType.sanctuary;
  bool get isMarketplace => type == WorldType.dominion && dominionType == DominionType.marketplace;
  bool get isAcademy => type == WorldType.dominion && dominionType == DominionType.academy;
  bool get isArchive => type == WorldType.dominion && dominionType == DominionType.archive;

  World copyWith({
    String? id,
    String? slug,
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
    bool? isDefault,
    int? sortOrder,
    String? bannerKey,
    String? motto,
    String? accentColor,
    String? lore,
    List<Map<String, dynamic>>? lineage,
    List<String>? tags,
    String? worldCurrencyName,
    int? taxRate,
    int? landmarkLevel,
    DominionType? dominionType,
    String? welcomeMessage,
  }) => World(
    id: id ?? this.id,
    slug: slug ?? this.slug,
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
    isDefault: isDefault ?? this.isDefault,
    sortOrder: sortOrder ?? this.sortOrder,
    bannerKey: bannerKey ?? this.bannerKey,
    motto: motto ?? this.motto,
    accentColor: accentColor ?? this.accentColor,
    lore: lore ?? this.lore,
    lineage: lineage ?? this.lineage,
    tags: tags ?? this.tags,
    worldCurrencyName: worldCurrencyName ?? this.worldCurrencyName,
    taxRate: taxRate ?? this.taxRate,
    landmarkLevel: landmarkLevel ?? this.landmarkLevel,
    dominionType: dominionType ?? this.dominionType,
    welcomeMessage: welcomeMessage ?? this.welcomeMessage,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
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
    'isDefault': isDefault,
    'sortOrder': sortOrder,
    'bannerKey': bannerKey,
    'constitution': constitution.toJson(),
    if (requiredTier != null) 'requiredTier': requiredTier,
    if (requiredProfession != null) 'requiredProfession': requiredProfession,
    'motto': motto,
    'accentColor': accentColor,
    'lore': lore,
    'lineage': lineage,
    'tags': tags,
    'worldCurrencyName': worldCurrencyName,
    'taxRate': taxRate,
    'landmarkLevel': landmarkLevel,
    if (dominionType != null) 'dominionType': dominionType!.name,
    'welcomeMessage': welcomeMessage,
  };

  static World fromJson(Map<String, dynamic> json) => World(
    id: json['id'] ?? '',
    slug: json['slug'] ?? json['id'] ?? '',
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
    isDefault: json['isDefault'] ?? false,
    sortOrder: json['sortOrder'] ?? 0,
    bannerKey: json['bannerKey'],
    constitution: json['constitution'] != null
        ? WorldConstitution.fromJson(json['constitution'])
        : const WorldConstitution(),
    requiredTier: json['requiredTier'],
    requiredProfession: json['requiredProfession'],
    motto: json['motto'] ?? '',
    accentColor: json['accentColor'] ?? '',
    lore: json['lore'] ?? '',
    lineage: json['lineage'] is List
        ? (json['lineage'] as List).map((e) => e as Map<String, dynamic>).toList()
        : [],
    tags: json['tags'] is List
        ? (json['tags'] as List).map((e) => e.toString()).toList()
        : [],
    worldCurrencyName: json['worldCurrencyName'] ?? 'Coins',
    taxRate: json['taxRate'] ?? 0,
    landmarkLevel: json['landmarkLevel'] ?? 1,
    dominionType: _parseDominionType(json['dominionType']),
    welcomeMessage: json['welcomeMessage'] ?? '',
  );

  static World fromSupabase(Map<String, dynamic> data) => World(
    id: data['id'] ?? '',
    slug: data['slug'] ?? '',
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
    lastBoostMonth: data['last_boost_month'] is String
        ? int.tryParse(data['last_boost_month']) ?? 0
        : data['last_boost_month'] ?? 0,
    isDefault: data['is_default'] ?? false,
    sortOrder: data['sort_order'] ?? 0,
    bannerKey: data['banner_key'] ?? data['banner'],
    constitution: data['constitution'] != null
        ? WorldConstitution.fromJson(data['constitution'])
        : const WorldConstitution(),
    requiredTier: data['required_tier'],
    requiredProfession: data['required_profession'],
    motto: data['motto'] ?? '',
    accentColor: data['accent_color'] ?? '',
    lore: data['lore'] ?? '',
    lineage: data['lineage'] is List
        ? (data['lineage'] as List).map((e) => e as Map<String, dynamic>).toList()
        : [],
    tags: data['tags'] is List
        ? (data['tags'] as List).map((e) => e.toString()).toList()
        : [],
    worldCurrencyName: data['world_currency_name'] ?? 'Coins',
    taxRate: data['tax_rate'] ?? 0,
    landmarkLevel: data['landmark_level'] ?? 1,
    dominionType: _parseDominionType(data['dominion_type']),
    welcomeMessage: data['welcome_message'] ?? '',
  );

  static WorldType _parseType(String? type) {
    return WorldType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => WorldType.wealth,
    );
  }

  static DominionType? _parseDominionType(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'academy' || raw == 'archive') {
      return DominionType.sanctuary;
    }
    return DominionType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => DominionType.sanctuary,
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
