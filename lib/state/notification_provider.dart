import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../utils/id_generator.dart';
import 'resident_provider.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  const NotificationState({this.notifications = const [], this.isLoading = true});

  NotificationState copyWith({List<AppNotification>? notifications, bool? isLoading}) =>
      NotificationState(notifications: notifications ?? this.notifications, isLoading: isLoading ?? this.isLoading);
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

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

    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      NotificationService.createNotification(
        recipientId: resident.id,
        notification: n,
      );
    }
  }

  void markRead(String id) {
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
    );
    _persist();

    NotificationService.markRead(id);
  }

  void markAllRead() {
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.copyWith(read: true)).toList(),
    );
    _persist();

    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      NotificationService.markAllRead(resident.id);
    }
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);

    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      final remoteNotifications = await NotificationService.getNotifications(resident.id);
      if (remoteNotifications.isNotEmpty) {
        state = NotificationState(notifications: remoteNotifications, isLoading: false);
        _persist();
        return;
      }
    }

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

  void worldRankingAlert({
    required String worldId,
    required int rank,
    required String worldName,
  }) {
    String message;
    if (rank == 1) {
      message = 'Your world $worldName is ranked #1! The reigning sovereign.';
    } else {
      final toGo = rank - 1;
      message = 'Your world $worldName is ranked #$rank! $toGo more ${toGo == 1 ? 'boost' : 'boosts'} to reach #1.';
    }
    addNotification(
      type: NotificationType.ranking,
      message: message,
      worldId: worldId,
    );
  }

  void streakExpiringAlert({required int hoursLeft, required String residentName}) {
    final scheduleMsg = hoursLeft <= 1
        ? 'Your streak expires in 1 hour! Open now to keep it.'
        : 'Your streak expires in $hoursLeft hours! Open now to keep it.';
    addNotification(
      type: NotificationType.streakReminder,
      message: scheduleMsg,
    );
  }

  void reactionMilestone({
    required String postId,
    required String worldId,
    required int count,
  }) {
    final milestones = [5, 10, 25, 50, 100];
    if (!milestones.contains(count)) return;
    addNotification(
      type: NotificationType.reactionMilestone,
      message: '$count residents reacted to your post!',
      postId: postId,
      worldId: worldId,
    );
  }

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

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
