import 'dart:convert';
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
  final int totalXp;
  final List<String> recentlyUnlockedIds;
  final ResidentTier? celebrationTier;

  const AchievementState({
    this.userAchievements = const [],
    this.isLoading = true,
    this.totalXp = 0,
    this.recentlyUnlockedIds = const [],
    this.celebrationTier,
  });

  AchievementState copyWith({
    List<UserAchievement>? userAchievements,
    bool? isLoading,
    int? totalXp,
    List<String>? recentlyUnlockedIds,
    ResidentTier? celebrationTier,
    bool clearCelebration = false,
  }) => AchievementState(
    userAchievements: userAchievements ?? this.userAchievements,
    isLoading: isLoading ?? this.isLoading,
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

  @override
  AchievementState build() => const AchievementState();

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

    final shouldAutoVerify =
        aiResult.autoApproved && aiResult.confidence >= 0.75;
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
        ref.read(residentProvider.notifier).updateTier(newTier);
      }

      onAchievementsVerified?.call([
        achievementId,
      ], tierChanged ? newTier : null);
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

    if (tierChanged) {
      ref.read(residentProvider.notifier).updateTier(newTier);
    }

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

    if (tierChanged) {
      ref.read(residentProvider.notifier).updateTier(newTier);
    }
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
    state = state.copyWith(isLoading: true);
    try {
      final json = await StorageService.getString(
        StorageService.achievementsKey,
      );
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final list = data['userAchievements'] as List? ?? [];
        final achievements = list
            .map((e) => _fromJson(e as Map<String, dynamic>))
            .toList();
        final totalXp = _calculateTotalXp(achievements);
        state = state.copyWith(
          userAchievements: achievements,
          isLoading: false,
          totalXp: totalXp,
        );
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
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
