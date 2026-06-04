import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/subscription_service.dart';

void main() {
  test('userFacingPurchaseError maps already redeemed', () {
    expect(
      SubscriptionService.userFacingPurchaseError('Purchase already redeemed'),
      contains('already linked'),
    );
  });

  test('userFacingPurchaseError passes through unknown errors', () {
    expect(
      SubscriptionService.userFacingPurchaseError('Network timeout'),
      'Network timeout',
    );
  });
}
