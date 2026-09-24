/// Progress hub routes (Wave 22).
String progressPath({ProgressTab? tab}) {
  if (tab == null) return '/progress';
  return '/progress?tab=${tab.queryValue}';
}

enum ProgressTab {
  quests,
  world,
  season,
  league;

  String get queryValue => switch (this) {
        ProgressTab.quests => 'quests',
        ProgressTab.world => 'world',
        ProgressTab.season => 'season',
        ProgressTab.league => 'league',
      };

  static ProgressTab? fromQuery(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'quests' => ProgressTab.quests,
      'world' => ProgressTab.world,
      'season' => ProgressTab.season,
      'league' => ProgressTab.league,
      _ => null,
    };
  }
}
