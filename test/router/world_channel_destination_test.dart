import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/channel.dart';
import 'package:vertiege/router/world_navigation.dart';

void main() {
  group('worldChannelDestinationPath', () {
    test('routes voice channels to Campfire', () {
      final channel = WorldChannel(
        id: 'w-campfire',
        worldId: 'w1',
        name: 'campfire',
        channelType: ChannelType.voice,
      );
      final path = worldChannelDestinationPath(
        'w1',
        channel,
        worldName: 'Aurelia',
      );
      expect(path, startsWith('/campfire/w-campfire'));
      expect(path, contains('name=campfire'));
      expect(path, contains('worldId=w1'));
      expect(path, contains('worldName=Aurelia'));
    });

    test('routes text channels to world channel screen', () {
      final channel = WorldChannel(
        id: 'w-lounge',
        worldId: 'w1',
        name: 'lounge',
        channelType: ChannelType.text,
      );
      final path = worldChannelDestinationPath('w1', channel);
      expect(path, startsWith('/explore/w1/lounge'));
      expect(path, contains('id=w-lounge'));
    });
  });
}
