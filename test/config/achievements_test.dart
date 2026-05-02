import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_status_worlds/config/achievements.dart';
import 'package:virtual_status_worlds/models/resident.dart';

void main() {
  group('ACHIEVEMENTS', () {
    test('has 72 achievements', () {
      expect(achievements.length, 75);
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
