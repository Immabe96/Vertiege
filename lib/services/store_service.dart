import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class StoreProduct {
  final String id;
  final String title;
  final String description;
  final String price;

  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });
}

enum StorePurchaseState { idle, loading, purchased, error, disabled }

class RestoredSubscriptionPurchase {
  final String productId;
  final String purchaseToken;
  final String? storePayload;

  const RestoredSubscriptionPurchase({
    required this.productId,
    required this.purchaseToken,
    this.storePayload,
  });
}

class StoreService {
  /// Legacy pay-to-win SKUs — not offered in v1 (PLAN.md Wave 9).
  static const wealthTierPrefix = 'wealth_access_tier_';
  static const worldBoostId = 'world_boost';
  static const patricianSubscriptionId = 'subscription_patrician';
  static const sovereignEliteSubscriptionId = 'subscription_sovereign_elite';
  static const subscriptionProductIds = {
    patricianSubscriptionId,
    sovereignEliteSubscriptionId,
  };

  /// Product IDs for each wealth tier (2-5). Tier 1 is free.
  static const wealthTierProducts = {
    2: '${wealthTierPrefix}2',
    3: '${wealthTierPrefix}3',
    4: '${wealthTierPrefix}4',
    5: '${wealthTierPrefix}5',
  };

  static final _store = InAppPurchase.instance;
  static bool _initialized = false;
  static bool _available = false;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  static final Map<String, Completer<StorePurchaseState>> _pendingPurchases = {};
  static Completer<void>? _restoreSync;
  static Timer? _restoreDebounce;
  static String? lastPurchaseToken;
  static String? lastStoreVerificationPayload;
  static String? lastPurchasedProductId;

  /// Subscription restores collected during [restorePurchasesAndWait].
  static final List<RestoredSubscriptionPurchase> restoredSubscriptions = [];

  /// Whether the store is available on this device.
  static bool get isEnabled => _available;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _available = await _store.isAvailable();
    if (!_available) return;

    _purchaseSub = _store.purchaseStream.listen(_onPurchaseUpdate);
  }

  static void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
  }

  /// Load product details from the store.
  static Future<List<StoreProduct>> loadProducts() async {
    if (!isEnabled) return _fallbackProducts();

    try {
      final allIds = [...subscriptionProductIds];
      final response = await _store.queryProductDetails(allIds.toSet());
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Store: not found: ${response.notFoundIDs}');
      }
      return response.productDetails
          .map(
            (p) => StoreProduct(
              id: p.id,
              title: p.title,
              description: p.description,
              price: p.price,
            ),
          )
          .toList();
    } catch (_) {
      return _fallbackProducts();
    }
  }

  /// Purchase access to a wealth tier.
  @Deprecated('Paid world access is disabled for v1; use achievements for tier.')
  static Future<StorePurchaseState> buyWealthTier(int tier) async {
    return StorePurchaseState.disabled;
  }

  static Future<StorePurchaseState> buyProduct(String productId) async {
    if (!isEnabled) return StorePurchaseState.disabled;
    if (!subscriptionProductIds.contains(productId)) {
      return StorePurchaseState.error;
    }

    try {
      final response = await _store.queryProductDetails({productId}.toSet());
      if (response.productDetails.isEmpty) return StorePurchaseState.error;

      final completer = Completer<StorePurchaseState>();
      _pendingPurchases[productId] = completer;

      await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: response.productDetails.first,
        ),
      );

      return completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingPurchases.remove(productId);
          return StorePurchaseState.error;
        },
      );
    } catch (_) {
      _pendingPurchases.remove(productId);
      return StorePurchaseState.error;
    }
  }

  /// Purchase a world boost (consumable, +1 level to a custom world).
  static Future<StorePurchaseState> buyWorldBoost() async {
    return StorePurchaseState.disabled;
  }

  /// Restore previous purchases from the store.
  static Future<void> restorePurchases() async {
    if (!isEnabled) return;
    await _store.restorePurchases();
  }

  /// Restores purchases and waits briefly for subscription events on the stream.
  static Future<List<RestoredSubscriptionPurchase>> restorePurchasesAndWait() async {
    if (!isEnabled) return [];
    restoredSubscriptions.clear();
    _restoreSync = Completer<void>();
    await _store.restorePurchases();
    _restoreDebounce?.cancel();
    _restoreDebounce = Timer(const Duration(milliseconds: 800), () {
      if (_restoreSync != null && !_restoreSync!.isCompleted) {
        _restoreSync!.complete();
      }
    });
    try {
      await _restoreSync!.future.timeout(const Duration(seconds: 12));
    } catch (_) {
      // Store may return no active subscriptions.
    } finally {
      _restoreDebounce?.cancel();
      _restoreDebounce = null;
      _restoreSync = null;
    }
    return List<RestoredSubscriptionPurchase>.from(restoredSubscriptions);
  }

  static void _recordSubscriptionPurchase(PurchaseDetails purchase) {
    final token = purchase.purchaseID ??
        purchase.verificationData.serverVerificationData;
    if (token.isEmpty) return;
    lastStoreVerificationPayload =
        purchase.verificationData.serverVerificationData;
    lastPurchaseToken = token;
    lastPurchasedProductId = purchase.productID;
    restoredSubscriptions.add(
      RestoredSubscriptionPurchase(
        productId: purchase.productID,
        purchaseToken: token,
        storePayload: purchase.verificationData.serverVerificationData,
      ),
    );
    _restoreDebounce?.cancel();
    _restoreDebounce = Timer(const Duration(milliseconds: 600), () {
      if (_restoreSync != null && !_restoreSync!.isCompleted) {
        _restoreSync!.complete();
      }
    });
  }

  static void _onPurchaseUpdate(List<PurchaseDetails> details) {
    for (final purchase in details) {
      final completer = _pendingPurchases[purchase.productID];
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (subscriptionProductIds.contains(purchase.productID)) {
          if (_restoreSync != null) {
            _recordSubscriptionPurchase(purchase);
          } else {
            lastStoreVerificationPayload =
                purchase.verificationData.serverVerificationData;
            lastPurchaseToken = purchase.purchaseID ??
                purchase.verificationData.serverVerificationData;
            lastPurchasedProductId = purchase.productID;
          }
        } else {
          lastStoreVerificationPayload =
              purchase.verificationData.serverVerificationData;
          lastPurchaseToken = purchase.purchaseID ??
              purchase.verificationData.serverVerificationData;
          lastPurchasedProductId = purchase.productID;
        }
        InAppPurchase.instance.completePurchase(purchase);
        completer?.complete(StorePurchaseState.purchased);
        _pendingPurchases.remove(purchase.productID);
      } else if (purchase.status == PurchaseStatus.error) {
        completer?.complete(StorePurchaseState.error);
        _pendingPurchases.remove(purchase.productID);
      } else if (purchase.status == PurchaseStatus.canceled) {
        completer?.complete(StorePurchaseState.error);
        _pendingPurchases.remove(purchase.productID);
      }
    }
  }

  /// Fallback product info shown during development.
  static List<StoreProduct> _fallbackProducts() => [
    const StoreProduct(
      id: patricianSubscriptionId,
      title: 'Patrician',
      description: 'Cosmetic profile perks and convenience tools',
      price: '\$4.99',
    ),
    const StoreProduct(
      id: sovereignEliteSubscriptionId,
      title: 'Sovereign Elite',
      description: 'Premium cosmetics, profile analytics, and draft tools',
      price: '\$14.99',
    ),
  ];
}
