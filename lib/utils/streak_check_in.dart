/// Pure daily check-in streak logic (mirrors [record_daily_check_in] RPC).
class StreakCheckInResult {
  final int streak;
  final int bonusXp;
  final bool shieldUsed;

  const StreakCheckInResult({
    required this.streak,
    required this.bonusXp,
    required this.shieldUsed,
  });
}

/// Returns null when already checked in today.
StreakCheckInResult? computeStreakCheckIn({
  required String todayYmd,
  required String yesterdayYmd,
  required String dayBeforeYesterdayYmd,
  required String? lastCheckInYmd,
  required int currentStreak,
  required int streakShields,
}) {
  if (lastCheckInYmd == todayYmd) return null;

  final lastDate = lastCheckInYmd;
  var shieldUsed = false;
  final int newStreak;
  if (lastDate == null) {
    newStreak = 1;
  } else if (lastDate == yesterdayYmd) {
    newStreak = currentStreak + 1;
  } else if (streakShields > 0 && lastDate == dayBeforeYesterdayYmd) {
    newStreak = currentStreak + 1;
    shieldUsed = true;
  } else {
    newStreak = 1;
  }

  return StreakCheckInResult(
    streak: newStreak,
    bonusXp: streakBonusXp(newStreak),
    shieldUsed: shieldUsed,
  );
}

int streakBonusXp(int streak) {
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

String dateYmd(DateTime dt) => dt.toIso8601String().substring(0, 10);
