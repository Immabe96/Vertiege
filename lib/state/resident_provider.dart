import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resident.dart';
import '../models/world.dart';
import '../models/notification.dart';
import '../config/tiers.dart';
import '../services/media_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../services/world_service.dart';
import '../services/moderation_service.dart';
import '../services/verification_service.dart';
import '../services/supabase.dart';
import '../repositories/world_repository.dart';
import '../utils/haptics.dart';
import 'achievement_provider.dart';
import 'world_provider.dart';
import 'post_provider.dart';
import 'notification_provider.dart';
import 'league_provider.dart';

class ResidentState {
  final Resident? resident;
  final bool isLoading;
  final VerificationStatus verificationStatus;

  const ResidentState({
    this.resident,
    this.isLoading = true,
    this.verificationStatus = VerificationStatus.idle,
  });

  static const Object _unset = Object();

  ResidentState copyWith({
    Object? resident = _unset,
    bool? isLoading,
    VerificationStatus? verificationStatus,
  }) => ResidentState(
    resident: identical(resident, _unset)
        ? this.resident
        : resident as Resident?,
    isLoading: isLoading ?? this.isLoading,
    verificationStatus: verificationStatus ?? this.verificationStatus,
  );
}

class ResidentNotifier extends Notifier<ResidentState> {
  final WorldRepository _worldRepository = const WorldRepository();

  int _lastStreakCount = 0;
  int _lastJoinedWorldsCount = 0;
  double _cachedWorldPrestigeBonus = 0.0;

  @override
  ResidentState build() {
    ref.listen<ResidentState>(residentProvider, (prev, next) {
      final r = next.resident;
      if (r == null) return;

      if (r.streakCount > _lastStreakCount) {
        _lastStreakCount = r.streakCount;
        _checkStreakMilestones(r.streakCount);
      }

      if (r.joinedWorldIds.length > _lastJoinedWorldsCount) {
        _lastJoinedWorldsCount = r.joinedWorldIds.length;
        _checkWorldJoinMilestones();
      }
    });

    return const ResidentState();
  }

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
        final mergedWorldIds = {
          ...remote.joinedWorldIds,
          ...?cached?.joinedWorldIds,
        }.toList();
        final resident = remote.copyWith(joinedWorldIds: mergedWorldIds);
        state = ResidentState(resident: resident, isLoading: false);
        _persist(); // cache locally
        unawaited(_worldRepository.replayOutbox());
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

    await _worldRepository.saveProfileMembership(durableResident);
    for (final worldId in durableResident.joinedWorldIds) {
      await _worldRepository.joinWorld(
        worldId: worldId,
        residentId: durableResident.id,
        residentName: durableResident.name,
      );
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
    if (name != null) {
      final trimmed = name.trim();
      if (trimmed.isEmpty || trimmed.length > 100) return;
      if (!RegExp(r'^[a-zA-Z0-9 _-]+$').hasMatch(trimmed)) return;
      name = trimmed;
    }
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
      _saveResidentProfile(
        state.resident!,
      ).catchError((e) => debugPrint('Failed to save profile: $e'));
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

  bool get hasLoungeAccess =>
      state.resident?.tier != null && state.resident!.tier.value >= 3;

  bool get hasGovernanceVote =>
      state.resident?.tier != null && state.resident!.tier.value >= 4;

  int get customReactionSlots => switch (state.resident?.tier.value) {
    null => 0,
    1 => 0,
    2 => 3,
    3 => 5,
    4 => 10,
    5 => 999,
    _ => 0,
  };

  int get postPinLimit => switch (state.resident?.tier.value) {
    null => 0,
    1 => 0,
    2 => 1,
    3 => 3,
    4 => 5,
    5 => 10,
    _ => 0,
  };

  int get worldCreationLimit => switch (state.resident?.tier.value) {
    null => 1,
    1 => 1,
    2 => 2,
    3 => 1,
    4 => 3,
    5 => 999,
    _ => 1,
  };

  double get xpMultiplier => switch (state.resident?.tier.value) {
    null => 1.0,
    1 => 1.0,
    2 => 1.1,
    3 => 1.25,
    4 => 1.5,
    5 => 2.0,
    _ => 1.0,
  };

  Future<double> _calculateWorldPrestigeBonus() async {
    final r = state.resident;
    if (r == null) return 0.0;
    try {
      final highPrestigeWorlds = await WorldService.getHighPrestigeWorlds(r.id);
      final count = highPrestigeWorlds.length;
      final cappedCount = count.clamp(0, 5);
      _cachedWorldPrestigeBonus = (cappedCount * 0.05).clamp(0.0, 0.25);
    } catch (_) {
      _cachedWorldPrestigeBonus = 0.0;
    }
    return _cachedWorldPrestigeBonus;
  }

  double get worldPrestigeBonus => _cachedWorldPrestigeBonus;

  int get dailyCoinBonus => switch (state.resident?.tier.value) {
    null => 0,
    1 => 0,
    2 => 5,
    3 => 15,
    4 => 30,
    5 => 50,
    _ => 0,
  };

  Future<int> awardActivityXp(String actionType, int baseXp) async {
    final r = state.resident;
    if (r == null) return 0;

    final client = maybeSupabase();
    if (client == null) return baseXp;

    try {
      final worldBonus = await _calculateWorldPrestigeBonus();
      final totalMultiplier =
          xpMultiplier * (1.0 + worldBonus) * r.referralXpMultiplier;
      final adjustedXp = (baseXp * totalMultiplier).round();

      final response = await client.rpc(
        'award_activity_xp',
        params: {
          'p_user_id': r.id,
          'p_action_type': actionType,
          'p_base_xp': adjustedXp,
        },
      );
      final actualXp = (response is int) ? response : adjustedXp;

      final newTotalXp = r.totalXp + actualXp;
      final newTier = ResidentTier.fromXp(newTotalXp);

      state = state.copyWith(
        resident: r.copyWith(
          totalXp: newTotalXp,
          lastActivityAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      _persist();

      ref.read(leagueProvider.notifier).trackXP(actualXp);

      if (newTier.value > r.tier.value) {
        await _performTierUpgrade(r, newTier);
      }

      return actualXp;
    } catch (_) {
      final newTotalXp = r.totalXp + baseXp;
      state = state.copyWith(
        resident: r.copyWith(
          totalXp: newTotalXp,
          lastActivityAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      _persist();
      return baseXp;
    }
  }

  Future<int> awardActivityXpForUser(
    String userId,
    String actionType,
    int baseXp,
  ) async {
    final client = maybeSupabase();
    if (client == null) return 0;

    try {
      final response = await client.rpc(
        'award_activity_xp',
        params: {
          'p_user_id': userId,
          'p_action_type': actionType,
          'p_base_xp': baseXp,
        },
      );
      final actualXp = (response is int) ? response : baseXp;

      final r = state.resident;
      if (r != null && r.id == userId) {
        final newTotalXp = r.totalXp + actualXp;
        final newTier = ResidentTier.fromXp(newTotalXp);

        state = state.copyWith(
          resident: r.copyWith(
            totalXp: newTotalXp,
            lastActivityAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        _persist();

        if (newTier.value > r.tier.value) {
          await _performTierUpgrade(r, newTier);
        }
      }

      return actualXp;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _performTierUpgrade(
    Resident oldResident,
    ResidentTier newTier,
  ) async {
    state = state.copyWith(resident: oldResident.copyWith(tier: newTier));
    _persist();

    ref
        .read(notificationProvider.notifier)
        .addNotification(
          type: NotificationType.tierUpgrade,
          message:
              'Congratulations! You\'ve ascended to ${newTier.label} tier!',
        );

    Haptics.heavy();

    ref
        .read(postProvider.notifier)
        .addPost(
          worldId: 'neon-district',
          residentId: oldResident.id,
          residentName: oldResident.name,
          residentAvatar: oldResident.avatarUrl,
          content:
              'Just ascended to ${newTier.label} tier! ${oldResident.tier.label} -> ${newTier.label}',
          tierValue: newTier.value,
          isAnnouncement: true,
        );
  }

  Future<void> checkTierUpgrade() async {
    final r = state.resident;
    if (r == null) return;

    final expectedTier = ResidentTier.fromXp(r.totalXp);
    if (expectedTier.value > r.tier.value) {
      await _performTierUpgrade(r, expectedTier);
    }
  }

  void addRep(String worldId, int amount) {
    final r = state.resident;
    if (r == null) return;
    final standings = Map<String, WorldStanding>.from(r.worldStandings);
    final current = standings[worldId]?.rep ?? 0;
    final newRep = current + amount;
    standings[worldId] = WorldStanding(rep: newRep);
    state = state.copyWith(resident: r.copyWith(worldStandings: standings));
    _persist();

    if (newRep >= 5000 && current < 5000) {
      _awardRepMilestoneXp(worldId, newRep);
    }
  }

  Future<void> _awardRepMilestoneXp(String worldId, int newRep) async {
    final r = state.resident;
    if (r == null) return;

    final client = maybeSupabase();
    if (client == null) return;

    try {
      await client.rpc(
        'award_rep_milestone_xp',
        params: {'p_user_id': r.id, 'p_world_id': worldId, 'p_new_rep': newRep},
      );

      const councilBonusXp = 500;
      final newTotalXp = r.totalXp + councilBonusXp;
      final newTier = ResidentTier.fromXp(newTotalXp);

      state = state.copyWith(resident: r.copyWith(totalXp: newTotalXp));
      _persist();

      if (newTier.value > r.tier.value) {
        await _performTierUpgrade(r, newTier);
      }

      ref
          .read(notificationProvider.notifier)
          .addNotification(
            type: NotificationType.welcome,
            message: 'Council milestone reached! +$councilBonusXp XP awarded.',
          );
    } catch (_) {}
  }

  Future<void> awardReferralXp(String referrerUserId) async {
    final client = maybeSupabase();
    if (client == null) return;

    final r = state.resident;
    if (r == null || r.id != referrerUserId) return;

    const referralBonusXp = 200;
    final newSuccessfulReferrals = r.successfulReferrals + 1;
    final newReferralMultiplier = (1.0 + (newSuccessfulReferrals * 0.05)).clamp(
      1.0,
      1.5,
    );
    final newTotalXp = r.totalXp + referralBonusXp;
    final newTier = ResidentTier.fromXp(newTotalXp);

    state = state.copyWith(
      resident: r.copyWith(
        totalXp: newTotalXp,
        successfulReferrals: newSuccessfulReferrals,
        referralXpMultiplier: newReferralMultiplier,
      ),
    );
    _persist();

    try {
      await client
          .from('profiles')
          .update({
            'total_xp': newTotalXp,
            'successful_referrals': newSuccessfulReferrals,
            'referral_xp_multiplier': newReferralMultiplier,
          })
          .eq('id', referrerUserId);
    } catch (_) {}

    if (newTier.value > r.tier.value) {
      await _performTierUpgrade(r, newTier);
    }

    ref
        .read(notificationProvider.notifier)
        .addNotification(
          type: NotificationType.welcome,
          message: 'Referral bonus! +$referralBonusXp XP awarded.',
        );
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

  Future<void> joinWorld(String worldId) async {
    final r = state.resident;
    if (r == null || r.joinedWorldIds.contains(worldId)) return;
    if (r.bannedWorldIds.contains('$worldId:${r.id}')) return;

    final worldNotifier = ref.read(worldProvider.notifier);
    final world = ref.read(worldProvider).worlds[worldId];
    if (world != null && world.type == WorldType.dominion) {
      final capacity = worldNotifier.residentCapacityFor(worldId);
      if (world.memberCount >= capacity) return;
    }

    final updatedResident = r.copyWith(
      joinedWorldIds: [...r.joinedWorldIds, worldId],
    );
    state = state.copyWith(resident: updatedResident);
    _persist();

    await _worldRepository.joinWorld(
      worldId: worldId,
      residentId: r.id,
      residentName: r.name,
    );
    await _worldRepository.saveProfileMembership(updatedResident);

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
    unawaited(_worldRepository.leaveWorld(worldId: worldId, residentId: r.id));
    ref.read(worldProvider.notifier).decrementMemberCount(worldId);
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

  bool get canAscend =>
      state.resident != null &&
      state.resident!.tier.value >= 5 &&
      state.resident!.prestigeStars == 0;

  Future<bool> ascendToPrestige() async {
    final r = state.resident;
    if (r == null || r.totalXp < 50000 || r.tier.value < 5) return false;

    final newStars = r.prestigeStars + 1;
    final prestigeFrameId = 'prestige_$newStars';

    state = state.copyWith(
      resident: r.copyWith(
        totalXp: 0,
        prestigeStars: newStars,
        avatarFrameId: prestigeFrameId,
        tier: ResidentTier.hustlers,
      ),
    );
    _persist();

    ref
        .read(notificationProvider.notifier)
        .addNotification(
          type: NotificationType.tierUpgrade,
          message: 'Ascended to Prestige $newStars! Your journey begins anew.',
        );

    Haptics.heavy();

    ref
        .read(postProvider.notifier)
        .addPost(
          worldId: 'neon-district',
          residentId: r.id,
          residentName: r.name,
          residentAvatar: r.avatarUrl,
          content:
              'Just ascended to Prestige $newStars! ${prestigeFrameId.toUpperCase()} frame unlocked.',
          tierValue: 5,
          isAnnouncement: true,
        );

    return true;
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
      avatarFrameId: json['avatarFrameId'] as String?,
      totalXp: (json['totalXp'] as int?) ?? 0,
      prestigeLevel: (json['prestigeLevel'] as int?) ?? 0,
      prestigeStars: (json['prestigeStars'] as int?) ?? 0,
      referralXpMultiplier:
          (json['referralXpMultiplier'] as num?)?.toDouble() ?? 1.0,
      successfulReferrals: (json['successfulReferrals'] as int?) ?? 0,
      xpMultiplier: (json['xpMultiplier'] as num?)?.toDouble() ?? 1.0,
      dailyCoinBonus: (json['dailyCoinBonus'] as int?) ?? 0,
      customReactionSlots: (json['customReactionSlots'] as int?) ?? 0,
      postPinLimit: (json['postPinLimit'] as int?) ?? 0,
      worldCreationLimit: (json['worldCreationLimit'] as int?) ?? 1,
      lastActivityAt: (json['lastActivityAt'] as int?) ?? 0,
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
    if (r.avatarFrameId != null) 'avatarFrameId': r.avatarFrameId,
    'totalXp': r.totalXp,
    'prestigeLevel': r.prestigeLevel,
    'prestigeStars': r.prestigeStars,
    'referralXpMultiplier': r.referralXpMultiplier,
    'successfulReferrals': r.successfulReferrals,
    'xpMultiplier': r.xpMultiplier,
    'dailyCoinBonus': r.dailyCoinBonus,
    'customReactionSlots': r.customReactionSlots,
    'postPinLimit': r.postPinLimit,
    'worldCreationLimit': r.worldCreationLimit,
    'lastActivityAt': r.lastActivityAt,
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
