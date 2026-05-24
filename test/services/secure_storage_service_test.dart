import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/secure_storage_service.dart';

void main() {
  test('clearLegacyAuthCredentials completes without throwing', () async {
    await expectLater(
      SecureStorageService.clearLegacyAuthCredentials(),
      completes,
    );
  });
}
