import '../models/resident.dart';
import '../models/world.dart';

const Map<String, List<String>> professionAliases = {
  'Medical': ['Doctor', 'Surgeon', 'Nurse', 'Nursing', 'Counseling'],
  'Engineering': [
    'Engineer',
    'Developer',
    'Architecture',
    'Science',
  ],
  'Finance': ['Banker', 'Accountant', 'Trader', 'Real Estate'],
  'Legal': ['Lawyer', 'Attorney', 'Judge'],
  'Arts': ['Artist', 'Designer', 'Musician', 'Culinary', 'Journalism'],
  'Aviation': ['Pilot', 'Flight Attendant'],
  'Technology': ['Developer', 'Programmer', 'Software Engineer'],
  'Education': ['Teacher', 'Education'],
};

/// Whether [residentProfession] or [verifiedRoles] satisfy a profession-gated world.
bool residentMatchesProfessionGate({
  required String? residentProfession,
  required List<String> verifiedRoles,
  required String requiredProfession,
}) {
  if (verifiedRoles.contains(requiredProfession)) return true;
  if (residentProfession == requiredProfession) return true;
  final aliases = professionAliases[requiredProfession] ?? [];
  if (residentProfession != null && aliases.contains(residentProfession)) {
    return true;
  }
  return verifiedRoles.any(aliases.contains);
}

bool canAccessWorld(Resident resident, World world) {
  // Default worlds are always accessible
  if (world.isDefault) return true;

  // If resident has already joined, allow access
  if (resident.joinedWorldIds.contains(world.id)) return true;

  switch (world.type) {
    case WorldType.wealth:
      return resident.tier.value >= (world.requiredTier ?? 1) ||
          resident.wealthWorldsUnlocked.contains(world.id);

    case WorldType.profession:
      final required = world.requiredProfession;
      if (required == null) return true;
      return residentMatchesProfessionGate(
        residentProfession: resident.profession,
        verifiedRoles: resident.verifiedRoles,
        requiredProfession: required,
      );

    case WorldType.dominion:
      return true; // Dominion worlds are open to all
  }
}

List<World> getAccessibleWorlds(Resident resident, Map<String, World> worlds) {
  return worlds.values.where((w) => canAccessWorld(resident, w)).toList();
}

List<World> getLockedWorlds(Resident resident, Map<String, World> worlds) {
  return worlds.values.where((w) => !canAccessWorld(resident, w)).toList();
}
