import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../models/resident.dart';
import '../config/achievements.dart' as config;
import '../config/titles.dart';
import '../services/ai_verification_service.dart';
import '../services/supabase.dart';
import '../services/storage_service.dart';
import '../utils/haptics.dart';
import 'resident_provider.dart';

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

class AchievementNotifier extends Notifier<AchievementState> {
  void Function(List<String> verifiedIds, ResidentTier? newTier)?
  onAchievementsVerified;
  int _lastTotalXp = 0;

  @override
  AchievementState build() {
    ref.listen<AchievementState>(achievementProvider, (prev, next) {
      if (next.totalXp > _lastTotalXp) {
        _lastTotalXp = next.totalXp;
        final newTier = config.getTierForXp(next.totalXp);
        ref.read(residentProvider.notifier).updateTier(newTier);
      }
    });

    return const AchievementState();
  }

  Future<void> submitAchievement(String achievementId, String proofUri) async {
    final existing = state.userAchievements
        .where((a) => a.achievementId == achievementId)
        .firstOrNull;
    if (existing != null &&
        (existing.status == AchievementStatus.verified ||
            existing.status == AchievementStatus.submitted)) {
      return;
    }

    final achDef = config.achievements
        .where((a) => a.id == achievementId)
        .firstOrNull;
    final aiResult = await AiVerificationService.analyzeProof(
      proofUrl: proofUri,
      achievementId: achievementId,
      category: achDef?.category.name ?? '',
    );

    final shouldAutoVerify = AiVerificationService.autoVerificationEnabled &&
        aiResult.autoApproved &&
        (aiResult.confidence ?? 0) >= 0.75;
    await _persistCloudSubmission(
      achievementId: achievementId,
      proofUri: proofUri,
      status: shouldAutoVerify
          ? AchievementStatus.verified
          : AchievementStatus.submitted,
    );

    state = state.copyWith(
      userAchievements: [
        ...state.userAchievements,
        UserAchievement(
          achievementId: achievementId,
          status: shouldAutoVerify
              ? AchievementStatus.verified
              : AchievementStatus.submitted,
          proofUri: proofUri,
          submittedAt: DateTime.now().millisecondsSinceEpoch,
          verifiedAt: shouldAutoVerify
              ? DateTime.now().millisecondsSinceEpoch
              : null,
          aiConfidence: aiResult.confidence,
          aiNotes: aiResult.notes,
        ),
      ],
    );
    _persist();

    if (shouldAutoVerify) {
      final oldTier = config.getTierForXp(state.totalXp);
      final newTotalXp = _calculateTotalXp(
        state.userAchievements
            .map(
              (a) => a.achievementId == achievementId
                  ? a.copyWith(
                      status: AchievementStatus.verified,
                      verifiedAt: DateTime.now().millisecondsSinceEpoch,
                      aiConfidence: aiResult.confidence,
                      aiNotes: aiResult.notes,
                    )
                  : a,
            )
            .toList(),
      );
      final newTier = config.getTierForXp(newTotalXp);
      final tierChanged = newTier.value > oldTier.value;

      final newIds = [
        ...state.recentlyUnlockedIds,
        if (!state.recentlyUnlockedIds.contains(achievementId)) achievementId,
      ];

      state = state.copyWith(
        totalXp: newTotalXp,
        recentlyUnlockedIds: newIds,
        celebrationTier: tierChanged ? newTier : state.celebrationTier,
      );
      _persist();

      if (tierChanged) {
        onAchievementsVerified?.call([achievementId], tierChanged ? newTier : null);
      }
      Haptics.success();
    }
  }

  Future<void> _persistCloudSubmission({
    required String achievementId,
    required String proofUri,
    required AchievementStatus status,
  }) async {
    final userId =
        ref.read(residentProvider).resident?.id ??
        maybeSupabase()?.auth.currentUser?.id;
    if (userId == null || userId.isEmpty || !isSupabaseConfigured()) return;
    await getSupabase().from('user_achievements').upsert({
      'user_id': userId,
      'achievement_id': achievementId,
      'status': status == AchievementStatus.verified ? 'verified' : 'submitted',
      'proof_uri': proofUri,
      'submitted_at': DateTime.now().toIso8601String(),
      if (status == AchievementStatus.verified)
        'verified_at': DateTime.now().toIso8601String(),
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

    final oldTier = config.getTierForXp(state.totalXp);

    List<UserAchievement> achievements;
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
          proofUri: 'auto',
          submittedAt: DateTime.now().millisecondsSinceEpoch,
          verifiedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];
    }

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

    final earnedTitle = titleForAchievement(achievementId);
    if (earnedTitle != null) {
      ref.read(residentProvider.notifier).setTitle(earnedTitle);
    }

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
    AchievementStatus.verified => 2,
    AchievementStatus.submitted => 1,
    AchievementStatus.locked => 0,
  };

  static UserAchievement _fromCloudRow(Map<String, dynamic> row) {
    final statusName = row['status'] as String? ?? 'locked';
    return UserAchievement(
      achievementId: row['achievement_id'] as String,
      status: AchievementStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => AchievementStatus.submitted,
      ),
      proofUri: row['proof_uri'] as String?,
      submittedAt: _parseMillis(row['submitted_at']),
      verifiedAt: _parseMillis(row['verified_at']),
      aiConfidence: (row['ai_confidence'] as num?)?.toDouble(),
      aiNotes: row['ai_notes'] as String?,
    );
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
        status: AchievementStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AchievementStatus.locked,
        ),
        proofUri: json['proofUri'] as String?,
        submittedAt: json['submittedAt'] as int?,
        verifiedAt: json['verifiedAt'] as int?,
        aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
        aiNotes: json['aiNotes'] as String?,
      );

  void clearForSignOut() {
    _lastTotalXp = 0;
    state = const AchievementState();
  }

  static Map<String, dynamic> _toJson(UserAchievement a) => {
    'achievementId': a.achievementId,
    'status': a.status.name,
    'proofUri': a.proofUri,
    'submittedAt': a.submittedAt,
    'verifiedAt': a.verifiedAt,
    'aiConfidence': a.aiConfidence,
    'aiNotes': a.aiNotes,
  };
}

final achievementProvider =
    NotifierProvider<AchievementNotifier, AchievementState>(
      AchievementNotifier.new,
    );
