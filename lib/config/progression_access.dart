import '../models/resident.dart';

/// Gates for endgame / advanced progression surfaces.
abstract final class ProgressionAccess {
  /// Elite (3) and above — Hall of Ascension / Ascension path.
  static const int minAscensionTier = 3;

  static bool canAccessAscension(int tierValue) =>
      tierValue >= minAscensionTier;

  static bool canAccessAscensionFor(Resident? resident) =>
      resident != null && canAccessAscension(resident.tier.value);
}
