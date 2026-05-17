import 'package:flutter/foundation.dart';
import '../models/treasury.dart';
import 'supabase.dart';

class TreasuryService {
  static Future<WorldTreasury?> getTreasury(String worldId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('world_treasury')
        .select()
        .eq('world_id', worldId)
        .maybeSingle();
    if (data == null) return null;
    return WorldTreasury.fromSupabase(data);
  }

  static Future<WorldTreasury?> initializeTreasury(String worldId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final result = await client
        .from('world_treasury')
        .insert({'world_id': worldId, 'balance': 0, 'total_donated': 0, 'total_spent': 0})
        .select()
        .single();
    return WorldTreasury.fromSupabase(result);
  }

  static Future<List<TreasuryTransaction>> getTransactions(
    String worldId, {
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('treasury_transactions')
        .select()
        .eq('world_id', worldId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => TreasuryTransaction.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> donate(String worldId, int amount, String description) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    try {
      await client.rpc('donate_to_treasury', params: {
        'p_world_id': worldId,
        'p_amount': amount,
        'p_description': description,
      });
      return true;
    } catch (e) {
      debugPrint('TreasuryService.donate error: $e');
      return false;
    }
  }

  static Future<bool> withdraw(String worldId, int amount, String description) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    try {
      await client.rpc('withdraw_from_treasury', params: {
        'p_world_id': worldId,
        'p_amount': amount,
        'p_description': description,
      });
      return true;
    } catch (e) {
      debugPrint('TreasuryService.withdraw error: $e');
      return false;
    }
  }
}
