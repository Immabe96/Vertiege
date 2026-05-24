import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/channel.dart';
import 'package:vertiege/widgets/worlds/world_feed_chat_teaser.dart';

void main() {
  test('worldFeedChatExplorePath includes general channel id', () {
    const channel = WorldChannel(
      id: 'ch-general',
      worldId: 'neon-district',
      name: 'general',
    );
    expect(
      worldFeedChatExplorePath('neon-district', channel),
      '/explore/neon-district/general?id=ch-general',
    );
  });
}
