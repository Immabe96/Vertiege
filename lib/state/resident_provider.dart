import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../models/resident.dart';
import '../config/tiers.dart';
import '../services/storage_service.dart';
import '../services/world_service.dart';
import 'achievement_provider.dart';

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
  }) =>
      ResidentState(
        resident: resident ?? this.resident,
        isLoading: isLoading ?? this.isLoading,
        verificationStatus: verificationStatus ?? this.verificationStatus,
      );
}

class ResidentNotifier extends StateNotifier<ResidentState> {
  final Ref _ref;

  ResidentNotifier(this._ref) : super(const ResidentState());

  Future<void> loadResident() async {
    state = state.copyWith(isLoading: true);
    try {
      final json = await StorageService.getString(StorageService.residentKey);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final resident = _fromJson(data);
        if (resident != null) {
          state = ResidentState(resident: resident, isLoading: false);
          return;
        }
      }
      state = const ResidentState(isLoading: false);
    } catch (_) {
      state = const ResidentState(isLoading: false);
    }
  }

  void setResident(Resident resident) {
    state = state.copyWith(resident: resident);
    _persist();
  }

  void updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
    String? profession,
  }) {
    final r = state.resident;
    if (r == null) return;
    if (name != null && (name.isEmpty || name.length > 100)) return;
    if (bio != null && bio.length > 500) return;

    state = state.copyWith(
      resident: r.copyWith(
        name: name ?? r.name,
        bio: bio ?? r.bio,
        avatarUrl: avatarUrl ?? r.avatarUrl,
        profession: profession ?? r.profession,
      ),
    );
    _persist();
  }

  void updateTier(ResidentTier tier) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(resident: r.copyWith(tier: tier));
    _persist();
  }

  ({int streak, int bonusXp})? checkInToday() {
    final r = state.resident;
    if (r == null) return null;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

    if (r.lastCheckIn == today) return null;

    final streak = r.lastCheckIn == null
        ? 1
        : r.lastCheckIn == yesterday
            ? r.streakCount + 1
            : 1;

    final bonusXp = streak >= 30 ? 15 : streak >= 7 ? 10 : streak >= 3 ? 5 : 2;

    state = state.copyWith(
      resident: r.copyWith(lastCheckIn: today, streakCount: streak),
    );
    _persist();
    return (streak: streak, bonusXp: bonusXp);
  }

  void follow(String residentId) {
    final r = state.resident;
    if (r == null || r.following.contains(residentId)) return;
    state = state.copyWith(resident: r.copyWith(following: [...r.following, residentId]));
    _persist();
  }

  void unfollow(String residentId) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(resident: r.copyWith(following: r.following.where((id) => id != residentId).toList()));
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
      resident: r.copyWith(wealthWorldsUnlocked: [...r.wealthWorldsUnlocked, worldId]),
    );
    _persist();
  }

  void muteResident(String worldId, String residentId, int durationHours) {
    final r = state.resident;
    if (r == null) return;
    final mutedUntil = DateTime.now().millisecondsSinceEpoch + (durationHours * 3600000);
    state = state.copyWith(
      resident: r.copyWith(mutedUntil: {...r.mutedUntil, '$worldId:$residentId': mutedUntil}),
    );
    _persist();
  }

  void unmuteResident(String worldId, String residentId) {
    final r = state.resident;
    if (r == null) return;
    final updated = Map<String, int>.from(r.mutedUntil);
    updated.remove('$worldId:$residentId');
    state = state.copyWith(resident: r.copyWith(mutedUntil: updated));
    _persist();
  }

  bool isMutedInWorld(String worldId, String residentId) {
    final r = state.resident;
    if (r == null) return false;
    final until = r.mutedUntil['$worldId:$residentId'] ?? 0;
    return until > DateTime.now().millisecondsSinceEpoch;
  }

  void banResident(String worldId, String residentId) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(
      resident: r.copyWith(bannedWorldIds: [...r.bannedWorldIds, '$worldId:$residentId']),
    );
    _persist();
    if (residentId == r.id) leaveWorld(worldId);
  }

  void unbanResident(String worldId, String residentId) {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(
      resident: r.copyWith(
        bannedWorldIds: r.bannedWorldIds.where((id) => id != '$worldId:$residentId').toList(),
      ),
    );
    _persist();
  }

  bool isBannedInWorld(String worldId, String residentId) {
    final r = state.resident;
    if (r == null) return false;
    return r.bannedWorldIds.contains('$worldId:$residentId');
  }

  void touchPresence() {
    final r = state.resident;
    if (r == null) return;
    state = state.copyWith(resident: r.copyWith(lastSeenAt: DateTime.now().millisecondsSinceEpoch));
    _persist();
  }

  void joinWorld(String worldId) {
    final r = state.resident;
    if (r == null || r.joinedWorldIds.contains(worldId)) return;
    state = state.copyWith(
      resident: r.copyWith(joinedWorldIds: [...r.joinedWorldIds, worldId]),
    );
    _persist();
    WorldService.joinWorld(worldId, r.id);
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
  }

  bool isMemberOf(String worldId) {
    final r = state.resident;
    if (r == null) return false;
    return r.joinedWorldIds.contains(worldId);
  }

  void verifyProfession(String profession) {
    state = state.copyWith(verificationStatus: VerificationStatus.verifying);
    Future.delayed(const Duration(seconds: 2), () {
      final r = state.resident;
      if (r == null) {
        state = state.copyWith(verificationStatus: VerificationStatus.idle);
        return;
      }

      final roles = [...r.verifiedRoles];
      if (!roles.contains(profession)) roles.add(profession);

      final decorations = [...r.decorations];
      final badgeId = '${profession}_badge';
      if (!decorations.contains(badgeId)) decorations.add(badgeId);

      state = state.copyWith(
        resident: r.copyWith(
          profession: profession,
          verifiedRoles: roles,
          decorations: decorations,
        ),
        verificationStatus: VerificationStatus.success,
      );
      _persist();
      HapticFeedback.lightImpact();

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
        _ref.read(achievementProvider.notifier).submitAchievement(achievementId, 'submitted');
      }
    });
  }

  void setVerificationStatus(VerificationStatus status) {
    state = state.copyWith(verificationStatus: status);
  }

  void resetVerification() {
    state = state.copyWith(verificationStatus: VerificationStatus.idle);
  }

  void _persist() {
    final r = state.resident;
    if (r == null) return;
    StorageService.setStringDebounced(StorageService.residentKey, jsonEncode(_toJson(r)));
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
      avatarUrl: (json['avatarUrl'] as String?) ?? 'https://via.placeholder.com/150',
      profession: json['profession'] as String?,
      verifiedRoles: _toStringList(json['verifiedRoles']) ?? _toStringList(json['verifiedProfessions']) ?? [],
      decorations: _toStringList(json['decorations']) ?? [],
      wealthWorldsUnlocked: _toStringList(json['wealthWorldsUnlocked']) ?? [],
      badges: _toStringList(json['cosmetics']?['badges']) ?? [],
      lastCheckIn: json['lastCheckIn'] as String?,
      streakCount: (json['streakCount'] as int?) ?? 0,
      following: _toStringList(json['following']) ?? [],
      joinedWorldIds: _toStringList(json['joinedWorldIds']) ?? [],
      worldStandings: _parseStandings(json['worldStandings']),
      bannedWorldIds: _toStringList(json['bannedWorldIds']) ?? [],
      mutedUntil: (json['mutedUntil'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as int?) ?? 0)) ?? {},
      lastSeenAt: (json['lastSeenAt'] as int?) ?? 0,
    );
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
        'following': r.following,
        'joinedWorldIds': r.joinedWorldIds,
        'worldStandings': r.worldStandings.map((k, v) => MapEntry(k, {'rep': v.rep})),
        'bannedWorldIds': r.bannedWorldIds,
        'mutedUntil': r.mutedUntil,
        'lastSeenAt': r.lastSeenAt,
      };

  static List<String>? _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }

  static Map<String, WorldStanding> _parseStandings(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), WorldStanding(rep: (v is Map ? (v['rep'] as int?) ?? 0 : 0))));
    }
    return {};
  }
}

final residentProvider = StateNotifierProvider<ResidentNotifier, ResidentState>(
  (ref) => ResidentNotifier(ref),
);
