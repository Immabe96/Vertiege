import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/achievements.dart' as config;
import '../config/titles.dart';
import '../models/achievement.dart';
import '../models/resident.dart';
import '../services/gamification_service.dart';
import '../services/profile_achievements_service.dart';
import '../services/supabase.dart';
import '../services/storage_service.dart';
import '../utils/achievement_proof_utils.dart';
import '../utils/haptics.dart';
import 'resident_provider.dart';

part 'achievement_provider.g.dart';

class AchievementState {
  final List<UserAchievement> userAchievements;
  final bool isLoading;
  final String? error;
  final int totalXp;
  final List<String> recentlyUnlockedIds;
  final ResidentTier? celebrationTier;

  const AchievementState({
    this.userAchievements = const [],
    this.isLoading = true,
    this.error,
    this.totalXp = 0,
    this.recentlyUnlockedIds = const [],
    this.celebrationTier,
  });

  AchievementState copyWith({
    List<UserAchievement>? userAchievements,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? totalXp,
    List<String>? recentlyUnlockedIds,
    ResidentTier? celebrationTier,
    bool clearCelebration = false,
  }) => AchievementState(
    userAchievements: userAchievements ?? this.userAchievements,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    totalXp: totalXp ?? this.totalXp,
    recentlyUnlockedIds: recentlyUnlockedIds ?? this.recentlyUnlockedIds,
    celebrationTier: clearCelebration
        ? null
        : (celebrationTier ?? this.celebrationTier),
  );
}

@Riverpod(name: 'achievementProvider', keepAlive: true)
class AchievementNotifier extends _$AchievementNotifier {
  void Function(List<String> verifiedIds, ResidentTier? newTier)?
  onAchievementsVerified;

  @override
  AchievementState build() {
    listenSelf((prev, next) {
      if (next.recentlyUnlockedIds.isNotEmpty &&
          next.recentlyUnlockedIds !=
              (prev?.recentlyUnlockedIds ?? const [])) {
        ref.read(residentProvider.notifier).refreshGamificationFromServer();
      }
    });

    return const AchievementState();
  }

  Future<void> submitAchievement(
    String achievementId,
    List<String> proofUris, {
    String? story,
  }) async {
    final existing = state.userAchievements
        .where((a) => a.achievementId == achievementId)
        .firstOrNull;
    if (existing != null &&
        (existing.status == AchievementStatus.verified ||
            existing.status == AchievementStatus.submitted)) {
      return;
    }

    await _persistCloudSubmission(
      achievementId: achievementId,
      proofUris: proofUris,
      status: AchievementStatus.submitted,
      clearReviewerNotes: existing?.status == AchievementStatus.rejected,
      story: story,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = UserAchievement(
      achievementId: achievementId,
      proofUris: proofUris,
      submittedAt: now,
      isProfileVisible: existing?.isProfileVisible ?? true,
      featuredOrder: existing?.featuredOrder,
    );

    final List<UserAchievement> updated;
    if (existing != null) {
      updated = state.userAchievements
          .map(
            (a) => a.achievementId == achievementId
                ? entry.copyWith()
                : a,
          )
          .toList();
    } else {
      updated = [...state.userAchievements, entry];
    }

    state = state.copyWith(userAchievements: updated);
    _persist();
  }

  Future<void> _persistCloudSubmission({
    required String achievementId,
    required List<String> proofUris,
    required AchievementStatus status,
    bool clearReviewerNotes = false,
    String? story,
  }) async {
    final userId =
        ref.read(residentProvider).resident?.id ??
        maybeSupabase()?.auth.currentUser?.id;
    if (userId == null || userId.isEmpty || !isSupabaseConfigured()) return;
    final primary = proofUris.isEmpty ? 'manual' : proofUris.first;
    await getSupabase().from('user_achievements').upsert({
      'user_id': userId,
      'achievement_id': achievementId,
      'status': status == AchievementStatus.verified ? 'verified' : 'submitted',
      'proof_uri': primary,
      'proof_uris': proofUris,
      'submitted_at': DateTime.now().toIso8601String(),
      if (status == AchievementStatus.verified)
        'verified_at': DateTime.now().toIso8601String(),
      if (clearReviewerNotes) 'ai_notes': null,
      if (story != null && story.trim().isNotEmpty)
        'achievement_story': story.trim().length > 280
            ? story.trim().substring(0, 280)
            : story.trim(),
    }, onConflict: 'user_id,achievement_id');
  }

  Future<void> verifyAchievement(String achievementId) async {
    final oldTier = config.getTierForXp(state.totalXp);

    final achievements = state.userAchievements.map((a) {
      if (a.achievementId == achievementId &&
          a.status == AchievementStatus.submitted) {
        return a.copyWith(
          status: AchievementStatus.verified,
          verifiedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return a;
    }).toList();

    final newTotalXp = _calculateTotalXp(achievements);
    final newTier = config.getTierForXp(newTotalXp);
    final tierChanged = newTier.value > oldTier.value;

    final newIds = [
      ...state.recentlyUnlockedIds,
      if (!state.recentlyUnlockedIds.contains(achievementId)) achievementId,
    ];

    state = state.copyWith(
      userAchievements: achievements,
      totalXp: newTotalXp,
      recentlyUnlockedIds: newIds,
      celebrationTier: tierChanged ? newTier : state.celebrationTier,
    );
    _persist();

    onAchievementsVerified?.call([achievementId], tierChanged ? newTier : null);

    Haptics.success();
  }

  Future<void> autoAwardAchievement(String achievementId) async {
    final existing = state.userAchievements
        .where((a) => a.achievementId == achievementId)
        .firstOrNull;
    if (existing != null && existing.status == AchievementStatus.verified) {
      return;
    }

    final userId =
        ref.read(residentProvider).resident?.id ??
        maybeSupabase()?.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    final oldTier = ref.read(residentProvider).resident?.tier ??
        config.getTierForXp(state.totalXp);

    if (isSupabaseConfigured()) {
      try {
        await GamificationService.grantVerifiedAchievement(
          userId: userId,
          achievementId: achievementId,
        );
        await loadAchievements();
        await ref.read(residentProvider.notifier).refreshGamificationFromServer();
      } catch (e) {
        debugPrint('autoAwardAchievement server grant failed: $e');
        return;
      }
    } else {
      await _applyLocalVerifiedUnlock(achievementId, existing);
      return;
    }

    final refreshed = ref.read(residentProvider).resident;
    final newTier = refreshed?.tier ?? oldTier;
    final tierChanged = newTier.value > oldTier.value;

    final newIds = [
      ...state.recentlyUnlockedIds,
      if (!state.recentlyUnlockedIds.contains(achievementId)) achievementId,
    ];

    if (tierChanged) {
      state = state.copyWith(
        recentlyUnlockedIds: newIds,
        celebrationTier: newTier,
      );
    } else if (newIds.length != state.recentlyUnlockedIds.length) {
      state = state.copyWith(recentlyUnlockedIds: newIds);
    }

    onAchievementsVerified?.call([achievementId], tierChanged ? newTier : null);

    final earnedTitle = titleForAchievement(achievementId);
    if (earnedTitle != null) {
      ref.read(residentProvider.notifier).setTitle(earnedTitle);
    }

    Haptics.success();
  }

  Future<void> _applyLocalVerifiedUnlock(
    String achievementId,
    UserAchievement? existing,
  ) async {
    final oldTier = config.getTierForXp(state.totalXp);
    final List<UserAchievement> achievements;
    if (existing != null) {
      achievements = state.userAchievements.map((a) {
        if (a.achievementId == achievementId) {
          return a.copyWith(
            status: AchievementStatus.verified,
            verifiedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
        return a;
      }).toList();
    } else {
      achievements = [
        ...state.userAchievements,
        UserAchievement(
          achievementId: achievementId,
          status: AchievementStatus.verified,
          proofUris: const ['auto'],
          submittedAt: DateTime.now().millisecondsSinceEpoch,
          verifiedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];
    }
    final newTotalXp = _calculateTotalXp(achievements);
    final newTier = config.getTierForXp(newTotalXp);
    state = state.copyWith(
      userAchievements: achievements,
      totalXp: newTotalXp,
      celebrationTier:
          newTier.value > oldTier.value ? newTier : state.celebrationTier,
    );
    _persist();
    Haptics.success();
  }

  void clearCelebration() {
    state = state.copyWith(recentlyUnlockedIds: [], clearCelebration: true);
  }

  void addDirectXp(int xp) {
    if (xp <= 0) return;
    final oldTier = config.getTierForXp(state.totalXp);
    final newTotalXp = state.totalXp + xp;
    final newTier = config.getTierForXp(newTotalXp);
    final tierChanged = newTier.value > oldTier.value;

    state = state.copyWith(
      totalXp: newTotalXp,
      celebrationTier: tierChanged ? newTier : state.celebrationTier,
    );
    _persist();
  }

  AchievementStatus getAchievementStatus(String achievementId) {
    final a = state.userAchievements
        .where((a) => a.achievementId == achievementId)
        .firstOrNull;
    return a?.status ?? AchievementStatus.locked;
  }

  ({int earned, int total, int xp}) getCategoryProgress(String category) {
    final catAchievements = config.achievements
        .where((a) => a.category.name == category)
        .toList();
    final verifiedIds = state.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .map((a) => a.achievementId)
        .toSet();

    final earned = catAchievements
        .where((a) => verifiedIds.contains(a.id))
        .length;
    final xp = catAchievements
        .where((a) => verifiedIds.contains(a.id))
        .fold<int>(0, (sum, a) => sum + a.xpValue);

    return (earned: earned, total: catAchievements.length, xp: xp);
  }

  int calculateTotalXp() => _calculateTotalXp(state.userAchievements);

  /// After staff approves on the server, pull cloud state and surface unlock UI.
  Future<void> reloadAndCelebrateRemoteVerifications() async {
    final beforeVerified = state.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .map((a) => a.achievementId)
        .toSet();
    final oldTier =
        ref.read(residentProvider).resident?.tier ??
        config.getTierForXp(state.totalXp);

    await loadAchievements();
    await ref.read(residentProvider.notifier).refreshGamificationFromServer();

    final afterVerified = state.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .map((a) => a.achievementId)
        .toSet();
    final newlyVerified = afterVerified.difference(beforeVerified).toList();
    if (newlyVerified.isEmpty) return;

    final refreshed = ref.read(residentProvider).resident;
    final newTier = refreshed?.tier ?? config.getTierForXp(state.totalXp);
    final tierChanged = newTier.value > oldTier.value;

    final newIds = [
      ...state.recentlyUnlockedIds,
      ...newlyVerified.where((id) => !state.recentlyUnlockedIds.contains(id)),
    ];

    state = state.copyWith(
      recentlyUnlockedIds: newIds,
      celebrationTier: tierChanged ? newTier : state.celebrationTier,
    );

    onAchievementsVerified?.call(
      newlyVerified,
      tierChanged ? newTier : null,
    );
    Haptics.success();
  }

  Future<void> loadAchievements() async {
    state = state.copyWith(isLoading: true, clearError: true);
    var achievements = <UserAchievement>[];
    var localFailed = false;
    var cloudFailed = false;

    try {
      final json = await StorageService.getString(
        StorageService.achievementsKey,
      );
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final list = data['userAchievements'] as List? ?? [];
        achievements = list
            .map((e) => _fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      localFailed = true;
      debugPrint('loadAchievements local cache failed: $e');
    }

    try {
      final userId =
          ref.read(residentProvider).resident?.id ??
          maybeSupabase()?.auth.currentUser?.id;
      if (userId != null && isSupabaseConfigured()) {
        final rows = await getSupabase()
            .from('user_achievements')
            .select()
            .eq('user_id', userId);
        achievements = _mergeWithCloud(
          achievements,
          List<Map<String, dynamic>>.from(rows),
        );
      }
    } catch (e) {
      cloudFailed = true;
      debugPrint('loadAchievements cloud sync failed: $e');
    }

    final totalXp = _calculateTotalXp(achievements);
    String? loadError;
    if (achievements.isEmpty && (localFailed || cloudFailed)) {
      loadError = cloudFailed
          ? 'Could not sync achievements. Showing offline data when available.'
          : 'Could not load achievements.';
    } else if (cloudFailed && achievements.isNotEmpty) {
      loadError = 'Using cached achievements (sync failed).';
    }

    state = state.copyWith(
      userAchievements: achievements,
      isLoading: false,
      totalXp: totalXp,
      error: loadError,
    );
    _persist();
  }

  List<UserAchievement> _mergeWithCloud(
    List<UserAchievement> local,
    List<Map<String, dynamic>> rows,
  ) {
    final byId = {for (final a in local) a.achievementId: a};
    for (final row in rows) {
      final cloud = _fromCloudRow(row);
      final existing = byId[cloud.achievementId];
      if (existing == null || _statusRank(cloud.status) >= _statusRank(existing.status)) {
        byId[cloud.achievementId] = cloud;
      }
    }
    return byId.values.toList();
  }

  int _statusRank(AchievementStatus status) => switch (status) {
    AchievementStatus.verified => 3,
    AchievementStatus.submitted => 2,
    AchievementStatus.rejected => 1,
    AchievementStatus.locked => 0,
  };

  static AchievementStatus _statusFromName(String? statusName) {
    return switch (statusName) {
      'verified' => AchievementStatus.verified,
      'submitted' => AchievementStatus.submitted,
      'rejected' => AchievementStatus.rejected,
      'locked' => AchievementStatus.locked,
      _ => AchievementStatus.locked,
    };
  }

  static UserAchievement _fromCloudRow(Map<String, dynamic> row) {
    final statusName = row['status'] as String? ?? 'locked';
    return UserAchievement(
      achievementId: row['achievement_id'] as String,
      status: _statusFromName(statusName),
      proofUris: parseProofUris(
        proofUri: row['proof_uri'] as String?,
        proofUrisRaw: row['proof_uris'],
      ),
      submittedAt: _parseMillis(row['submitted_at']),
      verifiedAt: _parseMillis(row['verified_at']),
      aiConfidence: (row['ai_confidence'] as num?)?.toDouble(),
      aiNotes: row['ai_notes'] as String?,
      isProfileVisible: row['is_profile_visible'] as bool? ?? true,
      featuredOrder: (row['featured_order'] as num?)?.toInt(),
    );
  }

  Future<void> setAchievementProfileVisibility({
    required String achievementId,
    required bool visible,
    int? featuredOrder,
    bool clearFeatured = false,
  }) async {
    await ProfileAchievementsService.setProfileVisibility(
      achievementId: achievementId,
      visible: visible,
      featuredOrder: featuredOrder,
      clearFeaturedOrder: clearFeatured,
    );
    final updated = state.userAchievements.map((a) {
      if (a.achievementId != achievementId) return a;
      return a.copyWith(
        isProfileVisible: visible,
        featuredOrder: featuredOrder,
        clearFeaturedOrder: clearFeatured,
      );
    }).toList();
    state = state.copyWith(userAchievements: updated);
    _persist();
  }

  static int? _parseMillis(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch;
    }
    return null;
  }

  void _persist() {
    final json = jsonEncode({
      'userAchievements': state.userAchievements.map(_toJson).toList(),
      'totalXp': state.totalXp,
    });
    StorageService.setStringDebounced(StorageService.achievementsKey, json);
  }

  int _calculateTotalXp(List<UserAchievement> achievements) {
    final verifiedIds = achievements
        .where((a) => a.status == AchievementStatus.verified)
        .map((a) => a.achievementId)
        .toSet();
    return config.achievements
        .where((a) => verifiedIds.contains(a.id))
        .fold<int>(0, (sum, a) => sum + a.xpValue);
  }

  static UserAchievement _fromJson(Map<String, dynamic> json) =>
      UserAchievement(
        achievementId: json['achievementId'] as String,
        status: _statusFromName(json['status'] as String?),
        proofUris: _proofUrisFromJson(json['proofUris'] ?? json['proofUri']),
        isProfileVisible: json['isProfileVisible'] as bool? ?? true,
        featuredOrder: json['featuredOrder'] as int?,
        submittedAt: json['submittedAt'] as int?,
        verifiedAt: json['verifiedAt'] as int?,
        aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
        aiNotes: json['aiNotes'] as String?,
      );

  void clearForSignOut() {
    state = const AchievementState();
  }

  static List<String> _proofUrisFromJson(dynamic raw) {
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    if (raw is String && raw.isNotEmpty && raw != 'manual') {
      return [raw];
    }
    return const [];
  }

  static Map<String, dynamic> _toJson(UserAchievement a) => {
    'achievementId': a.achievementId,
    'status': a.status.name,
    'proofUris': a.proofUris,
    'isProfileVisible': a.isProfileVisible,
    if (a.featuredOrder != null) 'featuredOrder': a.featuredOrder,
    if (a.proofUri != null) 'proofUri': a.proofUri,
    'submittedAt': a.submittedAt,
    'verifiedAt': a.verifiedAt,
    'aiConfidence': a.aiConfidence,
    'aiNotes': a.aiNotes,
  };
}


