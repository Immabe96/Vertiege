import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/app_failure.dart';
import 'package:vertiege/utils/provider_errors.dart';

void main() {
  test('userFacingLoadError returns AppFailure message', () {
    expect(
      userFacingLoadError(AppFailure.network()),
      'No internet connection',
    );
  });

  test('userFacingLoadError maps network exceptions', () {
    expect(
      userFacingLoadError(Exception('SocketException: failed host lookup')),
      contains('connection'),
    );
  });

  test('userFacingLoadError uses fallback for unknown errors', () {
    expect(
      userFacingLoadError(
        Exception('weird'),
        fallback: 'Custom fallback',
      ),
      'Custom fallback',
    );
  });
}
