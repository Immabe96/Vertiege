import '../models/resident.dart';
import '../models/world.dart';

const Map<String, List<String>> professionAliases = {
  'Medical': ['Doctor', 'Surgeon', 'Nurse'],
  'Engineering': ['Engineer', 'Developer'],
  'Finance': ['Banker', 'Accountant', 'Trader'],
  'Legal': ['Lawyer', 'Attorney', 'Judge'],
  'Arts': ['Artist', 'Designer', 'Musician'],
  'Aviation': ['Pilot', 'Flight Attendant'],
  'Technology': ['Developer', 'Programmer', 'Software Engineer'],
};

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
      if (resident.verifiedRoles.contains(required)) return true;
      final aliases = professionAliases[required] ?? [];
      return resident.verifiedRoles.any((role) => aliases.contains(role));

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
