import 'supabase.dart';

class CoinTransaction {
  final String id;
  final int amount;
  final String reason;
  final int balanceAfter;
  final DateTime createdAt;

  const CoinTransaction({
    required this.id,
    required this.amount,
    required this.reason,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) =>
      CoinTransaction(
        id: json['id']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String? ?? '',
        balanceAfter: (json['balance_after'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

/// Append-only sovereign coin ledger (Wave 18).
class CoinLedgerService {
  CoinLedgerService._();

  static Future<int?> grant(int amount, {String reason = 'grant'}) async {
    if (!isSupabaseConfigured() || amount == 0) return null;
    final raw = await getSupabase().rpc(
      'grant_sovereign_coins',
      params: {'p_amount': amount, 'p_reason': reason},
    );
    return (raw as num?)?.toInt();
  }

  static Future<List<CoinTransaction>> listRecent({int limit = 20}) async {
    if (!isSupabaseConfigured()) return [];
    final uid = getSupabase().auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await getSupabase()
        .from('coin_transactions')
        .select()
        .eq('resident_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => CoinTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
