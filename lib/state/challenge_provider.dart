import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/challenge_service.dart';
import 'resident_provider.dart';

class ChallengeData {
  final String id;
  final String title;
  final String description;
  final String type;
  final int targetValue;
  final int xpReward;
  final String? cosmeticReward;
  final int sortOrder;

  const ChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.xpReward,
    this.cosmeticReward,
    this.sortOrder = 0,
  });

  factory ChallengeData.fromMap(Map<String, dynamic> map) {
    return ChallengeData(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? '',
      targetValue: (map['target_value'] as int?) ?? 0,
      xpReward: (map['xp_reward'] as int?) ?? 0,
      cosmeticReward: map['cosmetic_reward'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}

class ChallengeProgressData {
  final String challengeId;
  final int currentValue;
  final bool completed;

  const ChallengeProgressData({
    required this.challengeId,
    required this.currentValue,
    required this.completed,
  });

  factory ChallengeProgressData.fromMap(Map<String, dynamic> map) {
    return ChallengeProgressData(
      challengeId: map['challenge_id'] as String? ?? '',
      currentValue: (map['current_value'] as int?) ?? 0,
      completed: (map['completed'] as bool?) ?? false,
    );
  }
}

class ChallengeState {
  final List<ChallengeData> activeChallenges;
  final Map<String, ChallengeProgressData> userProgress;
  final bool isLoading;
  final List<String> completedChallengeIds;

  const ChallengeState({
    this.activeChallenges = const [],
    this.userProgress = const {},
    this.isLoading = false,
    this.completedChallengeIds = const [],
  });

  ChallengeState copyWith({
    List<ChallengeData>? activeChallenges,
    Map<String, ChallengeProgressData>? userProgress,
    bool? isLoading,
    List<String>? completedChallengeIds,
  }) {
    return ChallengeState(
      activeChallenges: activeChallenges ?? this.activeChallenges,
      userProgress: userProgress ?? this.userProgress,
      isLoading: isLoading ?? this.isLoading,
      completedChallengeIds: completedChallengeIds ?? this.completedChallengeIds,
    );
  }
}

class ChallengeNotifier extends Notifier<ChallengeState> {
  @override
  ChallengeState build() {
    return const ChallengeState();
  }

  Future<void> loadChallengesForWorld(String worldId) async {
    state = state.copyWith(isLoading: true);
    try {
      final challenges = await ChallengeService.getChallenges(
        worldId,
        activeOnly: true,
      );
      final residentId = ref.read(residentProvider).resident?.id;

      Map<String, ChallengeProgressData> progress = {};
      if (residentId != null) {
        for (final c in challenges) {
          progress[c.id] = ChallengeProgressData(
            challengeId: c.id,
            currentValue: c.currentValue,
            completed: c.isCompleted,
          );
        }
      }

      final challengeData = challenges
          .map((c) => ChallengeData.fromMap({
            'id': c.id,
            'title': c.title,
            'description': c.description,
            'type': c.challengeType,
            'targetValue': c.targetValue,
            'xpReward': c.rewardXp,
            'sortOrder': 0,
          }))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final completedIds = progress.entries
          .where((e) => e.value.completed)
          .map((e) => e.key)
          .toList();

      state = state.copyWith(
        activeChallenges: challengeData,
        userProgress: progress,
        isLoading: false,
        completedChallengeIds: completedIds,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> trackEvent(String eventType) async {
    final residentId = ref.read(residentProvider).resident?.id;
    if (residentId == null) return;

    for (final challenge in state.activeChallenges) {
      if (challenge.type != eventType) {
        continue;
      }
      final progress = state.userProgress[challenge.id];
      if (progress != null && progress.completed) continue;

      await ChallengeService.updateProgress(challenge.id, 1);

      final newCurrentValue = (progress?.currentValue ?? 0) + 1;
      final newProgress = ChallengeProgressData(
        challengeId: challenge.id,
        currentValue: newCurrentValue,
        completed: false,
      );
      final updatedProgress = Map<String, ChallengeProgressData>.from(
        state.userProgress,
      )..[challenge.id] = newProgress;

      state = state.copyWith(userProgress: updatedProgress);

      if (newCurrentValue >= challenge.targetValue) {
        final completedProgress = ChallengeProgressData(
          challengeId: challenge.id,
          currentValue: newCurrentValue,
          completed: true,
        );
        final finalProgress = Map<String, ChallengeProgressData>.from(
          updatedProgress,
        )..[challenge.id] = completedProgress;

        state = state.copyWith(
          userProgress: finalProgress,
          completedChallengeIds: [
            ...state.completedChallengeIds,
            challenge.id,
          ],
        );

        final notifier = ref.read(residentProvider.notifier);
        await notifier.awardActivityXp('challenge_complete', challenge.xpReward);
      }
    }
  }

  Future<void> claimReward(String challengeId) async {
    final challenge = state.activeChallenges.firstWhere(
      (c) => c.id == challengeId,
      orElse: () => const ChallengeData(
        id: '',
        title: '',
        description: '',
        type: '',
        targetValue: 0,
        xpReward: 0,
      ),
    );
    if (challenge.id.isEmpty) return;

    final residentId = ref.read(residentProvider).resident?.id;
    if (residentId == null) return;

    final progress = state.userProgress[challengeId];
    if (progress == null || !progress.completed) return;

    if (challenge.cosmeticReward != null) {
      final notifier = ref.read(residentProvider.notifier);
      notifier.addDecoration(challenge.cosmeticReward!);
    }
  }
}

final challengeProvider = NotifierProvider<ChallengeNotifier, ChallengeState>(
  ChallengeNotifier.new,
);
