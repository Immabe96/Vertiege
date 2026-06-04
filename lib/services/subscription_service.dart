import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;

import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/feature_flags.dart';
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

  static String purchasePlatformKey() {
    if (kIsWeb) return 'unknown';
    if (!kIsWeb && Platform.isIOS) return 'ios';
    if (!kIsWeb && Platform.isAndroid) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'unknown';
  }

  /// Receipt-backed entitlement (Wave 9). [purchaseToken] from the store purchase.
  static Future<String?> verifyPurchase({
    required String productId,
    required String purchaseToken,
    String? storePayload,
    String? platform,
  }) async {
    final client = maybeSupabase();
    if (client == null) return 'Sign in to verify purchase.';

    final platformKey = platform ?? purchasePlatformKey();
    final Map<String, dynamic> map;

    if (FeatureFlags.receiptEdgeVerify) {
      final response = await client.functions.invoke(
        'verify-subscription-purchase',
        body: {
          'product_id': productId,
          'purchase_token': purchaseToken,
          'platform': platformKey,
          if (storePayload != null && storePayload.isNotEmpty)
            'store_payload': storePayload,
        },
      );
      if (response.status != 200) {
        final err = response.data;
        if (err is Map) {
          return err['error'] as String? ??
              'Receipt verification failed (${response.status})';
        }
        return 'Receipt verification failed (${response.status})';
      }
      if (response.data is! Map) return 'Unexpected response';
      map = Map<String, dynamic>.from(response.data as Map);
    } else {
      final result = await client.rpc(
        'verify_subscription_purchase',
        params: {
          'p_product_id': productId,
          'p_purchase_token': purchaseToken,
          'p_platform': platformKey,
          if (storePayload != null && storePayload.isNotEmpty)
            'p_store_payload': storePayload,
        },
      );
      if (result is! Map) return 'Unexpected response';
      map = Map<String, dynamic>.from(result);
    }

    if (map['success'] == true) {
      _cachedTier = null;
      _cachedUserId = null;
      unawaited(
        AnalyticsService.logEvent(
          AnalyticsEvents.subscriptionVerified,
          parameters: {'product_id': productId, 'platform': platformKey},
        ),
      );
      return null;
    }
    return map['error'] as String? ?? 'Verification failed';
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
          'extraCosmeticSlots': 0,
          'streakShieldsPerMonth': 0,
          'priorityReviewVisibility': false,
          'goldName': false,
          'customFrame': false,
          'analytics': false,
          'savedDrafts': 3,
          'badgeLabel': '',
        };
      case SubscriptionTier.patrician:
        return {
          'label': 'Patrician',
          'color': VColors.tertiary,
          'extraCosmeticSlots': 2,
          'streakShieldsPerMonth': 0,
          'priorityReviewVisibility': true,
          'goldName': false,
          'customFrame': true,
          'analytics': false,
          'savedDrafts': 10,
          'badgeLabel': 'PATRICIAN',
        };
      case SubscriptionTier.sovereignElite:
        return {
          'label': 'Sovereign Elite',
          'color': VColors.tertiary,
          'extraCosmeticSlots': 6,
          'streakShieldsPerMonth': 0,
          'priorityReviewVisibility': true,
          'goldName': true,
          'customFrame': true,
          'analytics': true,
          'savedDrafts': 25,
          'badgeLabel': 'SOVEREIGN ELITE',
        };
    }
  }
}
