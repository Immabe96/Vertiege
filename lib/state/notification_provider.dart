import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/storage_service.dart';
import '../utils/id_generator.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  const NotificationState({this.notifications = const [], this.isLoading = true});

  NotificationState copyWith({List<AppNotification>? notifications, bool? isLoading}) =>
      NotificationState(notifications: notifications ?? this.notifications, isLoading: isLoading ?? this.isLoading);
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  void addNotification({
    required NotificationType type,
    required String message,
    String? postId,
    String? worldId,
  }) {
    final n = AppNotification(
      id: generateId(),
      type: type,
      message: message,
      postId: postId,
      worldId: worldId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    state = state.copyWith(notifications: [n, ...state.notifications]);
    _persist();
  }

  void markRead(String id) {
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
    );
    _persist();
  }

  void markAllRead() {
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.copyWith(read: true)).toList(),
    );
    _persist();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final json = await StorageService.getString(StorageService.notificationsKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        final notifications = list.map((e) => _fromJson(e as Map<String, dynamic>)).whereType<AppNotification>().toList();
        state = NotificationState(notifications: notifications, isLoading: false);
        return;
      }
    } catch (_) {}
    state = const NotificationState(isLoading: false);
  }

  int get unreadCount => state.notifications.where((n) => !n.read).length;

  void _persist() {
    final json = jsonEncode(state.notifications.map(_toJson).toList());
    StorageService.setStringDebounced(StorageService.notificationsKey, json);
  }

  static AppNotification? _fromJson(Map<String, dynamic> json) {
    try {
      return AppNotification(
        id: json['id'] as String,
        type: AppNotification.typeFromString(json['type'] as String),
        message: json['message'] as String,
        worldId: json['worldId'] as String?,
        postId: json['postId'] as String?,
        read: (json['read'] as bool?) ?? false,
        createdAt: (json['createdAt'] as int?) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _toJson(AppNotification n) => {
        'id': n.id,
        'type': n.type.name,
        'message': n.message,
        'worldId': n.worldId,
        'postId': n.postId,
        'read': n.read,
        'createdAt': n.createdAt,
      };
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);
