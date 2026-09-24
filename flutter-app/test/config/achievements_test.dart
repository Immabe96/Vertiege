import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/achievements.dart';
import 'package:vertiege/config/core_achievement_badge_ids.dart';
import 'package:vertiege/models/achievement.dart';
import 'package:vertiege/models/resident.dart';
import 'package:vertiege/utils/world_assets.dart';

void main() {
  group('ACHIEVEMENTS', () {
    test('catalog stays within product limit', () {
      expect(achievements.length, greaterThan(110));
      expect(achievements.length, greaterThanOrEqualTo(615));
      expect(achievements.length, lessThanOrEqualTo(achievementCatalogLimit));
      expect(achievementCatalogSize, achievements.length);
      expect(coreAchievementCount, 110);
    });

    test('non-inApp achievements have verifier proof hints', () {
      final proofBased = achievements.where(
        (a) => a.category != AchievementCategory.inApp,
      );
      expect(proofBased.length, greaterThan(550));
      for (final a in proofBased) {
        expect(
          a.proofHint,
          isNotNull,
          reason: '${a.id} missing proofHint',
        );
        expect(a.proofHint!.trim().isNotEmpty, true);
      }
    });

    test('inApp achievements do not require proof', () {
      final inAppEntries = achievements.where(
        (a) => a.category == AchievementCategory.inApp,
      );
      for (final a in inAppEntries) {
        expect(a.proofRequired, false);
        expect(a.effectiveMinImages, 0);
      }
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

    test('achievementForId lookup', () {
      expect(achievementForId('edu-hs')?.title, 'High School Graduate');
      expect(achievementForId('edu-seed-honors-roll')?.category,
          AchievementCategory.education);
      expect(achievementForId('not-in-catalog'), isNull);
      expect(achievementById.length, achievements.length);
    });

    test('profession verification maps to catalog id', () {
      expect(achievementIdForVerifiedProfession('Medical'), 'prof-doctor');
      expect(achievementIdForVerifiedProfession('Nursing'), 'prof-nurse');
      expect(achievementIdForVerifiedProfession('Technology'), 'prof-engineer');
      expect(achievementIdForVerifiedProfession('Unknown'), isNull);
    });

    test('selectable professions include expanded list', () {
      expect(selectableProfessions.length, greaterThanOrEqualTo(14));
      expect(selectableProfessions, contains('Nursing'));
      expect(selectableProfessions, contains('Journalism'));
    });

    test('core achievements resolve per-id badge asset path', () {
      expect(coreAchievementBadgeIds.length, greaterThanOrEqualTo(100));
      expect(coreAchievementBadgeIds, contains('edu-hs'));
      expect(
        WorldAssets.coreAchievementBadgeImage('edu-hs'),
        'assets/generated/achievements/edu-hs.png',
      );
      expect(WorldAssets.coreAchievementBadgeImage('edu-seed-honors-roll'), isNull);
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
