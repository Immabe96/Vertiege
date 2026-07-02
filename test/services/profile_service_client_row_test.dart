import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/resident.dart';
import 'package:vertiege/services/profile_service.dart';

void main() {
  test('client profile row omits tier and sovereign_coins', () {
    final resident = const Resident(
      id: 'u1',
      name: 'Test',
      tier: ResidentTier.apex,
      sovereignCoins: 99999,
      gateCompleted: true,
    );

    final row = ProfileService.clientWritableProfileRow(resident);
    expect(row.containsKey('tier'), isFalse);
    expect(row.containsKey('sovereign_coins'), isFalse);
    expect(row.containsKey('streak_count'), isFalse);
    expect(row.containsKey('last_check_in'), isFalse);
    expect(row.containsKey('total_xp'), isFalse);
    expect(row['id'], 'u1');
    expect(row['gate_completed'], isTrue);
  });
}
