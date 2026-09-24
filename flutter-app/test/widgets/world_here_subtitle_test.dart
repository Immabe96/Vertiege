import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/world.dart';
import 'package:vertiege/widgets/worlds/world_here_subtitle.dart';

void main() {
  test('worldHereSubtitle includes prestige and membership', () {
    const world = World(
      id: 'w1',
      name: 'Neon',
      type: WorldType.dominion,
      description: '',
      sovereignId: 's1',
      sovereignName: 'Alice',
      prestige: 25,
      requiredTier: 3,
    );
    final line = worldHereSubtitle(
      world: world,
      isJoined: true,
      tierLabel: 'Open',
    );
    expect(line, contains('Prestige 25'));
    expect(line, contains('Member'));
  });
}
