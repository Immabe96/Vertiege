import 'feature_flags.dart';

/// Remote Config A/B copy for streak re-engagement (Wave 16).
class ReEngagementPushCopy {
  ReEngagementPushCopy._();

  static String streakReminderBody({required int hoursLeft}) {
    final variant = FeatureFlags.reEngagementPushVariant;
    if (variant == 'calm') {
      if (hoursLeft <= 1) {
        return 'A quick visit today keeps your streak — no rush.';
      }
      return 'Your streak is still here when you are ready ($hoursLeft h left today).';
    }
    if (hoursLeft <= 1) {
      return 'Your streak expires in 1 hour! Open now to keep it.';
    }
    return 'Your streak expires in $hoursLeft hours! Open now to keep it.';
  }
}
