import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/resident.dart';
import 'package:vertiege/models/world.dart';
import 'package:vertiege/services/access_control.dart';

void main() {
  final hustler = const Resident(id: '1', name: 'Test');
  final elite = const Resident(id: '2', name: 'Elite', tier: ResidentTier.elite);
  final apex = const Resident(id: '3', name: 'Apex', tier: ResidentTier.apex);

  final worldTier2 = const World(
    id: 'w1', name: 'Test', type: WorldType.wealth,
    description: '', sovereignId: '', sovereignName: '',
    requiredTier: 2,
  );

  final worldMed = const World(
    id: 'w2', name: 'Medical', type: WorldType.profession,
    description: '', sovereignId: '', sovereignName: '',
    requiredProfession: 'Medical',
  );

  group('canAccessWorld', () {
    test('tier too low grants no access to wealth world', () {
      expect(canAccessWorld(hustler, worldTier2), false);
    });

    test('tier high enough grants access to wealth world', () {
      expect(canAccessWorld(elite, worldTier2), true);
    });

    test('apex accesses all wealth worlds', () {
      expect(canAccessWorld(apex, worldTier2), true);
    });

    test('profession world requires verified role', () {
      expect(canAccessWorld(hustler, worldMed), false);
    });

    test('verified profession grants access', () {
      final doctor = const Resident(id: '4', name: 'Doc', verifiedRoles: ['Medical']);
      expect(canAccessWorld(doctor, worldMed), true);
    });

    test('nursing profession aliases medical gate', () {
      final nurse = const Resident(
        id: '6',
        name: 'Nurse',
        profession: 'Nursing',
        verifiedRoles: ['Nursing'],
      );
      expect(canAccessWorld(nurse, worldMed), true);
    });

    test('explicitly unlocked wealth world grants access regardless of tier', () {
      final poorButUnlocked = const Resident(
        id: '5', name: 'Unlocked',
        wealthWorldsUnlocked: ['w1'],
      );
      expect(canAccessWorld(poorButUnlocked, worldTier2), true);
    });
  });
}
