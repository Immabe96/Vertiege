import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';

enum SubscriptionTier { resident, patrician, sovereignElite }

class SubscriptionService {
  static const patricianProductId = 'subscription_patrician';
  static const sovereignEliteProductId = 'subscription_sovereign_elite';

  static String _tierKey(String residentId) => 'subscription_tier_$residentId';

  /// Returns the current subscription tier for a resident.
  static Future<SubscriptionTier> getTier(String residentId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_tierKey(residentId));
    if (stored == 'patrician') return SubscriptionTier.patrician;
    if (stored == 'sovereign_elite') return SubscriptionTier.sovereignElite;
    return SubscriptionTier.resident;
  }

  /// Persists the subscription tier locally.
  static Future<void> setTier(String residentId, SubscriptionTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    switch (tier) {
      case SubscriptionTier.patrician:
        await prefs.setString(_tierKey(residentId), 'patrician');
        break;
      case SubscriptionTier.sovereignElite:
        await prefs.setString(_tierKey(residentId), 'sovereign_elite');
        break;
      case SubscriptionTier.resident:
        await prefs.setString(_tierKey(residentId), 'resident');
        break;
    }
  }

  /// Returns benefits for a tier.
  static Map<String, dynamic> getBenefits(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.resident:
        return {
          'label': 'Resident',
          'color': AppColors.inkSecondary,
          'worldLimit': 3,
          'streakShieldsPerMonth': 0,
          'priorityVerification': false,
          'goldName': false,
          'customBackground': false,
          'analytics': false,
          'badgeLabel': '',
        };
      case SubscriptionTier.patrician:
        return {
          'label': 'Patrician',
          'color': AppColors.tertiary,
          'worldLimit': 10,
          'streakShieldsPerMonth': 1,
          'priorityVerification': true,
          'goldName': false,
          'customBackground': false,
          'analytics': false,
          'badgeLabel': 'PATRICIAN',
        };
      case SubscriptionTier.sovereignElite:
        return {
          'label': 'Sovereign Elite',
          'color': AppColors.tertiary,
          'worldLimit': 999,
          'streakShieldsPerMonth': 3,
          'priorityVerification': true,
          'goldName': true,
          'customBackground': true,
          'analytics': true,
          'badgeLabel': 'SOVEREIGN ELITE',
        };
    }
  }
}
