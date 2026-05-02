import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../config/achievements.dart' as config;
import '../services/storage_service.dart';

class AchievementState {
  final List<UserAchievement> userAchievements;
  final bool isLoading;
  final int totalXp;

  const AchievementState({
    this.userAchievements = const [],
    this.isLoading = true,
    this.totalXp = 0,
  });

  AchievementState copyWith({
    List<UserAchievement>? userAchievements,
    bool? isLoading,
    int? totalXp,
  }) =>
      AchievementState(
        userAchievements: userAchievements ?? this.userAchievements,
        isLoading: isLoading ?? this.isLoading,
        totalXp: totalXp ?? this.totalXp,
      );
}

class AchievementNotifier extends StateNotifier<AchievementState> {
  AchievementNotifier(Ref ref) : super(const AchievementState());

  Future<void> submitAchievement(String achievementId, String proofUri) async {
    final existing = state.userAchievements.where((a) => a.achievementId == achievementId).firstOrNull;
    if (existing != null && (existing.status == AchievementStatus.verified || existing.status == AchievementStatus.submitted)) {
      return;
    }

    state = state.copyWith(
      userAchievements: [
        ...state.userAchievements,
        UserAchievement(
          achievementId: achievementId,
          status: AchievementStatus.submitted,
          proofUri: proofUri,
          submittedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ],
    );
    _persist();
  }

  Future<void> verifyAchievement(String achievementId) async {
    final achievements = state.userAchievements.map((a) {
      if (a.achievementId == achievementId && a.status == AchievementStatus.submitted) {
        return a.copyWith(status: AchievementStatus.verified, verifiedAt: DateTime.now().millisecondsSinceEpoch);
      }
      return a;
    }).toList();

    final newTotalXp = _calculateTotalXp(achievements);

    state = state.copyWith(userAchievements: achievements, totalXp: newTotalXp);
    _persist();

    HapticFeedback.lightImpact();
  }

  AchievementStatus getAchievementStatus(String achievementId) {
    final a = state.userAchievements.where((a) => a.achievementId == achievementId).firstOrNull;
    return a?.status ?? AchievementStatus.locked;
  }

  ({int earned, int total, int xp}) getCategoryProgress(String category) {
    final catAchievements = config.achievements.where((a) => a.category.name == category).toList();
    final verifiedIds = state.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .map((a) => a.achievementId)
        .toSet();

    final earned = catAchievements.where((a) => verifiedIds.contains(a.id)).length;
    final xp = catAchievements.where((a) => verifiedIds.contains(a.id)).fold<int>(0, (sum, a) => sum + a.xpValue);

    return (earned: earned, total: catAchievements.length, xp: xp);
  }

  int calculateTotalXp() => _calculateTotalXp(state.userAchievements);

  Future<void> loadAchievements() async {
    state = state.copyWith(isLoading: true);
    try {
      final json = await StorageService.getString(StorageService.achievementsKey);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final list = data['userAchievements'] as List? ?? [];
        final achievements = list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
        final totalXp = _calculateTotalXp(achievements);
        state = AchievementState(userAchievements: achievements, isLoading: false, totalXp: totalXp);
        return;
      }
    } catch (_) {}
    state = const AchievementState(isLoading: false);
  }

  void _persist() {
    final json = jsonEncode({
      'userAchievements': state.userAchievements.map(_toJson).toList(),
      'totalXp': state.totalXp,
    });
    StorageService.setStringDebounced(StorageService.achievementsKey, json);
  }

  int _calculateTotalXp(List<UserAchievement> achievements) {
    final verifiedIds = achievements.where((a) => a.status == AchievementStatus.verified).map((a) => a.achievementId).toSet();
    return config.achievements.where((a) => verifiedIds.contains(a.id)).fold<int>(0, (sum, a) => sum + a.xpValue);
  }

  static UserAchievement _fromJson(Map<String, dynamic> json) => UserAchievement(
        achievementId: json['achievementId'] as String,
        status: AchievementStatus.values.firstWhere((s) => s.name == json['status'], orElse: () => AchievementStatus.locked),
        proofUri: json['proofUri'] as String?,
        submittedAt: json['submittedAt'] as int?,
        verifiedAt: json['verifiedAt'] as int?,
      );

  static Map<String, dynamic> _toJson(UserAchievement a) => {
        'achievementId': a.achievementId,
        'status': a.status.name,
        'proofUri': a.proofUri,
        'submittedAt': a.submittedAt,
        'verifiedAt': a.verifiedAt,
      };
}

final achievementProvider = StateNotifierProvider<AchievementNotifier, AchievementState>(
  (ref) => AchievementNotifier(ref),
);
