/// Season 1 — product narrative (not weekly league brackets).
class SeasonCatalog {
  SeasonCatalog._();

  static const activeSeasonId = 'season_1';

  static const season1 = SeasonDefinition(
    id: activeSeasonId,
    name: 'Season 1: The Big Bang',
    tagline: 'Empty worlds fill. New councils rise. Sovereigns claim the map.',
    narrative:
        'The first age of Vertiege: dormant realms awaken, residents earn standing, '
        'and worlds grow through real achievement. Unclaimed worlds gain sovereigns, '
        'councils form, and prestige unlocks lounge, treasury, and governance — together.',
    pillars: [
      'Unclaimed worlds find sovereigns',
      'Veteran councils emerge from standing',
      'World prestige unlocks shared systems',
      'Growth is earned, not purchased',
    ],
  );

  static SeasonDefinition get active => season1;
}

class SeasonDefinition {
  final String id;
  final String name;
  final String tagline;
  final String narrative;
  final List<String> pillars;

  const SeasonDefinition({
    required this.id,
    required this.name,
    required this.tagline,
    required this.narrative,
    required this.pillars,
  });
}
