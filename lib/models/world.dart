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
