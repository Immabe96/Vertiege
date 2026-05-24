import '../models/resident.dart';

/// Server-authoritative gamification fields (F31).
Resident applyServerGamification(Resident local, Resident server) {
  return local.copyWith(
    tier: server.tier,
    totalXp: server.totalXp,
    prestigeLevel: server.prestigeLevel,
    prestigeStars: server.prestigeStars,
    referralXpMultiplier: server.referralXpMultiplier,
    successfulReferrals: server.successfulReferrals,
    sovereignCoins: server.sovereignCoins,
    lastCheckIn: server.lastCheckIn,
    streakCount: server.streakCount,
    streakShields: server.streakShields,
    worldStandings: server.worldStandings,
    lastActivityAt: server.lastActivityAt,
    joinedWorldIds: server.joinedWorldIds,
  );
}
