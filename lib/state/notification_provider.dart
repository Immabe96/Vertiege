import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../services/quiet_hours_service.dart';
import '../utils/id_generator.dart';
import '../utils/provider_errors.dart';
import 'resident_provider.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final List<AppNotification> quietNotifications;
  final bool isLoading;
  final String? error;
  const NotificationState({
    this.notifications = const [],
    this.quietNotifications = const [],
    this.isLoading = true,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    List<AppNotification>? quietNotifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => NotificationState(
    notifications: notifications ?? this.notifications,
    quietNotifications: quietNotifications ?? this.quietNotifications,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

class NotificationNotifier extends Notifier<NotificationState> {
  StreamSubscription<AppNotification>? _realtimeSubscription;
  String? _realtimeResidentId;
  int _unreadCount = 0;

  @override
  NotificationState build() {
    ref.onDispose(() {
      _realtimeSubscription?.cancel();
      unawaited(PushService.dispose());
    });
    return const NotificationState();
  }

  void addNotification({
    required NotificationType type,
    required String message,
    String? postId,
    String? worldId,
  }) async {
    final n = AppNotification(
      id: generateId(),
      type: type,
      message: message,
      postId: postId,
      worldId: worldId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final isPriority =
        type == NotificationType.modAction ||
        type == NotificationType.tierUpgrade ||
        type == NotificationType.welcome;

    if (worldId != null && !isPriority) {
      final quiet = await QuietHoursService.isQuietTime(worldId);
      if (quiet) {
        state = state.copyWith(
          quietNotifications: [...state.quietNotifications, n],
        );
        _persist();
        return;
      }
    }

    state = state.copyWith(notifications: [n, ...state.notifications]);
    _unreadCount++;
    _persist();

    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      unawaited(
        NotificationService.createNotification(
          recipientId: resident.id,
          notification: n,
        ).catchError((_) {}),
      );
    }
  }

  void deliverQuietNotifications() {
    if (state.quietNotifications.isEmpty) return;
    final toDeliver = List<AppNotification>.from(state.quietNotifications);
    state = state.copyWith(
      notifications: [...toDeliver, ...state.notifications],
      quietNotifications: [],
    );
    _unreadCount += toDeliver.length;
    _persist();
  }

  void markRead(String id) {
    final wasUnread = state.notifications
        .where((n) => n.id == id && !n.read)
        .isNotEmpty;
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList(),
    );
    if (wasUnread) {
      _unreadCount = (_unreadCount - 1).clamp(0, 999999);
    }
    _persist();

    unawaited(NotificationService.markRead(id).catchError((_) {}));
  }

  void markAllRead() {
    final wasUnread = state.notifications.where((n) => !n.read).length;
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(read: true))
          .toList(),
    );
    _unreadCount = (_unreadCount - wasUnread).clamp(0, 999999);
    _persist();

    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      unawaited(
        NotificationService.markAllRead(resident.id).catchError((_) {}),
      );
    }
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    final cached = await _loadCachedNotifications();
    if (cached.isNotEmpty) {
      _unreadCount = cached.where((n) => !n.read).length;
      state = NotificationState(
        notifications: cached,
        quietNotifications: state.quietNotifications,
      );
    }

    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      unawaited(_subscribeRealtime(resident.id));
      try {
        final remoteNotifications = await NotificationService.getNotifications(
          resident.id,
        );
        _unreadCount = remoteNotifications.where((n) => !n.read).length;
        state = state.copyWith(
          notifications: remoteNotifications,
          isLoading: false,
          clearError: true,
        );
        _persist();
        return;
      } catch (e) {
        final message = cached.isNotEmpty
            ? 'Showing cached notifications (sync failed).'
            : userFacingLoadError(
                e,
                fallback: 'Could not load notifications. Pull to refresh.',
              );
        state = state.copyWith(isLoading: false, error: message);
        return;
      }
    }

    state = state.copyWith(notifications: cached, isLoading: false, clearError: true);
    _unreadCount = cached.where((n) => !n.read).length;
  }

  Future<List<AppNotification>> _loadCachedNotifications() async {
    try {
      final json = await StorageService.getString(
        StorageService.notificationsKey,
      );
      if (json != null) {
        final list = jsonDecode(json) as List;
        return list
            .map((e) => _fromJson(e as Map<String, dynamic>))
            .whereType<AppNotification>()
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  int get unreadCount => _unreadCount;

  Future<void> _subscribeRealtime(String residentId) async {
    if (_realtimeResidentId == residentId) return;
    await _realtimeSubscription?.cancel();
    await PushService.dispose();
    await PushService.initialize(userId: residentId);
    _realtimeResidentId = residentId;
    _realtimeSubscription = PushService.onNotificationReceived.listen(
      _addRemoteNotification,
    );
  }

  void _addRemoteNotification(AppNotification notification) {
    if (state.notifications.any((n) => n.id == notification.id)) return;
    if (!notification.read) {
      _unreadCount++;
    }
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
      isLoading: false,
    );
    _persist();
  }

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
      message =
          'Your world $worldName is ranked #$rank! $toGo more ${toGo == 1 ? 'boost' : 'boosts'} to reach #1.';
    }
    addNotification(
      type: NotificationType.ranking,
      message: message,
      worldId: worldId,
    );
  }

  void streakExpiringAlert({
    required int hoursLeft,
    required String residentName,
  }) {
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

  void clearForSignOut() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _realtimeResidentId = null;
    _unreadCount = 0;
    state = const NotificationState(isLoading: false);
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

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
