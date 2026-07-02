/// Selectable resident professions and links to achievements / worlds.
library;

/// Empty option in profile pickers.
const String kNoProfession = '';

/// Ordered list for onboarding and edit profile (no empty entry).
const List<String> selectableProfessions = [
  'Aviation',
  'Medical',
  'Nursing',
  'Counseling',
  'Education',
  'Finance',
  'Legal',
  'Technology',
  'Engineering',
  'Architecture',
  'Science',
  'Arts',
  'Culinary',
  'Real Estate',
  'Journalism',
];

/// Picker options: blank + [selectableProfessions].
List<String> professionPickerOptions() => [
  kNoProfession,
  ...selectableProfessions,
];

/// Catalog achievement granted when staff approves profession verification.
const Map<String, String> professionToAchievementId = {
  'Aviation': 'prof-pilot',
  'Medical': 'prof-doctor',
  'Nursing': 'prof-nurse',
  'Counseling': 'prof-therapist',
  'Education': 'prof-teacher',
  'Finance': 'prof-finance',
  'Legal': 'prof-attorney',
  'Technology': 'prof-engineer',
  'Engineering': 'prof-engineer',
  'Architecture': 'prof-architect',
  'Science': 'prof-scientist',
  'Arts': 'prof-artist',
  'Culinary': 'prof-chef',
  'Real Estate': 'prof-realtor',
  'Journalism': 'prof-journalist',
};

/// Gate world slug suggested at The Gate (craft path).
const Map<String, String> professionGateWorldSlug = {
  'Aviation': 'aviation-heights',
  'Medical': 'medical-nexus',
  'Nursing': 'medical-nexus',
  'Counseling': 'medical-nexus',
  'Education': 'silver-page',
  'Finance': 'financial-district',
  'Legal': 'legal-plaza',
  'Technology': 'tech-sprawl',
  'Engineering': 'quantum-core',
  'Architecture': 'quantum-core',
  'Science': 'quantum-core',
  'Arts': 'arts-pavilion',
  'Culinary': 'arts-pavilion',
  'Real Estate': 'golden-estate',
  'Journalism': 'silver-page',
};

String? achievementIdForVerifiedProfession(String profession) =>
    professionToAchievementId[profession];

String? gateWorldSlugForProfession(String? profession) {
  if (profession == null || profession.isEmpty) return null;
  return professionGateWorldSlug[profession];
}
