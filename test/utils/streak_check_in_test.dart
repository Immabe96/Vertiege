import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/streak_check_in.dart';

void main() {
  const today = '2026-05-24';
  const yesterday = '2026-05-23';
  const dayBefore = '2026-05-22';

  test('returns null when already checked in today', () {
    expect(
      computeStreakCheckIn(
        todayYmd: today,
        yesterdayYmd: yesterday,
        dayBeforeYesterdayYmd: dayBefore,
        lastCheckInYmd: today,
        currentStreak: 5,
        streakShields: 1,
      ),
      isNull,
    );
  });

  test('starts streak at 1 with no prior check-in', () {
    final r = computeStreakCheckIn(
      todayYmd: today,
      yesterdayYmd: yesterday,
      dayBeforeYesterdayYmd: dayBefore,
      lastCheckInYmd: null,
      currentStreak: 0,
      streakShields: 0,
    );
    expect(r?.streak, 1);
    expect(r?.shieldUsed, isFalse);
  });

  test('increments streak after consecutive day', () {
    final r = computeStreakCheckIn(
      todayYmd: today,
      yesterdayYmd: yesterday,
      dayBeforeYesterdayYmd: dayBefore,
      lastCheckInYmd: yesterday,
      currentStreak: 6,
      streakShields: 0,
    );
    expect(r?.streak, 7);
    expect(r?.bonusXp, 50);
  });

  test('uses shield when gap is one day beyond yesterday', () {
    final r = computeStreakCheckIn(
      todayYmd: today,
      yesterdayYmd: yesterday,
      dayBeforeYesterdayYmd: dayBefore,
      lastCheckInYmd: dayBefore,
      currentStreak: 10,
      streakShields: 2,
    );
    expect(r?.streak, 11);
    expect(r?.shieldUsed, isTrue);
  });

  test('resets streak after long gap without shield', () {
    final r = computeStreakCheckIn(
      todayYmd: today,
      yesterdayYmd: yesterday,
      dayBeforeYesterdayYmd: dayBefore,
      lastCheckInYmd: '2026-05-01',
      currentStreak: 20,
      streakShields: 0,
    );
    expect(r?.streak, 1);
  });
}
