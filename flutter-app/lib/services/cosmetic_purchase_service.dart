import 'supabase.dart';

class CosmeticPurchaseService {
  static Future<String?> purchaseWithCoins({
    required String cosmeticId,
    required int coinPrice,
  }) async {
    if (!isSupabaseConfigured()) {
      return 'Sign in to purchase cosmetics.';
    }
    final client = getSupabase();
    final result = await client.rpc(
      'purchase_cosmetic_with_coins',
      params: {
        'p_cosmetic_id': cosmeticId,
        'p_coin_price': coinPrice,
      },
    );
    if (result is! Map) return 'Unexpected response';
    final map = Map<String, dynamic>.from(result);
    if (map['success'] == true) return null;
    return map['error'] as String? ?? 'Purchase failed';
  }

  static Future<String?> equip({
    required String slot,
    String? cosmeticId,
  }) async {
    if (!isSupabaseConfigured()) return 'Sign in to equip cosmetics.';
    final client = getSupabase();
    final result = await client.rpc(
      'equip_cosmetic',
      params: {
        'p_slot': slot,
        'p_cosmetic_id': cosmeticId ?? '',
      },
    );
    if (result is! Map) return 'Unexpected response';
    final map = Map<String, dynamic>.from(result);
    if (map['success'] == true) return null;
    return map['error'] as String? ?? 'Could not equip';
  }

  static Future<Set<String>> ownedCosmeticIds(String userId) async {
    if (!isSupabaseConfigured()) return {};
    final client = getSupabase();
    final data = await client
        .from('user_cosmetic_grants')
        .select('cosmetic_id')
        .eq('user_id', userId);
    return (data as List)
        .map((e) => (e as Map<String, dynamic>)['cosmetic_id'] as String)
        .toSet();
  }
}
