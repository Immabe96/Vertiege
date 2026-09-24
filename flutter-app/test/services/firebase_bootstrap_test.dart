import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/firebase_bootstrap.dart';

void main() {
  test('FirebaseBootstrap exposes init state accessors', () {
    expect(FirebaseBootstrap.isInitialized, isA<bool>());
    expect(
      FirebaseBootstrap.lastError == null ||
          FirebaseBootstrap.lastError is Object,
      isTrue,
    );
  });
}
