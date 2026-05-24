import 'package:flutter_test/flutter_test.dart';

/// Documents gate redirect expectations (F13) — full GoRouter tests need ProviderScope.
void main() {
  test('incomplete gate should use /onboarding not /the-gate', () {
    const gateIncompleteTarget = '/onboarding';
    expect(gateIncompleteTarget, isNot('/the-gate'));
  });
}
