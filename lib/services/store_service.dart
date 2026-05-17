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

class StoreService {
  static const wealthTierPrefix = 'wealth_access_tier_';
  static const worldBoostId = 'world_boost';

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
      final allIds = [...wealthTierProducts.values, worldBoostId];
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
  static Future<StorePurchaseState> buyWealthTier(int tier) async {
    if (!isEnabled) return StorePurchaseState.disabled;
    final productId = wealthTierProducts[tier];
    if (productId == null) return StorePurchaseState.error;

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
    if (!isEnabled) return StorePurchaseState.disabled;

    try {
      final response = await _store.queryProductDetails({worldBoostId}.toSet());
      if (response.productDetails.isEmpty) return StorePurchaseState.error;

      final completer = Completer<StorePurchaseState>();
      _pendingPurchases[worldBoostId] = completer;

      await _store.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: response.productDetails.first,
        ),
      );

      return completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingPurchases.remove(worldBoostId);
          return StorePurchaseState.error;
        },
      );
    } catch (_) {
      _pendingPurchases.remove(worldBoostId);
      return StorePurchaseState.error;
    }
  }

  /// Restore previous purchases from the store.
  static Future<void> restorePurchases() async {
    if (!isEnabled) return;
    await _store.restorePurchases();
  }

  static void _onPurchaseUpdate(List<PurchaseDetails> details) {
    for (final purchase in details) {
      final completer = _pendingPurchases[purchase.productID];
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
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
      id: '${wealthTierPrefix}2',
      title: 'High Roller Access',
      description: 'Unlock tier 2 wealth worlds',
      price: '\$4.99',
    ),
    const StoreProduct(
      id: '${wealthTierPrefix}3',
      title: 'Elite Access',
      description: 'Unlock tier 3 wealth worlds',
      price: '\$9.99',
    ),
    const StoreProduct(
      id: '${wealthTierPrefix}4',
      title: 'Old Money Access',
      description: 'Unlock tier 4 wealth worlds',
      price: '\$19.99',
    ),
    const StoreProduct(
      id: '${wealthTierPrefix}5',
      title: 'Apex Access',
      description: 'Unlock tier 5 wealth worlds',
      price: '\$49.99',
    ),
    const StoreProduct(
      id: worldBoostId,
      title: 'World Boost',
      description: '+1 level to your custom world (monthly limit)',
      price: '\$4.99',
    ),
  ];
}
