import '../models/world.dart';

const Map<int, String> tierNames = {
  1: 'Hustler',
  2: 'High Roller',
  3: 'Elite',
  4: 'Old Money',
  5: 'Apex',
};

class StandingLevel {
  final int level;
  final String title;
  final int minRep;
  final List<String> unlocks;
  const StandingLevel(this.level, this.title, this.minRep, this.unlocks);
}

const List<StandingLevel> standingLevels = [
  StandingLevel(1, 'Visitor', 0, ['view']),
  StandingLevel(2, 'Member', 10, ['post', 'react', 'comment']),
  StandingLevel(3, 'Contributor', 50, ['images', 'polls', 'delete']),
  StandingLevel(4, 'Veteran', 200, ['lounge']),
  StandingLevel(5, 'Elder', 500, ['vault', 'gift']),
  StandingLevel(6, 'Patron', 1000, ['invite']),
  StandingLevel(7, 'Council', 5000, ['governance']),
];

StandingLevel getStanding(int rep) {
  StandingLevel? best;
  for (final level in standingLevels) {
    if (rep >= level.minRep) best = level;
  }
  return best ?? standingLevels[0];
}

({int current, int max}) getRepProgress(int rep) {
  final standing = getStanding(rep);
  final idx = standingLevels.indexOf(standing);
  final next = idx < standingLevels.length - 1
      ? standingLevels[idx + 1]
      : standing;
  return (current: rep - standing.minRep, max: next.minRep - standing.minRep);
}

// World level thresholds — activityScore needed per level (dominion worlds only)
// Each level increases resident capacity
const Map<int, int> worldLevelThresholds = {
  1: 0,
  2: 100,
  3: 250,
  4: 500,
  5: 1000,
  6: 2000,
  7: 3500,
  8: 5000,
  9: 7500,
  10: 10000,
};

// Resident capacity per world level
const Map<int, int> worldLevelCapacity = {
  1: 20,
  2: 50,
  3: 100,
  4: 200,
  5: 350,
  6: 500,
  7: 750,
  8: 1000,
  9: 1500,
  10: 2500,
};

int getWorldLevel(int activityScore) {
  int level = 1;
  for (final entry in worldLevelThresholds.entries) {
    if (activityScore >= entry.value) level = entry.key;
  }
  return level;
}

int getResidentCapacity(int worldLevel) {
  return worldLevelCapacity[worldLevel.clamp(1, 10)] ?? 20;
}

const Map<int, List<String>> featureUnlocks = {
  10: ['lounge'],
  15: ['events'],
  20: ['vault'],
  25: ['audioRooms'],
  30: ['marketplace'],
  35: ['treasury'],
  40: ['alliances'],
  45: ['landmarks'],
  50: ['governance'],
};

WorldFeatures getUnlockedFeatures(int prestige) {
  final accumulated = <String>{};
  for (final entry in featureUnlocks.entries) {
    if (prestige >= entry.key) {
      accumulated.addAll(entry.value);
    }
  }
  return WorldFeatures(
    lounge: accumulated.contains('lounge'),
    events: accumulated.contains('events'),
    vault: accumulated.contains('vault'),
    audioRooms: accumulated.contains('audioRooms'),
    marketplace: accumulated.contains('marketplace'),
    treasury: accumulated.contains('treasury'),
    alliances: accumulated.contains('alliances'),
    landmarks: accumulated.contains('landmarks'),
    governance: accumulated.contains('governance'),
  );
}

WorldFeatures getWorldFeatures(int prestige, WorldType type) {
  final clamped = type == WorldType.dominion
      ? prestige.clamp(1, 50)
      : prestige.clamp(1, 50);
  return getUnlockedFeatures(clamped);
}

int calculatePrestige({
  required int sovereignTier,
  required double avgMemberTier,
  required int weeklyPosts,
  required int weeklyReactions,
  required int memberCount,
}) {
  final score =
      sovereignTier * 8 +
      avgMemberTier * 5 +
      (weeklyPosts.clamp(0, 20)) * 0.5 +
      (weeklyReactions.clamp(0, 100)) * 0.1 +
      (memberCount.clamp(0, 50)) * 0.3;
  return (score / 2).floor().clamp(1, 50);
}

final Map<String, World> worldsConfig = {
  'neon-district': const World(
    id: 'neon-district',
    name: 'Neon District',
    type: WorldType.wealth,
    description:
        'The entry point to the digital realm. Neon lights and endless opportunity.',
    sovereignId: 'sovereign-neon',
    sovereignName: 'The Architect',
    prestige: 5,
    icon: 'neon',
    requiredTier: 1,
  ),
  'azure-coast': const World(
    id: 'azure-coast',
    name: 'Azure Coast',
    type: WorldType.wealth,
    description:
        'Pristine shores where the High Rollers gather to shape the economy.',
    sovereignId: 'sovereign-azure',
    sovereignName: 'Countess Voss',
    prestige: 12,
    icon: 'azure',
    requiredTier: 2,
  ),
  'sovereign-city': const World(
    id: 'sovereign-city',
    name: 'Sovereign City',
    type: WorldType.wealth,
    description:
        'The capital of power. Only the Elite tread these gilded streets.',
    sovereignId: 'sovereign-city-lord',
    sovereignName: 'Chancellor Vale',
    prestige: 22,
    icon: 'sovereign',
    requiredTier: 3,
  ),
  'golden-estate': const World(
    id: 'golden-estate',
    name: 'Golden Estate',
    type: WorldType.wealth,
    description: 'Old Money estates sprawling across manicured landscapes.',
    sovereignId: 'sovereign-golden',
    sovereignName: 'Lord Ashford',
    prestige: 35,
    icon: 'golden',
    requiredTier: 4,
  ),
  'aetheria': const World(
    id: 'aetheria',
    name: 'Aetheria',
    type: WorldType.wealth,
    description: 'The mythical apex realm where legends are forged.',
    sovereignId: 'sovereign-aetheria',
    sovereignName: 'The Oracle',
    prestige: 48,
    icon: 'aetheria',
    requiredTier: 5,
  ),
  'aviation-heights': const World(
    id: 'aviation-heights',
    name: 'Aviation Heights',
    type: WorldType.profession,
    description:
        'Where pilots and aerospace innovators push the boundaries of flight.',
    sovereignId: 'sovereign-aviation',
    sovereignName: 'Captain Storm',
    prestige: 18,
    icon: 'aviation',
    requiredProfession: 'Aviation',
  ),
  'medical-nexus': const World(
    id: 'medical-nexus',
    name: 'Medical Nexus',
    type: WorldType.profession,
    description:
        'The cutting edge of medicine where healers advance their craft.',
    sovereignId: 'sovereign-medical',
    sovereignName: 'Dean Hippocrates',
    prestige: 28,
    icon: 'medical',
    requiredProfession: 'Medical',
  ),
  'financial-district': const World(
    id: 'financial-district',
    name: 'Financial District',
    type: WorldType.profession,
    description: 'The heart of capital where financiers move markets.',
    sovereignId: 'sovereign-finance',
    sovereignName: 'Baron Roth',
    prestige: 32,
    icon: 'finance',
    requiredProfession: 'Finance',
  ),
  'tech-sprawl': const World(
    id: 'tech-sprawl',
    name: 'Tech Sprawl',
    type: WorldType.profession,
    description: 'A sprawling digital metropolis for the architects of code.',
    sovereignId: 'sovereign-tech',
    sovereignName: 'Architect Kai',
    prestige: 25,
    icon: 'tech',
    requiredProfession: 'Technology',
  ),
  'legal-plaza': const World(
    id: 'legal-plaza',
    name: 'Legal Plaza',
    type: WorldType.profession,
    description: 'Where law and order shape the framework of society.',
    sovereignId: 'sovereign-legal',
    sovereignName: 'Justice Thorne',
    prestige: 20,
    icon: 'legal',
    requiredProfession: 'Legal',
  ),
  'arts-pavilion': const World(
    id: 'arts-pavilion',
    name: 'Arts Pavilion',
    type: WorldType.profession,
    description:
        'A sanctuary of creativity where artists bring beauty to life.',
    sovereignId: 'sovereign-arts',
    sovereignName: 'Curator Noire',
    prestige: 15,
    icon: 'arts',
    requiredProfession: 'Arts',
  ),
  'crystal-shore': const World(
    id: 'crystal-shore',
    name: 'Crystal Shore',
    type: WorldType.wealth,
    description: 'Shimmering crystal beaches open to all newcomers.',
    sovereignId: 'sovereign-crystal',
    sovereignName: 'Admiral Tide',
    prestige: 3,
    icon: 'crystal',
    requiredTier: 1,
  ),
  'quantum-core': const World(
    id: 'quantum-core',
    name: 'Quantum Core',
    type: WorldType.profession,
    description: 'The bleeding edge of engineering and quantum mechanics.',
    sovereignId: 'sovereign-quantum',
    sovereignName: 'Dr. Flux',
    prestige: 24,
    icon: 'quantum',
    requiredProfession: 'Engineer',
  ),
  'silver-page': const World(
    id: 'silver-page',
    name: 'Silver Page',
    type: WorldType.profession,
    description:
        'A quiet library realm where wordsmiths and storytellers dwell.',
    sovereignId: 'sovereign-silver',
    sovereignName: 'Scribe Aurelius',
    prestige: 10,
    icon: 'silver',
    requiredProfession: 'Artist',
  ),
  'crimson-court': const World(
    id: 'crimson-court',
    name: 'Crimson Court',
    type: WorldType.wealth,
    description:
        'A velvet-draped court of intrigue for discerning High Rollers.',
    sovereignId: 'sovereign-crimson',
    sovereignName: 'Duchess Scarlett',
    prestige: 16,
    icon: 'crimson',
    requiredTier: 2,
  ),
  'nova-station': const World(
    id: 'nova-station',
    name: 'Nova Station',
    type: WorldType.wealth,
    description:
        'A deep-space outpost orbiting the frontier of the known universe.',
    sovereignId: 'sovereign-nova',
    sovereignName: 'Commander Vega',
    prestige: 42,
    icon: 'nova',
    requiredTier: 5,
  ),
};
