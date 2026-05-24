import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/resident.dart';
import 'package:vertiege/utils/gamification_reconcile.dart';

void main() {
  test('applyServerGamification overwrites server-managed fields', () {
    const local = Resident(
      id: 'u1',
      name: 'Local',
      totalXp: 100,
      streakCount: 1,
      sovereignCoins: 50,
      bio: 'local bio',
    );
    const server = Resident(
      id: 'u1',
      name: 'Server',
      totalXp: 500,
      tier: ResidentTier.highRollers,
      streakCount: 7,
      sovereignCoins: 200,
      bio: 'server bio',
    );

    final merged = applyServerGamification(local, server);
    expect(merged.bio, 'local bio');
    expect(merged.name, 'Local');
    expect(merged.totalXp, 500);
    expect(merged.tier, ResidentTier.highRollers);
    expect(merged.streakCount, 7);
    expect(merged.sovereignCoins, 200);
  });
}
