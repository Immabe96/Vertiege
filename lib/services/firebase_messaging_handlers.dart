import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../router/notification_navigation.dart';
import '../router/world_navigation.dart';
import 'local_notification_service.dart';

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
    await LocalNotificationService.ensureInitialized();
    final type = message.data['type']?.toString() ?? '';
    if (type == 'dmMessage' || message.notification == null) {
      await LocalNotificationService.showFromRemoteMessage(message);
    }
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

  final type = data['type']?.toString() ?? '';
  final worldId = data['world_id'] ?? data['worldId'];
  final postId = data['post_id'] ?? data['postId'];
  final roomId = data['room_id'] ?? data['roomId'] ?? data['dm_room_id'];

  if (type == 'dmMessage') {
    if (roomId is String && roomId.isNotEmpty) {
      return chatShellPath(roomId);
    }
    return '/chat';
  }

  if (type == 'achievementApproved' || type == 'achievementRejected') {
    return '/achievements';
  }

  if ((type == 'like' || type == 'comment') &&
      worldId is String &&
      worldId.isNotEmpty &&
      postId is String &&
      postId.isNotEmpty) {
    return exploreWorldPath(worldId, postId: postId);
  }

  final notificationId = data['notification_id'] ?? data['notificationId'];
  if (notificationId is String && notificationId.isNotEmpty) {
    return notificationDeepLinkPath(notificationId);
  }

  if (postId is String && postId.isNotEmpty) {
    return '/post/$postId';
  }

  if (roomId is String && roomId.isNotEmpty) {
    return chatShellPath(roomId);
  }

  final channelId = data['channel_id'] ?? data['channelId'];
  if (channelId is String && channelId.isNotEmpty) {
    return campfirePath(channelId: channelId);
  }

  if (worldId is String && worldId.isNotEmpty) {
    return exploreWorldPath(worldId);
  }

  return null;
}
