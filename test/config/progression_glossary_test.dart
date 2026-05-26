import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/progression_glossary.dart';
import 'package:vertiege/models/world.dart';

void main() {
  group('ProgressionGlossary', () {
    test('worldPrestigeShort never says Level', () {
      expect(ProgressionGlossary.worldPrestigeShort(12), 'Prestige 12');
    });

    test('worldEntryGateLabel for wealth world', () {
      const world = World(
        id: 'test',
        name: 'Test',
        type: WorldType.wealth,
        description: 'd',
        sovereignId: 's',
        sovereignName: 'S',
        requiredTier: 3,
      );
      expect(
        ProgressionGlossary.worldEntryGateLabel(world, 'Elite'),
        'Requires Elite tier or higher',
      );
    });

    test('xpToNextTier at hustler', () {
      expect(
        ProgressionGlossary.xpToNextTier(100, 1),
        contains('400 XP to High Roller'),
      );
    });
  });
}
