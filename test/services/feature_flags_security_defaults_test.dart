import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/feature_flags.dart';

void main() {
  test('receiptEdgeVerify defaults fail-closed when RC unavailable', () {
    // Without Firebase Remote Config initialized, fallback must be true.
    expect(FeatureFlags.receiptEdgeVerify, isTrue);
  });

  test('contentModerationRemote defaults on when RC unavailable', () {
    expect(FeatureFlags.contentModerationRemote, isTrue);
  });
}
