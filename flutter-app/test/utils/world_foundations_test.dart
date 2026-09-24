import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/world.dart';
import 'package:vertiege/utils/world_foundations.dart';

World _world(String slug, WorldType type) => World(
      id: slug,
      slug: slug,
      name: slug,
      type: type,
      description: 'Test world',
      sovereignId: 'sovereign-1',
      sovereignName: 'Test',
      requiredTier: 1,
    );

void main() {
  test('preset wealth worlds include wealth safety disclaimer', () {
    for (final slug in ['neon-district', 'crystal-shore', 'azure-coast']) {
      final world = _world(slug, WorldType.wealth);
      final foundation = foundationForWorld(world);
      expect(
        foundation.safetyDisclaimer,
        contains('financial advice'),
        reason: slug,
      );
    }
  });

  test('regulated profession worlds include domain disclaimers', () {
    for (final slug in ['medical-nexus', 'legal-plaza', 'aviation-heights']) {
      final world = _world(slug, WorldType.profession);
      final foundation = foundationForWorld(world);
      expect(
        foundation.safetyDisclaimer,
        isNotNull,
        reason: slug,
      );
      expect(foundation.safetyDisclaimer!.trim(), isNotEmpty, reason: slug);
    }
  });

  test('unknown world slug gets default community disclaimer', () {
    final world = _world('custom-realm', WorldType.dominion);
    final foundation = foundationForWorld(world);
    expect(foundation.safetyDisclaimer, kCommunitySafetyDisclaimer);
  });
}
