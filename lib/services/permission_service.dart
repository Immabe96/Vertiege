import '../config/tiers.dart';
import '../models/resident.dart';

class WorldPermissions {
  static const _postMinStanding = 2; // Member+
  static const _deleteOwnMinStanding = 3; // Contributor+
  static const _inviteMinStanding = 6; // Patron+
  static const _moderateMinStanding = 7; // Council+
  static const _manageMinStanding = 7; // Council+

  /// Resolve the effective standing level for a resident in a world.
  /// Sovereign always gets max standing (Council).
  static StandingLevel resolveStanding(Resident resident, String worldId, String? sovereignId) {
    if (resident.id == sovereignId) return standingLevels.last;
    final rep = resident.worldStandings[worldId]?.rep ?? 0;
    return getStanding(rep);
  }

  static int _standingLevel(Resident resident, String worldId, String? sovereignId) {
    if (resident.id == sovereignId) return standingLevels.length;
    final rep = resident.worldStandings[worldId]?.rep ?? 0;
    return getStanding(rep).level;
  }

  static bool canPost(Resident resident, String worldId, String? sovereignId) =>
      _standingLevel(resident, worldId, sovereignId) >= _postMinStanding;

  static bool canDeletePost(Resident resident, String worldId, String postAuthorId, String? sovereignId) {
    if (resident.id == sovereignId) return true;
    if (resident.id == postAuthorId) {
      return _standingLevel(resident, worldId, sovereignId) >= _deleteOwnMinStanding;
    }
    return _standingLevel(resident, worldId, sovereignId) >= _moderateMinStanding;
  }

  static bool canInvite(Resident resident, String worldId, String? sovereignId) =>
      _standingLevel(resident, worldId, sovereignId) >= _inviteMinStanding;

  static bool canManageSettings(Resident resident, String worldId, String? sovereignId) =>
      _standingLevel(resident, worldId, sovereignId) >= _manageMinStanding;

  static bool canModerate(Resident resident, String worldId, String? sovereignId) =>
      _standingLevel(resident, worldId, sovereignId) >= _moderateMinStanding;
}
