import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/league_service.dart';
import 'resident_provider.dart';

class LeagueParticipant {
  final String userId;
  final String name;
  final String avatarUrl;
  final int weeklyXp;
  final String leagueTier;

  const LeagueParticipant({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.weeklyXp,
    required this.leagueTier,
  });

  factory LeagueParticipant.fromMap(Map<String, dynamic> map, int rank) {
    final profiles = map['profiles'] as Map?;
    return LeagueParticipant(
      userId: map['user_id'] ?? '',
      name: profiles?['name'] ?? 'Unknown',
      avatarUrl: profiles?['avatar_url'] ?? '',
      weeklyXp: map['weekly_xp'] ?? 0,
      leagueTier: map['league_tier'] ?? 'bronze',
    );
  }
}

class UserLeagueInfo {
  final String tier;
  final int rank;
  final int weeklyXp;

  const UserLeagueInfo({
    required this.tier,
    required this.rank,
    required this.weeklyXp,
  });
}

class LeagueSeason {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const LeagueSeason({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory LeagueSeason.fromMap(Map<String, dynamic> map) {
    return LeagueSeason(
      id: map['id'] ?? '',
      startDate: DateTime.tryParse(map['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['end_date'] ?? '') ?? DateTime.now(),
      isActive: map['is_active'] ?? false,
    );
  }
}

class LeagueState {
  final LeagueSeason? currentSeason;
  final UserLeagueInfo? userLeague;
  final List<LeagueParticipant> standings;
  final bool isLoading;
  final String? error;

  const LeagueState({
    this.currentSeason,
    this.userLeague,
    this.standings = const [],
    this.isLoading = false,
    this.error,
  });

  LeagueState copyWith({
    LeagueSeason? currentSeason,
    UserLeagueInfo? userLeague,
    List<LeagueParticipant>? standings,
    bool? isLoading,
    String? error,
  }) => LeagueState(
    currentSeason: currentSeason ?? this.currentSeason,
    userLeague: userLeague ?? this.userLeague,
    standings: standings ?? this.standings,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class LeagueNotifier extends Notifier<LeagueState> {
  @override
  LeagueState build() {
    return const LeagueState();
  }

  Future<void> loadLeague() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = ref.read(residentProvider).resident?.id;
      final residentId = ref.read(residentProvider).resident?.id;
      final effectiveUserId = userId ?? residentId;

      if (effectiveUserId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final seasonData = await LeagueService.getCurrentSeason();
      final season = LeagueSeason.fromMap(seasonData);

      final userLeagueData = await LeagueService.getUserLeague(effectiveUserId);
      if (userLeagueData.isEmpty) {
        await LeagueService.assignNewUserLeague(effectiveUserId);
      }

      final updatedUserLeagueData = await LeagueService.getUserLeague(effectiveUserId);
      final userTier = updatedUserLeagueData['league_tier'] ?? 'bronze';
      final userWeeklyXp = updatedUserLeagueData['weekly_xp'] ?? 0;

      final standingsData = await LeagueService.getLeagueStandings(userTier);
      final standings = <LeagueParticipant>[];
      for (int i = 0; i < standingsData.length; i++) {
        standings.add(LeagueParticipant.fromMap(standingsData[i], i + 1));
      }

      int userRank = standings.indexWhere((p) => p.userId == effectiveUserId);
      if (userRank == -1) userRank = 0;

      state = state.copyWith(
        currentSeason: season,
        userLeague: UserLeagueInfo(
          tier: userTier,
          rank: userRank + 1,
          weeklyXp: userWeeklyXp,
        ),
        standings: standings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> trackXP(int amount) async {
    final residentId = ref.read(residentProvider).resident?.id;
    if (residentId == null) return;

    try {
      await LeagueService.addXP(residentId, amount);
      await refreshStandings();
    } catch (_) {}
  }

  Future<void> refreshStandings() async {
    final userLeague = state.userLeague;
    if (userLeague == null) return;

    try {
      final standingsData = await LeagueService.getLeagueStandings(userLeague.tier);
      final standings = <LeagueParticipant>[];
      for (int i = 0; i < standingsData.length; i++) {
        standings.add(LeagueParticipant.fromMap(standingsData[i], i + 1));
      }

      final residentId = ref.read(residentProvider).resident?.id;
      int userRank = standings.indexWhere((p) => p.userId == residentId);
      if (userRank == -1) userRank = 0;

      final updatedWeeklyXp = standings.isNotEmpty && userRank < standings.length
          ? standings[userRank].weeklyXp
          : userLeague.weeklyXp;

      state = state.copyWith(
        standings: standings,
        userLeague: UserLeagueInfo(
          tier: userLeague.tier,
          rank: userRank + 1,
          weeklyXp: updatedWeeklyXp,
        ),
      );
    } catch (_) {}
  }
}

final leagueProvider = NotifierProvider<LeagueNotifier, LeagueState>(
  LeagueNotifier.new,
);
