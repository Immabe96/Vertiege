import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/notification.dart';

void main() {
  group('AppNotification.toSupabase', () {
    test('includes created_at in output', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final notification = AppNotification(
        id: 'n1',
        type: NotificationType.welcome,
        message: 'Welcome!',
        createdAt: now,
      );

      final data = notification.toSupabase('r1');

      expect(data['created_at'], isNotNull);
      expect(data['created_at'], isA<String>());
    });

    test('round-trips type correctly through fromSupabase', () {
      final now = DateTime.now().toIso8601String();
      final data = <String, dynamic>{
        'id': 'n1',
        'type': 'like',
        'message': 'Someone liked your post',
        'world_id': 'w1',
        'post_id': 'p1',
        'read': false,
        'created_at': now,
      };

      final notification = AppNotification.fromSupabase(data);

      expect(notification.type, NotificationType.like);
      expect(notification.message, 'Someone liked your post');
      expect(notification.createdAt, greaterThan(0));
    });
  });
}
