class WorldTreasury {
  final String id;
  final String worldId;
  final int balance;
  final int totalDonated;
  final int totalSpent;

  const WorldTreasury({
    required this.id,
    required this.worldId,
    this.balance = 0,
    this.totalDonated = 0,
    this.totalSpent = 0,
  });

  static WorldTreasury fromSupabase(Map<String, dynamic> data) => WorldTreasury(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    balance: (data['balance'] as num?)?.toInt() ?? 0,
    totalDonated: (data['total_donated'] as num?)?.toInt() ?? 0,
    totalSpent: (data['total_spent'] as num?)?.toInt() ?? 0,
  );
}

enum TreasuryTransactionType { donation, withdrawal, tax, reward, refund }

class TreasuryTransaction {
  final String id;
  final String worldId;
  final String userId;
  final TreasuryTransactionType transactionType;
  final int amount;
  final String description;
  final DateTime createdAt;

  const TreasuryTransaction({
    required this.id,
    required this.worldId,
    required this.userId,
    required this.transactionType,
    required this.amount,
    this.description = '',
    required this.createdAt,
  });

  static TreasuryTransaction fromSupabase(Map<String, dynamic> data) => TreasuryTransaction(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    userId: data['user_id'] ?? '',
    transactionType: _parseType(data['transaction_type']),
    amount: (data['amount'] as num?)?.toInt() ?? 0,
    description: data['description'] ?? '',
    createdAt: _parseDate(data['created_at']),
  );

  static TreasuryTransactionType _parseType(String? raw) {
    return TreasuryTransactionType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => TreasuryTransactionType.donation,
    );
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
