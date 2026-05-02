import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/notification_provider.dart';
import '../../models/notification.dart';
import '../../utils/date_format.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider).notifications;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          if (notifications.any((n) => !n.read))
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No notifications', style: theme.textTheme.bodyLarge),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final icon = switch (n.type) {
                  NotificationType.like => Icons.favorite,
                  NotificationType.comment => Icons.chat_bubble,
                  NotificationType.worldUnlocked => Icons.lock_open,
                  NotificationType.tierUpgrade => Icons.trending_up,
                  NotificationType.welcome => Icons.waving_hand,
                };

                return ListTile(
                  leading: Icon(icon, color: n.read ? theme.colorScheme.outline : theme.colorScheme.primary),
                  title: Text(n.message, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(formatTimestamp(n.createdAt)),
                  onTap: () => ref.read(notificationProvider.notifier).markRead(n.id),
                );
              },
            ),
    );
  }
}
