import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/firebase_messaging_handlers.dart';

RemoteMessage messageWith(Map<String, dynamic> data) =>
    RemoteMessage(data: data);

void main() {
  test('uses explicit route when present', () {
    expect(
      routeFromRemoteMessage(messageWith({'route': '/notifications'})),
      '/notifications',
    );
  });

  test('uses deeplink when route is absent', () {
    expect(
      routeFromRemoteMessage(messageWith({'deeplink': '/notifications/n1'})),
      '/notifications/n1',
    );
  });

  test('maps notification id to notification route', () {
    expect(
      routeFromRemoteMessage(messageWith({'notification_id': 'n1'})),
      '/notifications/n1',
    );
  });

  test('maps post id to post route', () {
    expect(routeFromRemoteMessage(messageWith({'post_id': 'p1'})), '/post/p1');
  });

  test('maps channel id to campfire route', () {
    expect(
      routeFromRemoteMessage(messageWith({'channel_id': 'c1'})),
      '/campfire/c1',
    );
  });

  test('maps world id to world route', () {
    expect(
      routeFromRemoteMessage(messageWith({'world_id': 'w1'})),
      '/explore/w1',
    );
  });

  test('returns null when data has no route target', () {
    expect(routeFromRemoteMessage(messageWith({'kind': 'unknown'})), isNull);
  });
}
