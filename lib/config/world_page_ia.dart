import '../models/world.dart';

/// World detail information architecture — tabs, labels, defaults.
///
/// See [docs/vision/world-page-redesign.md].
enum WorldDetailTabId {
  home,
  feed,
  channels,
  members,
  shop,
}

class WorldPageIa {
  WorldPageIa._();

  /// Dominion types offered when **creating** a world (Release 4).
  static const userCreatableDominions = <DominionType>[
    DominionType.sanctuary,
    DominionType.marketplace,
  ];

  static const creatableDominionNames = {'sanctuary', 'marketplace'};

  static bool isCreatableDominionName(String? raw) =>
      raw != null && creatableDominionNames.contains(raw);

  /// Legacy DB values map to sanctuary until migrated off the client.
  static DominionType? normalizeDominionType(DominionType? type) {
    if (type == null) return null;
    switch (type) {
      case DominionType.academy:
      case DominionType.archive:
        return DominionType.sanctuary;
      case DominionType.marketplace:
      case DominionType.sanctuary:
        return type;
    }
  }

  static List<WorldDetailTabId> tabsFor(World world) {
    final tabs = <WorldDetailTabId>[
      WorldDetailTabId.home,
      WorldDetailTabId.feed,
      WorldDetailTabId.channels,
      WorldDetailTabId.members,
    ];
    if (world.isMarketplace) {
      tabs.add(WorldDetailTabId.shop);
    }
    return tabs;
  }

  static String tabLabel(WorldDetailTabId id) {
    switch (id) {
      case WorldDetailTabId.home:
        return 'HOME';
      case WorldDetailTabId.feed:
        return 'FEED';
      case WorldDetailTabId.channels:
        return 'CHANNELS';
      case WorldDetailTabId.members:
        return 'MEMBERS';
      case WorldDetailTabId.shop:
        return 'SHOP';
    }
  }

  static int indexOf(World world, WorldDetailTabId id) {
    return tabsFor(world).indexOf(id);
  }

  static int feedIndex(World world) => indexOf(world, WorldDetailTabId.feed);

  static int homeIndex(World world) => indexOf(world, WorldDetailTabId.home);

  static int defaultTabIndex({
    required World world,
    required bool isJoined,
    bool hasPostHighlight = false,
    bool memberOpensOnFeed = true,
  }) {
    if (hasPostHighlight) return feedIndex(world);
    if (isJoined) {
      return memberOpensOnFeed ? feedIndex(world) : homeIndex(world);
    }
    return homeIndex(world);
  }

  static String worldKindLabel(World world) {
    switch (world.type) {
      case WorldType.wealth:
        return 'Wealth world';
      case WorldType.profession:
        return 'Profession world';
      case WorldType.dominion:
        final type = world.dominionType;
        if (type == null) return 'Community world';
        switch (type) {
          case DominionType.marketplace:
            return 'Shop world';
          case DominionType.sanctuary:
            return 'Community world';
          case DominionType.academy:
            return 'Learning community';
          case DominionType.archive:
            return 'Knowledge world';
        }
    }
  }

  static String visibilityLabel(World world) {
    switch (world.constitution.admission) {
      case 'open':
        return 'Public';
      case 'invite-only':
        return 'Private · invite only';
      case 'application':
        return 'Private · application required';
      default:
        return world.constitution.admission;
    }
  }

  static String adminStatusLabel(World world) {
    if (world.isUnclaimed) {
      return 'No admin yet — first member can claim this world';
    }
    return 'Admin: ${world.sovereignName}';
  }
}
