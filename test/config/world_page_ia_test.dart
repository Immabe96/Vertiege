import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/world_page_ia.dart';
import 'package:vertiege/models/world.dart';

World _dominion(DominionType type, {int prestige = 1, int activityScore = 0}) =>
    World(
      id: 'w1',
      slug: 'w1',
      name: 'Test',
      type: WorldType.dominion,
      description: 'Desc',
      sovereignId: 's1',
      sovereignName: 'Admin',
      dominionType: type,
      prestige: prestige,
      activityScore: activityScore,
    );

void main() {
  group('WorldPageIa', () {
    test('marketplace world is channels-first with optional feed', () {
      final tabs = WorldPageIa.tabsFor(_dominion(DominionType.marketplace));
      expect(tabs.first, WorldDetailTabId.channels);
      expect(tabs, isNot(contains(WorldDetailTabId.shop)));
      expect(tabs, contains(WorldDetailTabId.feed));
      expect(tabs.length, 4);
    });

    test('sanctuary world has no shop or feed tab by default', () {
      final tabs = WorldPageIa.tabsFor(_dominion(DominionType.sanctuary));
      expect(tabs, isNot(contains(WorldDetailTabId.shop)));
      expect(tabs, isNot(contains(WorldDetailTabId.feed)));
      expect(tabs.first, WorldDetailTabId.channels);
      expect(tabs.length, 3);
    });

    test('feed tab appears when world has activity', () {
      final tabs = WorldPageIa.tabsFor(
        _dominion(DominionType.sanctuary, activityScore: 5),
      );
      expect(tabs, contains(WorldDetailTabId.feed));
    });

    test('default tab visitor vs member', () {
      final world = _dominion(DominionType.sanctuary);
      expect(
        WorldPageIa.defaultTabIndex(world: world, isJoined: false),
        WorldPageIa.homeIndex(world),
      );
      expect(
        WorldPageIa.defaultTabIndex(world: world, isJoined: true),
        WorldPageIa.indexOf(world, WorldDetailTabId.channels),
      );
      expect(
        WorldPageIa.defaultTabIndex(
          world: world,
          isJoined: true,
          memberOpensOnFeed: false,
        ),
        WorldPageIa.indexOf(world, WorldDetailTabId.channels),
      );
    });

    test('post highlight opens feed when available', () {
      final world = _dominion(DominionType.marketplace);
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
