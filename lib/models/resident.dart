enum ResidentTier {
  hustlers(1, 'Hustler'),
  highRollers(2, 'High Roller'),
  elite(3, 'Elite'),
  oldMoney(4, 'Old Money'),
  apex(5, 'Apex');

  const ResidentTier(this.value, this.label);
  final int value;
  final String label;

  static ResidentTier fromValue(int value) {
    return ResidentTier.values.firstWhere(
      (t) => t.value == value,
      orElse: () => ResidentTier.hustlers,
    );
  }

  static ResidentTier fromXp(int totalXp) {
    if (totalXp >= 50000) return ResidentTier.apex;
    if (totalXp >= 10000) return ResidentTier.oldMoney;
    if (totalXp >= 2000) return ResidentTier.elite;
    if (totalXp >= 500) return ResidentTier.highRollers;
    return ResidentTier.hustlers;
  }
}

enum VerificationStatus { idle, verifying, success, failed }

class WorldStanding {
  final int rep;
  const WorldStanding({this.rep = 0});

  WorldStanding copyWith({int? rep}) => WorldStanding(rep: rep ?? this.rep);
}

class Resident {
  final String id;
  final String name;
  final ResidentTier tier;
  final String bio;
  final String avatarUrl;
  final String? profession;
  final List<String> verifiedRoles;
  final List<String> decorations;
  final List<String> wealthWorldsUnlocked;
  final List<String> badges;
  final String? lastCheckIn;
  final int streakCount;
  final List<String> following;
  final List<String> joinedWorldIds;
  final Map<String, WorldStanding> worldStandings;

  const Resident({
    required this.id,
    required this.name,
    this.tier = ResidentTier.hustlers,
    this.bio = '',
    this.avatarUrl = 'https://via.placeholder.com/150',
    this.profession,
    this.verifiedRoles = const [],
    this.decorations = const [],
    this.wealthWorldsUnlocked = const [],
    this.badges = const [],
    this.lastCheckIn,
    this.streakCount = 0,
    this.following = const [],
    this.joinedWorldIds = const [],
    this.worldStandings = const {},
  });

  Resident copyWith({
    String? id,
    String? name,
    ResidentTier? tier,
    String? bio,
    String? avatarUrl,
    String? profession,
    List<String>? verifiedRoles,
    List<String>? decorations,
    List<String>? wealthWorldsUnlocked,
    List<String>? badges,
    String? lastCheckIn,
    int? streakCount,
    List<String>? following,
    List<String>? joinedWorldIds,
    Map<String, WorldStanding>? worldStandings,
  }) =>
      Resident(
        id: id ?? this.id,
        name: name ?? this.name,
        tier: tier ?? this.tier,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        profession: profession ?? this.profession,
        verifiedRoles: verifiedRoles ?? this.verifiedRoles,
        decorations: decorations ?? this.decorations,
        wealthWorldsUnlocked: wealthWorldsUnlocked ?? this.wealthWorldsUnlocked,
        badges: badges ?? this.badges,
        lastCheckIn: lastCheckIn ?? this.lastCheckIn,
        streakCount: streakCount ?? this.streakCount,
        following: following ?? this.following,
        joinedWorldIds: joinedWorldIds ?? this.joinedWorldIds,
        worldStandings: worldStandings ?? this.worldStandings,
      );
}
