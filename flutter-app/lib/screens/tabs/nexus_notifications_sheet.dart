import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/ally_provider.dart';
import '../../state/notification_provider.dart';
import '../../models/notification.dart';
import '../../router/notification_navigation.dart';
import '../../utils/time_ago.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/buttons/v_icon_button.dart';

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
    final hasUnread = notifications.any((n) => !n.read);

    final sheetHeight = MediaQuery.sizeOf(context).height * 0.65;

    return SizedBox(
      height: sheetHeight,
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
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
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
                  VButton(
                    label: 'Mark all read',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(notificationProvider.notifier).markAllRead();
                    },
                    variant: ButtonVariant.text,
                  ),
                VIconButton(
                  semanticsLabel: 'Close notifications',
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(VIcons.x),
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
                          color: theme.colorScheme.onSurfaceVariant,
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
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : NotificationList(notifications: notifications),
          ),
        ],
      ),
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
                  color: VColors.glassBackgroundDark,
                  borderRadius: BorderRadius.circular(VRadius.lg),
                  border: Border.all(color: VColors.glassBorderDark),
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
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: VSpacing.xxs),
                          Text(
                            timeAgo(
                              DateTime.fromMillisecondsSinceEpoch(n.createdAt),
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
    final route = routeForNotification(n);
    if (route != null) context.push(route);
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
      NotificationType.dmMessage => VColors.primary,
      NotificationType.allegianceRequest => VColors.tertiary,
      NotificationType.achievementApproved => VColors.success,
      NotificationType.identityVerified => VColors.brand,
      NotificationType.identityRejected => VColors.error,
      NotificationType.achievementRejected => VColors.error,
      NotificationType.jobApplicationAccepted => VColors.success,
      NotificationType.jobApplicationRejected => VColors.error,
      NotificationType.governanceProposalApproved => VColors.success,
      NotificationType.governanceProposalRejected => VColors.error,
      NotificationType.unknown => VColors.primary,
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
      NotificationType.dmMessage => Icons.chat_outlined,
      NotificationType.allegianceRequest => Icons.handshake,
      NotificationType.achievementApproved => Icons.verified,
      NotificationType.identityVerified => Icons.badge_outlined,
      NotificationType.identityRejected => Icons.badge_outlined,
      NotificationType.achievementRejected => Icons.cancel_outlined,
      NotificationType.jobApplicationAccepted => Icons.work_outline,
      NotificationType.jobApplicationRejected => Icons.work_off_outlined,
      NotificationType.governanceProposalApproved => Icons.how_to_vote,
      NotificationType.governanceProposalRejected => Icons.block,
      NotificationType.unknown => Icons.notifications_outlined,
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
        VButton(
          label: 'Decline',
          onPressed: () async {
            ref.read(notificationProvider.notifier).markRead(notification.id);
            final pending = ref.read(allyProvider).pendingRequests;
            if (pending.isNotEmpty) {
              await allyNotifier.declineRequest(pending.first.id);
            }
          },
          variant: ButtonVariant.outlined,
        ),
        const SizedBox(width: VSpacing.xs),
        VButton(
          label: 'Accept',
          onPressed: () async {
            ref.read(notificationProvider.notifier).markRead(notification.id);
            final pending = ref.read(allyProvider).pendingRequests;
            if (pending.isNotEmpty) {
              await allyNotifier.acceptRequest(pending.first.id);
            }
          },
        ),
      ],
    );
  }
}
