import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/world_page_ia.dart';
import 'package:vertiege/models/world.dart';

World _dominion(DominionType type) => World(
      id: 'w1',
      slug: 'w1',
      name: 'Test',
      type: WorldType.dominion,
      description: 'Desc',
      sovereignId: 's1',
      sovereignName: 'Admin',
      dominionType: type,
    );

void main() {
  group('WorldPageIa', () {
    test('marketplace world includes shop tab', () {
      final tabs = WorldPageIa.tabsFor(_dominion(DominionType.marketplace));
      expect(tabs, contains(WorldDetailTabId.shop));
      expect(tabs.length, 5);
    });

    test('sanctuary world has no shop tab', () {
      final tabs = WorldPageIa.tabsFor(_dominion(DominionType.sanctuary));
      expect(tabs, isNot(contains(WorldDetailTabId.shop)));
      expect(tabs.length, 4);
    });

    test('default tab visitor vs member', () {
      final world = _dominion(DominionType.sanctuary);
      expect(
        WorldPageIa.defaultTabIndex(world: world, isJoined: false),
        WorldPageIa.homeIndex(world),
      );
      expect(
        WorldPageIa.defaultTabIndex(world: world, isJoined: true),
        WorldPageIa.feedIndex(world),
      );
      expect(
        WorldPageIa.defaultTabIndex(
          world: world,
          isJoined: true,
          memberOpensOnFeed: false,
        ),
        WorldPageIa.homeIndex(world),
      );
    });

    test('post highlight opens feed', () {
      final world = _dominion(DominionType.sanctuary);
      expect(
        WorldPageIa.defaultTabIndex(
          world: world,
          isJoined: false,
          hasPostHighlight: true,
        ),
        WorldPageIa.feedIndex(world),
      );
    });

    test('creatable dominion names', () {
      expect(WorldPageIa.isCreatableDominionName('sanctuary'), isTrue);
      expect(WorldPageIa.isCreatableDominionName('marketplace'), isTrue);
      expect(WorldPageIa.isCreatableDominionName('academy'), isFalse);
      expect(
        WorldPageIa.normalizeDominionType(DominionType.academy),
        DominionType.sanctuary,
      );
    });

    test('visibility labels', () {
      final open = _dominion(DominionType.sanctuary);
      expect(WorldPageIa.visibilityLabel(open), 'Public');

      final invite = open.copyWith(
        constitution: const WorldConstitution(admission: 'invite-only'),
      );
      expect(WorldPageIa.visibilityLabel(invite), 'Private · invite only');
    });
  });
}
