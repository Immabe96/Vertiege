import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/rate_limiter.dart';

void main() {
  setUp(RateLimiter.clear);

  group('RateLimiter', () {
    test('canProceed allows calls up to maxCalls', () {
      const key = 'test_key_1';

      // Allow 3 calls
      expect(RateLimiter.canProceed(key, maxCalls: 3), isTrue);
      expect(RateLimiter.canProceed(key, maxCalls: 3), isTrue);
      expect(RateLimiter.canProceed(key, maxCalls: 3), isTrue);

      // 4th call should be blocked
      expect(RateLimiter.canProceed(key, maxCalls: 3), isFalse);
    });

    test('canProceed blocks calls exceeding maxCalls', () {
      const key = 'test_key_2';

      // 1 allowed
      expect(RateLimiter.canProceed(key, maxCalls: 1), isTrue);

      // Next 2 blocked
      expect(RateLimiter.canProceed(key, maxCalls: 1), isFalse);
      expect(RateLimiter.canProceed(key, maxCalls: 1), isFalse);
    });

    test('canProceed allows calls after windowMs expires', () async {
      const key = 'test_key_3';
      const windowMs = 50; // Small window for testing

      // Exhaust limits
      expect(RateLimiter.canProceed(key, windowMs: windowMs, maxCalls: 2), isTrue);
      expect(RateLimiter.canProceed(key, windowMs: windowMs, maxCalls: 2), isTrue);
      expect(RateLimiter.canProceed(key, windowMs: windowMs, maxCalls: 2), isFalse);

      // Wait for window to expire
      await Future.delayed(const Duration(milliseconds: 60));

      // Should be allowed again
      expect(RateLimiter.canProceed(key, windowMs: windowMs, maxCalls: 2), isTrue);
    });

    test('canProceed tracks different keys independently', () {
      const key1 = 'key_indep_1';
      const key2 = 'key_indep_2';

      // Exhaust limit for key1
      expect(RateLimiter.canProceed(key1, maxCalls: 1), isTrue);
      expect(RateLimiter.canProceed(key1, maxCalls: 1), isFalse);

      // key2 should still be allowed
      expect(RateLimiter.canProceed(key2, maxCalls: 1), isTrue);
      expect(RateLimiter.canProceed(key2, maxCalls: 1), isFalse);
    });

    test('clear resets the state completely', () {
      const key = 'test_key_clear';

      // Exhaust limit
      expect(RateLimiter.canProceed(key, maxCalls: 1), isTrue);
      expect(RateLimiter.canProceed(key, maxCalls: 1), isFalse);

      // Clear state
      RateLimiter.clear();

      // Should be allowed again
      expect(RateLimiter.canProceed(key, maxCalls: 1), isTrue);
    });

    test('setLimit executes without error', () {
      const key = 'test_key_limit';

      expect(() => RateLimiter.setLimit(key, 10), returnsNormally);
    });
  });
}
