import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/router/world_route_redirects.dart';

void main() {
  group('redirectReservedWorldSubRoute', () {
    for (final segment in kReservedWorldSubRoutes) {
      test('reserved segment "$segment" redirects to static route', () {
        expect(
          redirectReservedWorldSubRoute(
            worldId: 'neon-district',
            segment: segment,
            query: 'admin=true',
          ),
          '/explore/neon-district/$segment?admin=true',
        );
      });
    }

    test('channel names pass through without redirect', () {
      expect(
        redirectReservedWorldSubRoute(
          worldId: 'neon-district',
          segment: 'general',
          query: 'id=ch-1',
        ),
        isNull,
      );
    });

    test('announcements channel name is not treated as reserved', () {
      expect(
        redirectReservedWorldSubRoute(
          worldId: 'neon-district',
          segment: 'announcements',
          query: 'id=ch-2',
        ),
        isNull,
      );
    });
  });

  group('redirectMissingChannelId', () {
    test('missing id redirects to world explore root', () {
      expect(
        redirectMissingChannelId(
          worldId: 'neon-district',
          channelName: 'general',
          queryParams: const {},
        ),
        '/explore/neon-district',
      );
    });

    test('present id does not redirect', () {
      expect(
        redirectMissingChannelId(
          worldId: 'neon-district',
          channelName: 'general',
          queryParams: const {'id': 'ch-1'},
        ),
        isNull,
      );
    });
  });
}
