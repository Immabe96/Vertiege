import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resident.dart';
import '../models/world.dart';
import '../config/tiers.dart';
import '../services/media_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../services/world_service.dart';
import '../services/moderation_service.dart';
import '../services/verification_service.dart';
import '../services/supabase.dart';
import '../utils/haptics.dart';
import 'achievement_provider.dart';
import 'world_provider.dart';
import 'post_provider.dart';
import 'notification_provider.dart';

class ResidentState {
  final Resident? resident;
  final bool isLoading;
  final VerificationStatus verificationStatus;

  const ResidentState({
    this.resident,
    this.isLoading = true,
    this.verificationStatus = VerificationStatus.idle,
  });

  ResidentState copyWith({
    Resident? resident,
    bool? isLoading,
    VerificationStatus? verificationStatus,
  }) => ResidentState(
    resident: resident ?? this.resident,
    isLoading: isLoading ?? this.isLoading,
    verificationStatus: verificationStatus ?? this.verificationStatus,
  );
}

class ResidentNotifier extends Notifier<ResidentState> {
  @override
  ResidentState build() => const ResidentState();

  Future<void> loadResident() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = maybeSupabase()?.auth.currentUser?.id;
      if (userId == null) {
        state = const ResidentState(isLoading: false);
        return;
      }
      // Fetch from Supabase first
      final remote = await ProfileService.getProfile(userId);
      if (remote != null) {
        final cached = await _cachedResidentFor(userId);
        final resident = cached != null && remote.joinedWorldIds.isEmpty
            ? remote.copyWith(joinedWorldIds: cached.joinedWorldIds)
            : remote;
        state = ResidentState(resident: resident, isLoading: false);
        _persist(); // cache locally
        return;
      }
      // Fallback to local cache
      final cached = await _cachedResidentFor(userId);
      if (cached != null) {
        state = ResidentState(resident: cached, isLoading: false);
        return;
      }
      state = const ResidentState(isLoading: false);
    } catch (_) {
      state = const ResidentState(isLoading: false);
    }
  }

  void setResident(Resident resident) {
    state = state.copyWith(resident: resident);
    _persist();
    _saveResidentProfile(resident);
  }

  Future<void> _saveResidentProfile(Resident resident) async {
    var durableResident = resident;
    if (resident.avatarUrl.isNotEmpty &&
        !resident.avatarUrl.startsWith('http') &&
        !resident.avatarUrl.startsWith('assets/')) {
      final uploaded = await MediaService.uploadAvatar(
        resident.avatarUrl,
        resident.id,
      );
      if (uploaded != null && state.resident?.id == resident.id) {
        durableResident = resident.copyWith(avatarUrl: uploaded);
        state = state.copyWith(resident: durableResident);
        _persist();
      }
    }

    await ProfileService.upsertProfile(durableResident);
    for (final worldId in durableResident.joinedWorldIds) {
      try {
        await WorldService.joinWorld(
          worldId,
          durableResident.id,
          residentName: durableResident.name,
        );
      } catch (_) {
        // Some seeded worlds are local catalog ids until the database is seeded.
      }
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? avatarPath, // local file path → gets uploaded to Supabase Storage
    String? profession,
  }) async {
    final r = state.resident;
    if (r == null) return;
    if (name != null && (name.isEmpty || name.length > 100)) return;
    if (bio != null && bio.length > 500) return;

    String? cloudUrl = r.avatarUrl;
    if (avatarPath != null) {
      final uploaded = await MediaService.uploadAvatar(avatarPath, r.id);
      if (uploaded != null) cloudUrl = uploaded;
    }

    state = state.copyWith(
      resident: r.copyWith(
        name: name ?? r.name,
        bio: bio ?? r.bio,
        avatarUrl: cloudUrl,
        profession: profession ?? r.profession,
      ),
    );
    _persist();
    // Save to Supabase
    if (state.resident != null) {
      _saveResidentProfile(state.resident!);
    }
  }

  void updateTier(ResidentTier tier) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(resident: r.copyWith(tier: tier));
    _persist();
  }

  ({int streak, int bonusXp, bool shieldUsed})? checkInToday() {
    final r = state.resident;
    if (r == null) return null;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    if (r.lastCheckIn == today) return null;

    final lastDate = r.lastCheckIn?.substring(0, 10);
    bool shieldUsed = false;

    int newStreak;
    if (lastDate == null) {
      newStreak = 1;
    } else if (lastDate == yesterday) {
      newStreak = r.streakCount + 1;
    } else {
      final dayBeforeYesterday = DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String()
          .substring(0, 10);
      if (r.streakShields > 0 && lastDate == dayBeforeYesterday) {
        newStreak = r.streakCount + 1;
        shieldUsed = true;
      } else {
        newStreak = 1;
      }
    }

    final bonusXp = _getStreakBonusXp(newStreak);

    final updatedShields = shieldUsed ? r.streakShields - 1 : r.streakShields;

    state = state.copyWith(
      resident: r.copyWith(
        lastCheckIn: today,
        streakCount: newStreak,
        streakShields: updatedShields,
      ),
    );
    _persist();
    _checkStreakMilestones(newStreak);
    return (streak: newStreak, bonusXp: bonusXp, shieldUsed: shieldUsed);
  }

  int _getStreakBonusXp(int streak) {
    const milestones = {
      3: 10,
      7: 50,
      14: 100,
      30: 200,
      60: 500,
      90: 1000,
      180: 2500,
      365: 5000,
    };
    return milestones[streak] ?? 0;
  }

  void follow(String residentId) {
    final r = state.resident;
    if (r == null || r.following.contains(residentId)) return;
    state = state.copyWith(
      resident: r.copyWith(following: [...r.following, residentId]),
    );
    _persist();
  }

  void unfollow(String residentId) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(
      resident: r.copyWith(
        following: r.following.where((id) => id != residentId).toList(),
      ),
    );
    _persist();
  }

  bool isFollowing(String residentId) {
    return state.resident?.following.contains(residentId) ?? false;
  }

  void addRep(String worldId, int amount) {
    final r = state.resident;
    if (r == null) return;
    final standings = Map<String, WorldStanding>.from(r.worldStandings);
    final current = standings[worldId]?.rep ?? 0;
    standings[worldId] = WorldStanding(rep: current + amount);
    state = state.copyWith(resident: r.copyWith(worldStandings: standings));
    _persist();
  }

  ({int level, String title, int rep}) getStandingInWorld(String worldId) {
    final r = state.resident;
    if (r == null) return (level: 1, title: 'Visitor', rep: 0);
    final rep = r.worldStandings[worldId]?.rep ?? 0;
    final standing = getStanding(rep);
    return (level: standing.level, title: standing.title, rep: rep);
  }

  void unlockWealthWorld(String worldId) {
    final r = state.resident;
    if (r == null || r.wealthWorldsUnlocked.contains(worldId)) return;
    state = state.copyWith(
      resident: r.copyWith(
        wealthWorldsUnlocked: [...r.wealthWorldsUnlocked, worldId],
      ),
    );
    _persist();
  }

  void muteResident(
    String worldId,
    String residentId, {
    int durationHours = 1,
  }) {
    final r = state.resident;
    if (r == null) return;
    final mutedUntil =
        DateTime.now().millisecondsSinceEpoch + (durationHours * 3600000);
    state = state.copyWith(
      resident: r.copyWith(
        mutedUntil: {...r.mutedUntil, '$worldId:$residentId': mutedUntil},
      ),
    );
    _persist();
    ModerationService.muteUser(
      worldId: worldId,
      moderatorId: r.id,
      targetUserId: residentId,
      durationHours: durationHours,
    );
  }

  void unmuteResident(String worldId, String residentId) {
    final r = state.resident;
    if (r == null) return;
    final updated = Map<String, int>.from(r.mutedUntil);
    updated.remove('$worldId:$residentId');
    state = state.copyWith(resident: r.copyWith(mutedUntil: updated));
    _persist();
    ModerationService.unmuteUser(
      worldId: worldId,
      moderatorId: r.id,
      targetUserId: residentId,
    );
  }

  bool isMutedInWorld(String worldId, String residentId) {
    final r = state.resident;
    if (r == null) return false;
    final until = r.mutedUntil['$worldId:$residentId'] ?? 0;
    return until > DateTime.now().millisecondsSinceEpoch;
  }

  void banResident(String worldId, String residentId, {String? reason}) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(
      resident: r.copyWith(
        bannedWorldIds: [...r.bannedWorldIds, '$worldId:$residentId'],
      ),
    );
    _persist();
    ModerationService.banUser(
      worldId: worldId,
      moderatorId: r.id,
      targetUserId: residentId,
      reason: reason,
    );
    if (residentId == r.id) leaveWorld(worldId);
  }

  void unbanResident(String worldId, String residentId) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(
      resident: r.copyWith(
        bannedWorldIds: r.bannedWorldIds
            .where((id) => id != '$worldId:$residentId')
            .toList(),
      ),
    );
    _persist();
    ModerationService.unbanUser(
      worldId: worldId,
      moderatorId: r.id,
      targetUserId: residentId,
    );
  }

  bool isBannedInWorld(String worldId, String residentId) {
    final r = state.resident;
    if (r == null) return false;
    return r.bannedWorldIds.contains('$worldId:$residentId');
  }

  void checkStreakRisk() {
    final r = state.resident;
    if (r == null || r.streakCount == 0) return;

    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    final yesterday = now
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final dayBeforeYesterday = now
        .subtract(const Duration(days: 2))
        .toIso8601String()
        .substring(0, 10);

    final lastDate = r.lastCheckIn?.substring(0, 10);
    if (lastDate == null || lastDate == today) return;

    if (lastDate == yesterday) {
      final hoursLeft = 23 - now.hour;
      ref
          .read(notificationProvider.notifier)
          .streakExpiringAlert(
            hoursLeft: hoursLeft.clamp(1, 23),
            residentName: r.name,
          );
    } else if (lastDate == dayBeforeYesterday && r.streakShields > 0) {
      final hoursLeft = 23 - now.hour;
      ref
          .read(notificationProvider.notifier)
          .streakExpiringAlert(
            hoursLeft: hoursLeft.clamp(1, 23),
            residentName: r.name,
          );
    }
  }

  Future<void> touchPresence() async {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(
      resident: r.copyWith(lastSeenAt: DateTime.now().millisecondsSinceEpoch),
    );
    _persist();
  }

  void joinWorld(String worldId) {
    final r = state.resident;
    if (r == null || r.joinedWorldIds.contains(worldId)) return;
    if (r.bannedWorldIds.contains('$worldId:${r.id}')) return;

    final worldNotifier = ref.read(worldProvider.notifier);
    final world = ref.read(worldProvider).worlds[worldId];
    if (world != null && world.type == WorldType.dominion) {
      final capacity = worldNotifier.residentCapacityFor(worldId);
      if (world.memberCount >= capacity) return;
    }

    state = state.copyWith(
      resident: r.copyWith(joinedWorldIds: [...r.joinedWorldIds, worldId]),
    );
    _persist();
    _checkWorldJoinMilestones();
    WorldService.joinWorld(worldId, r.id, residentName: r.name);
    worldNotifier.incrementMemberCount(worldId);
    final updatedWorld = ref.read(worldProvider).worlds[worldId];
    worldNotifier.updateWorldPrestige(
      worldId: worldId,
      memberCount: updatedWorld?.memberCount ?? 0,
      memberTiers: {r.id: r.tier.value},
      recentPosts: ref.read(postProvider).posts,
    );
    worldNotifier.addActivityScore(worldId, 10);
  }

  void leaveWorld(String worldId) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(
      resident: r.copyWith(
        joinedWorldIds: r.joinedWorldIds.where((id) => id != worldId).toList(),
      ),
    );
    _persist();
    WorldService.leaveWorld(worldId, r.id);
    ref
        .read(worldProvider.notifier)
        .updateWorldPrestige(
          worldId: worldId,
          memberCount:
              ref.read(worldProvider).worlds[worldId]?.memberCount ?? 0,
          memberTiers: {},
          recentPosts: ref.read(postProvider).posts,
        );
  }

  bool isMemberOf(String worldId) {
    final r = state.resident;
    if (r == null) return false;
    return r.joinedWorldIds.contains(worldId);
  }

  Future<void> verifyProfession(String profession, {String? proofPath}) async {
    final r = state.resident;
    if (r == null) return;

    state = state.copyWith(
      resident: r.copyWith(profession: profession),
      verificationStatus: VerificationStatus.verifying,
    );

    if (proofPath != null) {
      state = state.copyWith(verificationStatus: VerificationStatus.verifying);
      final proofUrl = await VerificationService.uploadProof(proofPath, r.id);
      if (proofUrl != null) {
        await VerificationService.submitVerification(
          residentId: r.id,
          residentName: r.name,
          profession: profession,
          proofUrl: proofUrl,
        );
        state = state.copyWith(verificationStatus: VerificationStatus.idle);
        _persist();
        return;
      }
    }

    state = state.copyWith(verificationStatus: VerificationStatus.verifying);

    final updated = state.resident;
    if (updated == null) {
      state = state.copyWith(verificationStatus: VerificationStatus.idle);
      return;
    }

    final roles = [...updated.verifiedRoles];
    if (!roles.contains(profession)) roles.add(profession);

    final decorations = [...updated.decorations];
    final badgeId = '${profession}_badge';
    if (!decorations.contains(badgeId)) decorations.add(badgeId);

    state = state.copyWith(
      resident: updated.copyWith(
        verifiedRoles: roles,
        decorations: decorations,
      ),
      verificationStatus: VerificationStatus.success,
    );
    _persist();
    Haptics.light();

    const professionToAchievement = {
      'Medical': 'prof-doctor',
      'Aviation': 'prof-pilot',
      'Finance': 'prof-finance',
      'Legal': 'prof-attorney',
      'Engineering': 'prof-engineer',
      'Technology': 'prof-engineer',
      'Arts': 'prof-artist',
    };
    final achievementId = professionToAchievement[profession];
    if (achievementId != null) {
      ref
          .read(achievementProvider.notifier)
          .submitAchievement(achievementId, 'submitted');
    }
  }

  void setVerificationStatus(VerificationStatus status) {
    state = state.copyWith(verificationStatus: status);
  }

  void resetVerification() {
    state = state.copyWith(verificationStatus: VerificationStatus.idle);
  }

  void _checkStreakMilestones(int streak) {
    final notifier = ref.read(achievementProvider.notifier);
    if (streak >= 3) notifier.autoAwardAchievement('streak-3');
    if (streak >= 7) notifier.autoAwardAchievement('week-warrior');
    if (streak >= 14) notifier.autoAwardAchievement('streak-14');
    if (streak >= 30) {
      notifier.autoAwardAchievement('month-master');
      _grantShieldIfNew('shield-30');
    }
    if (streak >= 60) notifier.autoAwardAchievement('streak-60');
    if (streak >= 90) {
      notifier.autoAwardAchievement('season-sage');
      _grantShieldIfNew('shield-90');
    }
    if (streak >= 180) notifier.autoAwardAchievement('streak-180');
    if (streak >= 365) {
      notifier.autoAwardAchievement('streak-365');
      _grantShieldIfNew('shield-365');
    }
  }

  void addStreakShield() {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(
      resident: r.copyWith(streakShields: r.streakShields + 1),
    );
    _persist();
  }

  void addXpFromDailyReward(int xp) {
    if (xp <= 0) return;
    ref.read(achievementProvider.notifier).addDirectXp(xp);
  }

  void _grantShieldIfNew(String shieldId) {
    final r = state.resident;
    if (r == null) return;
    if (r.decorations.contains(shieldId)) return;
    state = state.copyWith(
      resident: r.copyWith(
        streakShields: r.streakShields + 1,
        decorations: [...r.decorations, shieldId],
      ),
    );
    _persist();
  }

  void _checkWorldJoinMilestones() {
    final r = state.resident;
    if (r == null) return;
    final count = r.joinedWorldIds.length;
    final notifier = ref.read(achievementProvider.notifier);
    if (count >= 1) notifier.autoAwardAchievement('explorer');
    if (count >= 3) notifier.autoAwardAchievement('wayfarer');
    if (count >= 5) notifier.autoAwardAchievement('realm-wanderer');
  }

  void setTitle(String? title) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(resident: r.copyWith(title: title));
    _persist();
  }

  bool addDecoration(String decorationId) {
    final r = state.resident;
    if (r == null) return false;
    final updated = [...r.decorations, decorationId];
    state = state.copyWith(resident: r.copyWith(decorations: updated));
    _persist();
    if (state.resident != null) ProfileService.upsertProfile(state.resident!);
    return true;
  }

  bool spendCoins(int amount) {
    final r = state.resident;
    if (r == null || r.sovereignCoins < amount) return false;
    state = state.copyWith(
      resident: r.copyWith(sovereignCoins: r.sovereignCoins - amount),
    );
    _persist();
    if (state.resident != null) ProfileService.upsertProfile(state.resident!);
    return true;
  }

  void _persist() {
    final r = state.resident;
    if (r == null) return;
    StorageService.setString(
      StorageService.residentKey,
      jsonEncode(_toJson(r)),
    );
  }

  static Resident? _fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;

    return Resident(
      id: id,
      name: name,
      tier: ResidentTier.fromValue((json['tier'] as int?) ?? 1),
      bio: (json['bio'] as String?) ?? '',
      avatarUrl: (json['avatarUrl'] as String?) ?? '',
      profession: json['profession'] as String?,
      verifiedRoles:
          _toStringList(json['verifiedRoles']) ??
          _toStringList(json['verifiedProfessions']) ??
          [],
      decorations: _toStringList(json['decorations']) ?? [],
      wealthWorldsUnlocked: _toStringList(json['wealthWorldsUnlocked']) ?? [],
      badges: _toStringList(json['cosmetics']?['badges']) ?? [],
      lastCheckIn: json['lastCheckIn'] as String?,
      streakCount: (json['streakCount'] as int?) ?? 0,
      streakShields: (json['streakShields'] as int?) ?? 0,
      following: _toStringList(json['following']) ?? [],
      joinedWorldIds: _toStringList(json['joinedWorldIds']) ?? [],
      worldStandings: _parseStandings(json['worldStandings']),
      bannedWorldIds: _toStringList(json['bannedWorldIds']) ?? [],
      mutedUntil:
          (json['mutedUntil'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as int?) ?? 0),
          ) ??
          {},
      lastSeenAt: (json['lastSeenAt'] as int?) ?? 0,
      referredBy: json['referredBy'] as String?,
      title: json['title'] as String?,
      sovereignCoins: (json['sovereignCoins'] as int?) ?? 100,
      onboardingCompleted: (json['onboardingCompleted'] as bool?) ?? false,
      gateCompleted: (json['gateCompleted'] as bool?) ?? false,
    );
  }

  static Future<Resident?> _cachedResidentFor(String userId) async {
    final raw = await StorageService.getString(StorageService.residentKey);
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final resident = _fromJson(data);
    if (resident == null || resident.id != userId) return null;
    return resident;
  }

  static Map<String, dynamic> _toJson(Resident r) => {
    'id': r.id,
    'name': r.name,
    'tier': r.tier.value,
    'bio': r.bio,
    'avatarUrl': r.avatarUrl,
    'profession': r.profession,
    'verifiedRoles': r.verifiedRoles,
    'decorations': r.decorations,
    'wealthWorldsUnlocked': r.wealthWorldsUnlocked,
    'cosmetics': {'badges': r.badges},
    'lastCheckIn': r.lastCheckIn,
    'streakCount': r.streakCount,
    'streakShields': r.streakShields,
    'following': r.following,
    'joinedWorldIds': r.joinedWorldIds,
    'worldStandings': r.worldStandings.map(
      (k, v) => MapEntry(k, {'rep': v.rep}),
    ),
    'bannedWorldIds': r.bannedWorldIds,
    'mutedUntil': r.mutedUntil,
    'lastSeenAt': r.lastSeenAt,
    if (r.referredBy != null) 'referredBy': r.referredBy,
    if (r.title != null) 'title': r.title,
    'sovereignCoins': r.sovereignCoins,
    'onboardingCompleted': r.onboardingCompleted,
    'gateCompleted': r.gateCompleted,
  };

  static List<String>? _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }

  static Map<String, WorldStanding> _parseStandings(dynamic value) {
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(
          k.toString(),
          WorldStanding(rep: (v is Map ? (v['rep'] as int?) ?? 0 : 0)),
        ),
      );
    }
    return {};
  }
}

final residentProvider = NotifierProvider<ResidentNotifier, ResidentState>(
  ResidentNotifier.new,
);
