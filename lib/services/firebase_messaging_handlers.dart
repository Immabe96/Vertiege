import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    FirebaseCrashlytics.instance.log(
      'background_fcm:${message.messageId ?? "unknown"}',
    );
  } catch (error, stackTrace) {
    debugPrint('Background FCM handler failed: $error');
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'background FCM handler',
        fatal: false,
      );
    } catch (_) {}
  }
}

String? routeFromRemoteMessage(RemoteMessage message) {
  final data = message.data;
  final explicitRoute = data['route'] ?? data['deeplink'];
  if (explicitRoute is String && explicitRoute.startsWith('/')) {
    return explicitRoute;
  }

  final notificationId = data['notification_id'] ?? data['notificationId'];
  if (notificationId is String && notificationId.isNotEmpty) {
    return '/notifications/$notificationId';
  }

  final postId = data['post_id'] ?? data['postId'];
  if (postId is String && postId.isNotEmpty) {
    return '/post/$postId';
  }

  final roomId = data['room_id'] ?? data['roomId'] ?? data['dm_room_id'];
  if (roomId is String && roomId.isNotEmpty) {
    return '/dm/$roomId';
  }

  final channelId = data['channel_id'] ?? data['channelId'];
  if (channelId is String && channelId.isNotEmpty) {
    return '/campfire/$channelId';
  }

  final worldId = data['world_id'] ?? data['worldId'];
  if (worldId is String && worldId.isNotEmpty) {
    return '/explore/$worldId';
  }

  return null;
}
