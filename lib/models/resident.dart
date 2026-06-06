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
  final int streakShields;
  final List<String> following;
  final List<String> joinedWorldIds;
  final Map<String, WorldStanding> worldStandings;
  final List<String> bannedWorldIds;
  final Map<String, int> mutedUntil;
  final int lastSeenAt;
  final String? referredBy;
  final String? title;
  final int sovereignCoins;
  final bool onboardingCompleted;
  final bool gateCompleted;
  final String? gateInterest;
  final String? avatarFrameId;
  final int totalXp;
  final int prestigeLevel;
  final int prestigeStars;
  final double referralXpMultiplier;
  final int successfulReferrals;
  final double xpMultiplier;
  final int dailyCoinBonus;
  final int customReactionSlots;
  final int postPinLimit;
  final int worldCreationLimit;
  final int lastActivityAt;
  final bool leaderboardOptOut;
  final String presenceMode;
  final String? customStatus;

  const Resident({
    required this.id,
    required this.name,
    this.tier = ResidentTier.hustlers,
    this.bio = '',
    this.avatarUrl = '',
    this.profession,
    this.verifiedRoles = const [],
    this.decorations = const [],
    this.wealthWorldsUnlocked = const [],
    this.badges = const [],
    this.lastCheckIn,
    this.streakCount = 0,
    this.streakShields = 0,
    this.following = const [],
    this.joinedWorldIds = const [],
    this.worldStandings = const {},
    this.bannedWorldIds = const [],
    this.mutedUntil = const {},
    this.lastSeenAt = 0,
    this.referredBy,
    this.title,
    this.sovereignCoins = 100,
    this.onboardingCompleted = false,
    this.gateCompleted = false,
    this.gateInterest,
    this.avatarFrameId,
    this.totalXp = 0,
    this.prestigeLevel = 0,
    this.prestigeStars = 0,
    this.referralXpMultiplier = 1.0,
    this.successfulReferrals = 0,
    this.xpMultiplier = 1.0,
    this.dailyCoinBonus = 0,
    this.customReactionSlots = 0,
    this.postPinLimit = 0,
    this.worldCreationLimit = 1,
    this.lastActivityAt = 0,
    this.leaderboardOptOut = false,
    this.presenceMode = 'online',
    this.customStatus,
  });

  /// Unique referral code derived from the resident's ID — first 8 chars,
  /// uppercased for readability.
  String get referralCode => id.isNotEmpty
      ? id.substring(0, id.length < 8 ? id.length : 8).toUpperCase()
      : '';

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
    int? streakShields,
    List<String>? following,
    List<String>? joinedWorldIds,
    Map<String, WorldStanding>? worldStandings,
    List<String>? bannedWorldIds,
    Map<String, int>? mutedUntil,
    int? lastSeenAt,
    String? referredBy,
    String? title,
    int? sovereignCoins,
    bool? onboardingCompleted,
    bool? gateCompleted,
    String? gateInterest,
    String? avatarFrameId,
    int? totalXp,
    int? prestigeLevel,
    int? prestigeStars,
    double? referralXpMultiplier,
    int? successfulReferrals,
    double? xpMultiplier,
    int? dailyCoinBonus,
    int? customReactionSlots,
    int? postPinLimit,
    int? worldCreationLimit,
    int? lastActivityAt,
    bool? leaderboardOptOut,
    String? presenceMode,
    String? customStatus,
  }) => Resident(
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
    streakShields: streakShields ?? this.streakShields,
    following: following ?? this.following,
    joinedWorldIds: joinedWorldIds ?? this.joinedWorldIds,
    worldStandings: worldStandings ?? this.worldStandings,
    bannedWorldIds: bannedWorldIds ?? this.bannedWorldIds,
    mutedUntil: mutedUntil ?? this.mutedUntil,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    referredBy: referredBy ?? this.referredBy,
    title: title ?? this.title,
    sovereignCoins: sovereignCoins ?? this.sovereignCoins,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    gateCompleted: gateCompleted ?? this.gateCompleted,
    gateInterest: gateInterest ?? this.gateInterest,
    avatarFrameId: avatarFrameId ?? this.avatarFrameId,
    totalXp: totalXp ?? this.totalXp,
    prestigeLevel: prestigeLevel ?? this.prestigeLevel,
    prestigeStars: prestigeStars ?? this.prestigeStars,
    referralXpMultiplier: referralXpMultiplier ?? this.referralXpMultiplier,
    successfulReferrals: successfulReferrals ?? this.successfulReferrals,
    xpMultiplier: xpMultiplier ?? this.xpMultiplier,
    dailyCoinBonus: dailyCoinBonus ?? this.dailyCoinBonus,
    customReactionSlots: customReactionSlots ?? this.customReactionSlots,
    postPinLimit: postPinLimit ?? this.postPinLimit,
    worldCreationLimit: worldCreationLimit ?? this.worldCreationLimit,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    leaderboardOptOut: leaderboardOptOut ?? this.leaderboardOptOut,
    presenceMode: presenceMode ?? this.presenceMode,
    customStatus: customStatus ?? this.customStatus,
  );
}
