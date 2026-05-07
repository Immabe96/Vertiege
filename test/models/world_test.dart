import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/world.dart';

void main() {
  group('World serialization', () {
    test('constitution round-trips through toJson/fromJson', () {
      final world = World(
        id: 'w1',
        name: 'Test World',
        type: WorldType.wealth,
        description: 'A test world',
        sovereignId: 's1',
        sovereignName: 'Sovereign',
        constitution: const WorldConstitution(
          admission: 'application',
          minTier: 2,
          posting: 'moderated',
          contentTypes: ['text'],
          entryFee: 5,
        ),
      );

      final json = world.toJson();
      final restored = World.fromJson(json);

      expect(restored.constitution.admission, 'application');
      expect(restored.constitution.minTier, 2);
      expect(restored.constitution.posting, 'moderated');
      expect(restored.constitution.contentTypes, ['text']);
      expect(restored.constitution.entryFee, 5);
    });

    test('constitution defaults when missing from JSON', () {
      final world = World.fromJson({
        'id': 'w1',
        'name': 'Test',
        'type': 'wealth',
        'description': '',
        'sovereignId': '',
        'sovereignName': '',
      });

      expect(world.constitution.admission, 'open');
      expect(world.constitution.entryFee, 0);
    });
  });
}
