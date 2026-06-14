import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/leaderboard_service.dart';
import 'resident_provider.dart';

enum LeaderboardTab { xp, achievements, referrals }

class LeaderboardState {
  final List<LeaderboardEntry> xpEntries;
  final List<LeaderboardEntry> achievementEntries;
  final List<LeaderboardEntry> referralEntries;
  final LeaderboardEntry? myRank;
  final bool isLoading;
  final String? error;
  final LeaderboardTab selectedTab;

  const LeaderboardState({
    this.xpEntries = const [],
    this.achievementEntries = const [],
    this.referralEntries = const [],
    this.myRank,
    this.isLoading = false,
    this.error,
    this.selectedTab = LeaderboardTab.xp,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? xpEntries,
    List<LeaderboardEntry>? achievementEntries,
    List<LeaderboardEntry>? referralEntries,
    LeaderboardEntry? myRank,
    bool? isLoading,
    String? error,
    bool clearError = false,
    LeaderboardTab? selectedTab,
  }) {
    return LeaderboardState(
      xpEntries: xpEntries ?? this.xpEntries,
      achievementEntries: achievementEntries ?? this.achievementEntries,
      referralEntries: referralEntries ?? this.referralEntries,
      myRank: myRank ?? this.myRank,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }

  List<LeaderboardEntry> get currentEntries {
    switch (selectedTab) {
      case LeaderboardTab.xp:
        return xpEntries;
      case LeaderboardTab.achievements:
        return achievementEntries;
      case LeaderboardTab.referrals:
        return referralEntries;
    }
  }
}

class LeaderboardNotifier extends Notifier<LeaderboardState> {
  @override
  LeaderboardState build() => const LeaderboardState();

  void selectTab(LeaderboardTab tab) {
    state = state.copyWith(selectedTab: tab);
    if (state.currentEntries.isEmpty) {
      loadLeaderboard();
    }
  }

  Future<void> loadLeaderboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final residentId = ref.read(residentProvider).resident?.id;

      final results = await Future.wait([
        LeaderboardService.getGlobalLeaderboard(limit: 50),
        LeaderboardService.getAchievementLeaderboard(limit: 50),
        LeaderboardService.getReferralLeaderboard(limit: 50),
        if (residentId != null)
          LeaderboardService.getMyRank(residentId)
        else
          Future.value(null),
      ]);

      state = state.copyWith(
        xpEntries: results[0] as List<LeaderboardEntry>,
        achievementEntries: results[1] as List<LeaderboardEntry>,
        referralEntries: results[2] as List<LeaderboardEntry>,
        myRank: results[3] as LeaderboardEntry?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load leaderboard. Pull to refresh.',
      );
    }
  }
}

final leaderboardProvider =
    NotifierProvider<LeaderboardNotifier, LeaderboardState>(
  LeaderboardNotifier.new,
);
