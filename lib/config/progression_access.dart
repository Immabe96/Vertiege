import '../models/achievement.dart';
import '../models/resident.dart';

/// Gates for endgame / advanced progression surfaces.
abstract final class ProgressionAccess {
  /// Elite (3) and above — Hall of Ascension / Ascension path.
  static const int minAscensionTier = 3;

  static bool canAccessAscension(int tierValue) =>
      tierValue >= minAscensionTier;

  static bool canAccessAscensionFor(Resident? resident) =>
      resident != null && canAccessAscension(resident.tier.value);

  /// Cosmetics shop unlocks after the first verified life achievement.
  static bool canAccessShop(Iterable<UserAchievement> achievements) =>
      achievements.any((a) => a.status == AchievementStatus.verified);
}
