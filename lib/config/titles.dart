/// Title definitions earned via achievements.
/// Keys are achievement IDs, values are display name titles.
const Map<String, String> earnedTitles = {
  'chronicler': 'the Storyteller',
  'season-sage': 'the Seasoned',
  'streak-365': 'the Eternal',
  'pioneer-poster': 'the Voice',
  'explorer': 'the Pathfinder',
  'nexus-scribe': 'the Scribe',
  'wayfarer': 'the Wayfarer',
  'week-warrior': 'the Devoted',
  'month-master': 'the Committed',
  'com-volunteer': 'the Benevolent',
  'com-mentor': 'the Guide',
  'cre-book': 'the Author',
  'cre-art': 'the Artist',
  'fin-debtfree': 'the Unburdened',
  'health-marathon': 'the Marathoner',
  'trv-7continents': 'the Global',
  'rel-marriage': 'the United',
  'car-business': 'the Founder',
  'cre-perform': 'the Performer',
  'skill-speak': 'the Orator',
};

/// Returns the display title for a given achievement ID, or null if none.
String? titleForAchievement(String achievementId) {
  return earnedTitles[achievementId];
}
