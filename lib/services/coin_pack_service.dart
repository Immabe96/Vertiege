import 'supabase.dart';

/// Consumable coin pack verification (Wave 19).
class CoinPackService {
  CoinPackService._();

  static const starterId = 'coin_pack_starter';
  static const valueId = 'coin_pack_value';
  static const eliteId = 'coin_pack_elite';

  static const productIds = {starterId, valueId, eliteId};

  static int coinsForProduct(String productId) => switch (productId) {
        starterId => 100,
        valueId => 550,
        eliteId => 1200,
        _ => 0,
      };

  static Future<({bool success, int? balance, String? error})> grantPurchase({
    required String productId,
    required String purchaseToken,
    String? platform,
  }) async {
    if (!isSupabaseConfigured()) {
      return (success: false, balance: null, error: 'Sign in to complete purchase.');
    }
    final raw = await getSupabase().rpc(
      'grant_coin_pack_purchase',
      params: {
        'p_product_id': productId,
        'p_purchase_token': purchaseToken,
        'p_platform': platform ?? 'unknown',
      },
    );
    if (raw is! Map) {
      return (success: false, balance: null, error: 'Unexpected response');
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['success'] == true) {
      return (
        success: true,
        balance: (map['balance'] as num?)?.toInt(),
        error: null,
      );
    }
    return (
      success: false,
      balance: null,
      error: map['error'] as String? ?? 'Purchase failed',
    );
  }
}
