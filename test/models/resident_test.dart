import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_status_worlds/models/resident.dart';

void main() {
  group('ResidentTier', () {
    test('fromValue returns correct tier', () {
      expect(ResidentTier.fromValue(1), ResidentTier.hustlers);
      expect(ResidentTier.fromValue(3), ResidentTier.elite);
      expect(ResidentTier.fromValue(5), ResidentTier.apex);
    });

    test('fromValue clamps invalid values to hustlers', () {
      expect(ResidentTier.fromValue(0), ResidentTier.hustlers);
      expect(ResidentTier.fromValue(99), ResidentTier.hustlers);
    });

    test('fromXp returns correct tier', () {
      expect(ResidentTier.fromXp(0), ResidentTier.hustlers);
      expect(ResidentTier.fromXp(500), ResidentTier.highRollers);
      expect(ResidentTier.fromXp(2000), ResidentTier.elite);
      expect(ResidentTier.fromXp(10000), ResidentTier.oldMoney);
      expect(ResidentTier.fromXp(50000), ResidentTier.apex);
    });
  });

  group('Resident', () {
    test('copyWith preserves unchanged fields', () {
      const r = Resident(id: '1', name: 'Test');
      final updated = r.copyWith(bio: 'Hello');
      expect(updated.id, '1');
      expect(updated.name, 'Test');
      expect(updated.bio, 'Hello');
      expect(updated.tier, ResidentTier.hustlers);
    });

    test('defaults are correct', () {
      const r = Resident(id: '1', name: 'Test');
      expect(r.bio, '');
      expect(r.following, []);
      expect(r.verifiedRoles, []);
      expect(r.streakCount, 0);
    });
  });
}
