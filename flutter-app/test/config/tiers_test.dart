import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/tiers.dart';
import 'package:vertiege/models/world.dart';

void main() {
  group('WORLDS_CONFIG', () {
    test('has 15 worlds', () {
      expect(worldsConfig.length, 16);
    });

    test('each world has required fields', () {
      for (final world in worldsConfig.values) {
        expect(world.id.isNotEmpty, true);
        expect(world.name.isNotEmpty, true);
        expect(world.description.isNotEmpty, true);
        expect(world.sovereignName.isNotEmpty, true);
        expect(world.prestige, greaterThan(0));
      }
    });

    test('wealth worlds have requiredTier', () {
      final wealth = worldsConfig.values.where((w) => w.type == WorldType.wealth);
      for (final w in wealth) {
        expect(w.requiredTier, isNotNull);
      }
    });

    test('profession worlds have requiredProfession', () {
      final prof = worldsConfig.values.where((w) => w.type == WorldType.profession);
      for (final w in prof) {
        expect(w.requiredProfession, isNotNull);
      }
    });
  });

  group('getStanding', () {
    test('returns Visitor at 0 rep', () {
      final s = getStanding(0);
      expect(s.title, 'Visitor');
      expect(s.level, 1);
    });

    test('returns Member at 10 rep', () {
      final s = getStanding(10);
      expect(s.title, 'Member');
    });

    test('returns Council at 5000 rep', () {
      final s = getStanding(5000);
      expect(s.title, 'Council');
    });
  });

  group('calculatePrestige', () {
    test('clamps to 1-50', () {
      final p = calculatePrestige(
        sovereignTier: 5,
        avgMemberTier: 5,
        weeklyPosts: 100,
        weeklyReactions: 500,
        memberCount: 100,
      );
      expect(p, 50);
    });
  });
}
