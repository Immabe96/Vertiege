import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/channel.dart';
import 'package:vertiege/services/favorite_channel_prefs.dart';

WorldChannel _ch(String id, String name) => WorldChannel(
  id: id,
  worldId: 'w1',
  name: name,
);

void main() {
  group('sortChannelsWithFavorites', () {
    test('pins favorites first preserving relative order', () {
      final sorted = sortChannelsWithFavorites(
        channels: [_ch('a', 'alpha'), _ch('b', 'beta'), _ch('c', 'charlie')],
        favoriteIds: {'c', 'a'},
        idFor: (c) => c.id,
      );

      expect(sorted.map((c) => c.id).toList(), ['a', 'c', 'b']);
    });

    test('sorts non-favorites when comparator provided', () {
      final sorted = sortChannelsWithFavorites(
        channels: [_ch('z', 'zulu'), _ch('b', 'bravo')],
        favoriteIds: {},
        idFor: (c) => c.id,
        compareNonFavorite: (a, b) => a.name.compareTo(b.name),
      );

      expect(sorted.map((c) => c.id).toList(), ['b', 'z']);
    });
  });
}
