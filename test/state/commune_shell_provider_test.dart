import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/state/commune_shell_provider.dart';

void main() {
  group('communeImmersivePath', () {
    test('hides nav in world channel', () {
      expect(
        communeImmersivePath('/explore/world-1/general'),
        isTrue,
      );
    });

    test('shows nav on world settings', () {
      expect(
        communeImmersivePath('/explore/world-1/settings'),
        isFalse,
      );
    });

    test('hides nav in dm and chat room', () {
      expect(communeImmersivePath('/dm/room-1'), isTrue);
      expect(communeImmersivePath('/chat/room-1'), isTrue);
    });

    test('hides nav in campfire', () {
      expect(communeImmersivePath('/campfire/ch-1'), isTrue);
    });

    test('shows nav on home', () {
      expect(communeImmersivePath('/'), isFalse);
      expect(communeImmersivePath('/you'), isFalse);
    });
  });
}
