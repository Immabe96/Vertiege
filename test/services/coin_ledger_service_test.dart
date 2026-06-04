import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/coin_ledger_service.dart';

void main() {
  test('CoinTransaction parses ledger row', () {
    final tx = CoinTransaction.fromJson({
      'id': 'tx-1',
      'amount': 25,
      'reason': 'daily_bonus',
      'balance_after': 125,
      'created_at': '2026-05-30T12:00:00.000Z',
    });
    expect(tx.amount, 25);
    expect(tx.reason, 'daily_bonus');
    expect(tx.balanceAfter, 125);
  });
}
