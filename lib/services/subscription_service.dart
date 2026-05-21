import '../services/supabase.dart';
import '../theme/v_colors.dart';

enum SubscriptionTier { resident, patrician, sovereignElite }

class SubscriptionService {
  static const patricianProductId = 'subscription_patrician';
  static const sovereignEliteProductId = 'subscription_sovereign_elite';

  static SubscriptionTier? _cachedTier;
  static String? _cachedUserId;

  /// Verifies subscription tier from Supabase (server-side).
  /// Caches result in memory only — never persists to SharedPreferences.
  static Future<SubscriptionTier> verifySubscription(String userId) async {
    if (_cachedUserId == userId && _cachedTier != null) {
      return _cachedTier!;
    }

    try {
      final client = maybeSupabase();
      if (client == null) {
        _cachedTier = SubscriptionTier.resident;
        _cachedUserId = userId;
        return _cachedTier!;
      }

      final response = await client
          .from('profiles')
          .select('subscription_tier')
          .eq('id', userId)
          .single();

      final tierStr = response['subscription_tier'] as String?;
      final tier = _parseTier(tierStr);
      _cachedTier = tier;
      _cachedUserId = userId;
      return tier;
    } catch (_) {
      _cachedTier = SubscriptionTier.resident;
      _cachedUserId = userId;
      return _cachedTier!;
    }
  }

  /// Returns the cached tier if available, otherwise verifies from Supabase.
  static Future<SubscriptionTier> getTier(String userId) async {
    if (_cachedUserId == userId && _cachedTier != null) {
      return _cachedTier!;
    }
    return verifySubscription(userId);
  }

  /// Clears the in-memory cache (e.g., on logout).
  static void clearCache() {
    _cachedTier = null;
    _cachedUserId = null;
  }

  /// No-op: subscription tier must be set server-side via Supabase.
  /// This method exists for backward compatibility.
  static Future<void> setTier(String userId, SubscriptionTier tier) async {
    // Tier is managed server-side. Call verifySubscription() to refresh.
    _cachedTier = null;
    _cachedUserId = null;
  }

  static SubscriptionTier _parseTier(String? value) {
    switch (value) {
      case 'patrician':
        return SubscriptionTier.patrician;
      case 'sovereign_elite':
        return SubscriptionTier.sovereignElite;
      default:
        return SubscriptionTier.resident;
    }
  }

  /// Returns benefits for a tier.
  static Map<String, dynamic> getBenefits(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.resident:
        return {
          'label': 'Resident',
          'color': VColors.onSurfaceVariant,
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
          'color': VColors.tertiary,
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
          'color': VColors.tertiary,
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
