import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/ally_provider.dart';
import '../../state/notification_provider.dart';
import '../../models/notification.dart';
import '../../utils/time_ago.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class NexusNotificationsSheet extends ConsumerStatefulWidget {
  const NexusNotificationsSheet({super.key});

  @override
  ConsumerState<NexusNotificationsSheet> createState() =>
      _NexusNotificationsSheetState();
}

class _NexusNotificationsSheetState
    extends ConsumerState<NexusNotificationsSheet> {
  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationProvider);
    final notifications = notifState.notifications;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = notifications.any((n) => !n.read);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? VColors.surfaceDark : VColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VRadius.xl),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.md,
                  VSpacing.sm,
                  VSpacing.md,
                  VSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant)
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Notifications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                    const Spacer(),
                    if (hasUnread)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(notificationProvider.notifier)
                              .markAllRead();
                        },
                        child: const Text('Mark all read'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 48,
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: VSpacing.md),
                            Text(
                              'All caught up!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: VFontWeight.semiBold,
                              ),
                            ),
                            const SizedBox(height: VSpacing.xs),
                            Text(
                              'No notifications yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : NotificationList(
                        notifications: notifications,
                        scrollController: scrollController,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NotificationList extends ConsumerWidget {
  final List<AppNotification> notifications;
  final ScrollController? scrollController;

  const NotificationList({
    super.key,
    required this.notifications,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(VSpacing.sm),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        final typeColor = _colorForType(n.type);
        final unread = !n.read;

        return Padding(
          padding: const EdgeInsets.only(bottom: VSpacing.xs),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(notificationProvider.notifier).markRead(n.id);
                _handleNavigation(context, n);
              },
              borderRadius: BorderRadius.circular(VRadius.lg),
              child: Container(
                padding: const EdgeInsets.all(VSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? VColors.glassBackgroundDark
                      : VColors.glassBackground,
                  borderRadius: BorderRadius.circular(VRadius.lg),
                  border: Border.all(
                    color: isDark
                        ? VColors.glassBorderDark
                        : VColors.glassBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(VRadius.md),
                      ),
                      child: Icon(
                        _iconForType(n.type),
                        color: typeColor,
                        size: VIconSize.md,
                      ),
                    ),
                    const SizedBox(width: VSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: unread
                                  ? VFontWeight.semiBold
                                  : VFontWeight.regular,
                              color: unread
                                  ? (isDark
                                      ? VColors.onSurfaceDark
                                      : VColors.onSurface)
                                  : (isDark
                                      ? VColors.onSurfaceVariantDark
                                      : VColors.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(height: VSpacing.xxs),
                          Text(
                            timeAgo(
                              DateTime.fromMillisecondsSinceEpoch(n.createdAt),
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (n.type == NotificationType.allegianceRequest)
                      _AllegianceActions(notification: n),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleNavigation(BuildContext context, AppNotification n) {
    switch (n.type) {
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.worldUnlocked:
      case NotificationType.mention:
        if (n.worldId != null) {
          context.push('/explore/${n.worldId}');
        }
        break;
      case NotificationType.tierUpgrade:
      case NotificationType.allegianceRequest:
        context.push('/identity');
        break;
      case NotificationType.welcome:
      case NotificationType.modAction:
      case NotificationType.ranking:
      case NotificationType.streakReminder:
      case NotificationType.reactionMilestone:
        break;
    }
  }

  static Color _colorForType(NotificationType type) {
    return switch (type) {
      NotificationType.like => VColors.error,
      NotificationType.comment => VColors.primary,
      NotificationType.worldUnlocked => VColors.success,
      NotificationType.tierUpgrade => VColors.tertiary,
      NotificationType.welcome => VColors.primary,
      NotificationType.modAction => VColors.error,
      NotificationType.ranking => VColors.tertiary,
      NotificationType.streakReminder => VColors.warning,
      NotificationType.reactionMilestone => VColors.error,
      NotificationType.mention => VColors.primary,
      NotificationType.allegianceRequest => VColors.tertiary,
    };
  }

  static IconData _iconForType(NotificationType type) {
    return switch (type) {
      NotificationType.like => Icons.favorite,
      NotificationType.comment => Icons.chat_bubble,
      NotificationType.worldUnlocked => Icons.lock_open,
      NotificationType.tierUpgrade => Icons.trending_up,
      NotificationType.welcome => Icons.celebration,
      NotificationType.modAction => Icons.gavel,
      NotificationType.ranking => Icons.emoji_events,
      NotificationType.streakReminder => Icons.local_fire_department,
      NotificationType.reactionMilestone => Icons.favorite_border,
      NotificationType.mention => Icons.alternate_email,
      NotificationType.allegianceRequest => Icons.handshake,
    };
  }
}

class _AllegianceActions extends ConsumerWidget {
  final AppNotification notification;

  const _AllegianceActions({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allyNotifier = ref.read(allyProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () async {
            ref.read(notificationProvider.notifier).markRead(notification.id);
            final pending = ref.read(allyProvider).pendingRequests;
            if (pending.isNotEmpty) {
              await allyNotifier.declineRequest(pending.first.id);
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: VColors.onSurfaceVariant,
            side: const BorderSide(color: VColors.outlineVariant),
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: VSpacing.xs,
            ),
          ),
          child: const Text(
            'Decline',
            style: TextStyle(fontSize: VFontSize.labelSm),
          ),
        ),
        const SizedBox(width: VSpacing.xs),
        FilledButton(
          onPressed: () async {
            ref.read(notificationProvider.notifier).markRead(notification.id);
            final pending = ref.read(allyProvider).pendingRequests;
            if (pending.isNotEmpty) {
              await allyNotifier.acceptRequest(pending.first.id);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: VColors.tertiary,
            foregroundColor: VColors.onTertiary,
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: VSpacing.xs,
            ),
          ),
          child: const Text(
            'Accept',
            style: TextStyle(fontSize: VFontSize.labelSm),
          ),
        ),
      ],
    );
  }
}
