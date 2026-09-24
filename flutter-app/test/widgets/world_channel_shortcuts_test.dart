import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/channel.dart';
import 'package:vertiege/router/world_navigation.dart';

void main() {
  test('worldChannelExplorePath includes channel id query param', () {
    const channel = WorldChannel(
      id: 'ch-general',
      worldId: 'neon-district',
      name: 'general',
    );
    expect(
      worldChannelExplorePath('neon-district', channel),
      '/explore/neon-district/general?id=ch-general',
    );
  });

  test('announcement channel path preserves name and id', () {
    const channel = WorldChannel(
      id: 'ch-ann',
      worldId: 'neon-district',
      name: 'announcements',
      channelType: ChannelType.announcement,
    );
    expect(
      worldChannelExplorePath('neon-district', channel),
      '/explore/neon-district/announcements?id=ch-ann',
    );
  });
}
