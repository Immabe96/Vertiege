import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/world_capability_matrix.dart';
import 'package:vertiege/config/tiers.dart';
import 'package:vertiege/models/resident.dart';
import 'package:vertiege/models/world.dart';

void main() {
  const resident = Resident(
    id: 'u1',
    name: 'Test',
    tier: ResidentTier.highRollers,
    joinedWorldIds: ['w1'],
    worldStandings: {'w1': WorldStanding(rep: 60)},
  );

  const lowTier = Resident(
    id: 'u2',
    name: 'Low',
    tier: ResidentTier.hustlers,
    joinedWorldIds: ['w1'],
    worldStandings: {'w1': WorldStanding(rep: 100)},
  );

  const world = World(
    id: 'w1',
    name: 'Test Dominion',
    type: WorldType.dominion,
    description: 'd',
    sovereignId: 'sovereign',
    sovereignName: 'S',
    prestige: 35,
    icon: 'x',
    activityScore: 150,
  );

  test('marketplace requires tier and standing', () {
    expect(WorldCapabilityMatrix.worldHasMarketplace(world), isTrue);
    expect(
      WorldCapabilityMatrix.canCreateListing(
        resident,
        world,
        isJoined: true,
      ),
      isTrue,
    );
    expect(
      WorldCapabilityMatrix.canCreateListing(
        lowTier,
        world,
        isJoined: true,
      ),
      isFalse,
    );
  });

  test('treasury manage requires council standing', () {
    expect(WorldCapabilityMatrix.canManageTreasury(resident, world), isFalse);
    expect(
      WorldCapabilityMatrix.canManageTreasury(
        const Resident(id: 'sovereign', name: 'S'),
        world,
      ),
      isTrue,
    );
  });

  test('world growth for dominion uses activity thresholds', () {
    final g = WorldCapabilityMatrix.worldGrowth(world);
    expect(g.level, getWorldLevel(150));
    expect(g.activityScore, 150);
  });
}
