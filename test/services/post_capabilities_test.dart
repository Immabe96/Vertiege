import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/resident.dart';
import 'package:vertiege/services/post_capabilities.dart';

void main() {
  group('PostCapabilities', () {
    test('denies announcement for regular resident', () {
      final resident = Resident(
        id: 'r1',
        name: 'Test',
        tier: ResidentTier.hustlers,
        joinedWorldIds: ['w1'],
      );
      final result = PostCapabilities.check(
        capability: PostCapability.announcement,
        resident: resident,
        worldId: 'w1',
        sovereignId: 'other',
      );
      expect(result.allowed, isFalse);
      expect(result.reason, isNotNull);
    });

    test('allows announcement for sovereign', () {
      final resident = Resident(
        id: 'sovereign',
        name: 'Sovereign',
        tier: ResidentTier.hustlers,
        joinedWorldIds: ['w1'],
      );
      final result = PostCapabilities.check(
        capability: PostCapability.announcement,
        resident: resident,
        worldId: 'w1',
        sovereignId: 'sovereign',
      );
      expect(result.allowed, isTrue);
    });
  });
}
