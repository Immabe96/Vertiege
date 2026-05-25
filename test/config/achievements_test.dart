import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/achievements.dart';
import 'package:vertiege/models/achievement.dart';
import 'package:vertiege/models/resident.dart';

void main() {
  group('ACHIEVEMENTS', () {
    test('catalog stays within product limit', () {
      expect(achievements.length, greaterThanOrEqualTo(100));
      expect(achievements.length, lessThanOrEqualTo(achievementCatalogLimit));
    });

    test('life category has expanded seed entries', () {
      final life = achievements
          .where((a) => a.category == AchievementCategory.life)
          .toList();
      expect(life.length, greaterThanOrEqualTo(20));
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
