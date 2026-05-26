import '../models/achievement.dart';
import '../models/resident.dart';
import '../services/world_service.dart';

/// First-session checklist aligned with product funnel:
/// profile → world → nexus → achievement proof.
class OnboardingFunnel {
  OnboardingFunnel._();

  static bool profileReady(Resident resident) =>
      resident.name.trim().length >= 2;

  static bool hasJoinedWorld(Resident resident) =>
      resident.joinedWorldIds.any(WorldService.isRemoteWorldId);

  static bool hasSubmittedProof(List<UserAchievement> achievements) {
    for (final ua in achievements) {
      if (ua.submittedAt == null) continue;
      final proofs = ua.proofUris;
      if (proofs.isEmpty) continue;
      if (proofs.length == 1 && proofs.first == 'auto') continue;
      return true;
    }
    return false;
  }

  static bool isComplete({
    required Resident resident,
    required List<UserAchievement> achievements,
    required bool openedWorld,
    required bool openedNexus,
  }) {
    return profileReady(resident) &&
        hasJoinedWorld(resident) &&
        openedWorld &&
        openedNexus &&
        hasSubmittedProof(achievements);
  }

  static int completedCount({
    required Resident resident,
    required List<UserAchievement> achievements,
    required bool openedWorld,
    required bool openedNexus,
  }) {
    var n = 0;
    if (profileReady(resident)) n++;
    if (hasJoinedWorld(resident)) n++;
    if (openedWorld) n++;
    if (openedNexus) n++;
    if (hasSubmittedProof(achievements)) n++;
    return n;
  }

  static const totalSteps = 5;
}
