import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/router/world_route_redirects.dart';

void main() {
  test('reserved segments redirect to static world routes', () {
    expect(
      redirectReservedWorldSubRoute(
        worldId: 'neon-district',
        segment: 'members',
        query: 'name=Neon&sovereign=abc',
      ),
      '/explore/neon-district/members?name=Neon&sovereign=abc',
    );
  });

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
}
