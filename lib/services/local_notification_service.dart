import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/world_navigation.dart';
import '../utils/id_generator.dart';
import 'chat_notification_scope.dart';
import 'chat_service.dart';
import 'firebase_messaging_handlers.dart';
import 'storage_service.dart';
import 'supabase.dart';
import 'supabase_bootstrap.dart';

const _kPrefPushEnabled = 'settings_push_enabled';
const _androidReplyActionId = 'dm_reply';
const _channelMessages = 'vertiege_messages';
const _channelGeneral = 'vertiege_notifications';

/// System notifications (Android shade / iOS banner) with DM inline reply.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static void Function(String route)? _onNavigate;

  static Future<void> ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  static Future<void> initialize({
    void Function(String route)? onNavigate,
  }) async {
    if (kIsWeb) return;
    _onNavigate = onNavigate;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationBackgroundResponse,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelMessages,
        'Messages',
        description: 'Direct message notifications',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelGeneral,
        'Vertiege',
        description: 'Likes, comments, and world updates',
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  static Future<bool> _pushEnabled() async {
    final value = await StorageService.getString(_kPrefPushEnabled);
    return value != 'false';
  }

  static Future<void> showFromRemoteMessage(RemoteMessage message) async {
    if (kIsWeb || !_initialized) return;
    if (!await _pushEnabled()) return;

    final data = message.data;
    final type = data['type']?.toString() ?? '';
    final roomId =
        data['room_id'] ?? data['roomId'] ?? data['dm_room_id'];
    if (type == 'dmMessage' &&
        roomId is String &&
        roomId.isNotEmpty &&
        ChatNotificationScope.shouldSuppressDm(roomId)) {
      return;
    }

    final title = message.notification?.title ??
        _titleForType(type, data['sender_name']?.toString());
    final body = message.notification?.body ??
        data['message']?.toString() ??
        data['body']?.toString() ??
        'New activity in Vertiege';

    final payload = jsonEncode(data);
    final isDm = type == 'dmMessage' && roomId is String && roomId.isNotEmpty;
    final channelId = isDm ? _channelMessages : _channelGeneral;

    final senderName = data['sender_name']?.toString() ?? 'Contact';
    final senderPerson = Person(name: senderName);
    final androidDetails = AndroidNotificationDetails(
      channelId,
      isDm ? 'Messages' : 'Vertiege',
      channelDescription: isDm
          ? 'Direct message notifications'
          : 'App notifications',
      importance: isDm ? Importance.high : Importance.defaultImportance,
      priority: isDm ? Priority.high : Priority.defaultPriority,
      category: isDm ? AndroidNotificationCategory.message : null,
      styleInformation: isDm
          ? MessagingStyleInformation(
              senderPerson,
              messages: [
                Message(body, DateTime.now(), senderPerson),
              ],
            )
          : null,
      actions: isDm
          ? [
              const AndroidNotificationAction(
                _androidReplyActionId,
                'Reply',
                inputs: [
                  AndroidNotificationActionInput(
                    label: 'Message',
                  ),
                ],
              ),
            ]
          : null,
      tag: isDm ? roomId : data['notification_id']?.toString(),
    );

    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = _notificationIdFor(data, message.messageId);
    await _plugin.show(id, title, body, details, payload: payload);
  }

  static int _notificationIdFor(Map<String, dynamic> data, String? messageId) {
    final raw = data['notification_id'] ??
        data['room_id'] ??
        messageId ??
        DateTime.now().millisecondsSinceEpoch.toString();
    return raw.hashCode.abs() % 2147483647;
  }

  static String _titleForType(String type, String? senderName) {
    return switch (type) {
      'dmMessage' => senderName ?? 'New message',
      'comment' => 'New comment',
      'like' => 'New reaction',
      'mention' => 'Mention',
      _ => 'Vertiege',
    };
  }

  static void _onNotificationResponse(NotificationResponse response) {
    unawaited(handleResponse(response));
  }

  /// Handles taps and inline replies (foreground + background isolate).
  static Future<void> handleResponse(
    NotificationResponse response,
  ) async {
    if (response.actionId == _androidReplyActionId) {
      await _handleInlineReply(response);
      return;
    }

    final route = _routeFromPayload(response.payload);
    if (route != null) {
      _onNavigate?.call(route);
    }
  }

  static Future<void> _handleInlineReply(NotificationResponse response) async {
    final text = response.input?.trim();
    if (text == null || text.isEmpty) return;

    Map<String, dynamic> data = {};
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        data = jsonDecode(response.payload!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final roomId =
        data['room_id'] ?? data['roomId'] ?? data['dm_room_id'];
    if (roomId is! String || roomId.isEmpty) return;

    if (!Supabase.instance.isInitialized) {
      await SupabaseBootstrap.initialize();
    }
    if (!isSupabaseConfigured()) return;

    final userId = getSupabase().auth.currentUser?.id;
    if (userId == null) return;

    final profile = await getSupabase()
        .from('profiles')
        .select('name, avatar_url')
        .eq('id', userId)
        .maybeSingle();
    final name = profile?['name'] as String? ?? 'You';

    await ChatService.sendMessage(
      messageId: generateId(),
      roomId: roomId,
      senderId: userId,
      senderName: name,
      senderAvatar: profile?['avatar_url'] as String?,
      content: text,
    );
  }

  static String? _routeFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final roomId =
          data['room_id'] ?? data['roomId'] ?? data['dm_room_id'];
      if (roomId is String && roomId.isNotEmpty) {
        return chatShellPath(roomId);
      }
      return routeFromRemoteMessage(
        RemoteMessage(data: data.map((k, v) => MapEntry('$k', '$v'))),
      );
    } catch (_) {
      return null;
    }
  }
}

@pragma('vm:entry-point')
void notificationBackgroundResponse(NotificationResponse response) {
  unawaited(_notificationBackgroundResponseImpl(response));
}

Future<void> _notificationBackgroundResponseImpl(
  NotificationResponse response,
) async {
  await LocalNotificationService.ensureInitialized();
  await LocalNotificationService.handleResponse(response);
}
