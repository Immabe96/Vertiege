import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/progression_access.dart';
import 'package:vertiege/models/resident.dart';

void main() {
  group('ProgressionAccess', () {
    test('ascension unlocks at Elite (tier 3)', () {
      expect(ProgressionAccess.canAccessAscension(1), isFalse);
      expect(ProgressionAccess.canAccessAscension(2), isFalse);
      expect(ProgressionAccess.canAccessAscension(3), isTrue);
      expect(ProgressionAccess.canAccessAscension(5), isTrue);
    });

    test('canAccessAscensionFor null resident is false', () {
      expect(ProgressionAccess.canAccessAscensionFor(null), isFalse);
    });

    test('canAccessAscensionFor uses resident tier', () {
      const elite = Resident(
        id: 'r1',
        name: 'Elite',
        tier: ResidentTier.elite,
        totalXp: 2000,
      );
      expect(ProgressionAccess.canAccessAscensionFor(elite), isTrue);
    });
  });
}
