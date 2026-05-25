import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/achievements.dart';
import 'package:vertiege/models/achievement.dart';
import 'package:vertiege/models/resident.dart';

void main() {
  group('ACHIEVEMENTS', () {
    test('has 100 achievements', () {
      expect(achievements.length, 100);
    });

    test('life category has seed entries', () {
      final life = achievements
          .where((a) => a.category == AchievementCategory.life)
          .toList();
      expect(life.length, greaterThanOrEqualTo(10));
    });

    test('each has valid data', () {
      for (final a in achievements) {
        expect(a.id.isNotEmpty, true);
        expect(a.title.isNotEmpty, true);
        expect(a.xpValue, greaterThan(0));
      }
    });

    test('no duplicate IDs', () {
      final ids = achievements.map((a) => a.id).toSet();
      expect(ids.length, achievements.length);
    });
  });

  group('getTierForXp', () {
    test('returns tiers at correct thresholds', () {
      expect(getTierForXp(0), ResidentTier.hustlers);
      expect(getTierForXp(499), ResidentTier.hustlers);
      expect(getTierForXp(500), ResidentTier.highRollers);
      expect(getTierForXp(1999), ResidentTier.highRollers);
      expect(getTierForXp(2000), ResidentTier.elite);
      expect(getTierForXp(9999), ResidentTier.elite);
      expect(getTierForXp(10000), ResidentTier.oldMoney);
      expect(getTierForXp(49999), ResidentTier.oldMoney);
      expect(getTierForXp(50000), ResidentTier.apex);
    });
  });
}
