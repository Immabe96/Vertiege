import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/ally_provider.dart';
import '../../state/notification_provider.dart';
import '../../models/notification.dart';
import '../../utils/time_ago.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/core/screen_loading.dart';
import '../../theme/design_system.dart';
import '../../utils/navigation.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/icons/v_icons.dart';
import '../../theme/v_colors.dart';

enum _DateGroup { today, thisWeek, earlier }

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _markAllAnimController;
  late final Animation<double> _markAllScale;

  @override
  void initState() {
    super.initState();
    _markAllAnimController = AnimationController(
      duration: AnimDurations.fast,
      vsync: this,
    );
    _markAllScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.85),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.85, end: 1.0),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _markAllAnimController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _markAllAnimController.dispose();
    super.dispose();
  }

  // ── Date grouping helpers ──────────────────────────────────────────

  _DateGroup _groupForNotification(AppNotification n) {
    final now = DateTime.now();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(n.createdAt);
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = today.difference(dateDay).inDays;

    if (diff == 0) return _DateGroup.today;
    if (diff < 7) return _DateGroup.thisWeek;
    return _DateGroup.earlier;
  }

  String _labelForGroup(_DateGroup group) {
    return switch (group) {
      _DateGroup.today => 'TODAY',
      _DateGroup.thisWeek => 'THIS WEEK',
      _DateGroup.earlier => 'EARLIER',
    };
  }

  // ── Mark all read animation ────────────────────────────────────────

  void _onMarkAllRead() {
    HapticFeedback.lightImpact();
    _markAllAnimController.forward(from: 0.0);
    ref.read(notificationProvider.notifier).markAllRead();
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationProvider);
    final notifications = notifState.notifications;
    final theme = Theme.of(context);
    final hasUnread = notifications.any((n) => !n.read);

    if (notifState.isLoading) {
      return const Scaffold(body: ScreenLoading.list());
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(VIcons.arrowLeft),
          onPressed: () => safeBack(context),
        ),
        title: const Text('Alerts'),
        actions: [
          if (hasUnread)
            AnimatedBuilder(
              animation: _markAllScale,
              builder: (context, child) =>
                  Transform.scale(scale: _markAllScale.value, child: child),
              child: VButton(
                label: 'Mark all read',
                onPressed: _onMarkAllRead,
                variant: ButtonVariant.text,
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const AppEmptyState(
              title: 'All caught up!',
              description: 'You have no notifications yet.',
              icon: Icons.notifications_outlined,
              imageAsset: 'assets/generated/empty-notifications.jpg',
              variant: EmptyStateVariant.default_,
            )
          : _buildNotificationList(context, notifications, ref, theme),
    );
  }

  // ── Notification list with grouped slivers ─────────────────────────

  Widget _buildNotificationList(
    BuildContext context,
    List<AppNotification> notifications,
    WidgetRef ref,
    ThemeData theme,
  ) {
    // Partition notifications into date groups.
    final todayList = <AppNotification>[];
    final weekList = <AppNotification>[];
    final earlierList = <AppNotification>[];

    for (final n in notifications) {
      switch (_groupForNotification(n)) {
        case _DateGroup.today:
          todayList.add(n);
        case _DateGroup.thisWeek:
          weekList.add(n);
        case _DateGroup.earlier:
          earlierList.add(n);
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationProvider.notifier).loadNotifications();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        HapticFeedback.mediumImpact();
      },
      child: CustomScrollView(
        slivers: [
          if (todayList.isNotEmpty) ...[
            _SectionHeader(title: _labelForGroup(_DateGroup.today)),
            _NotificationSliverList(
              notifications: todayList,
              ref: ref,
              theme: theme,
            ),
          ],
          if (weekList.isNotEmpty) ...[
            _SectionHeader(title: _labelForGroup(_DateGroup.thisWeek)),
            _NotificationSliverList(
              notifications: weekList,
              ref: ref,
              theme: theme,
            ),
          ],
          if (earlierList.isNotEmpty) ...[
            _SectionHeader(title: _labelForGroup(_DateGroup.earlier)),
            _NotificationSliverList(
              notifications: earlierList,
              ref: ref,
              theme: theme,
            ),
          ],
          // Bottom padding so content isn't obscured by the nav bar.
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SectionHeaderDelegate(
        title: title,
        backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
        textColor: VColors.tertiary,
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final Color backgroundColor;
  final Color textColor;

  const _SectionHeaderDelegate({
    required this.title,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeights.semiBold,
          letterSpacing: LetterSpacing.label,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 40;

  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) =>
      title != oldDelegate.title ||
      backgroundColor != oldDelegate.backgroundColor ||
      textColor != oldDelegate.textColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification item list with dual-swipe cards
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationSliverList extends StatelessWidget {
  final List<AppNotification> notifications;
  final WidgetRef ref;
  final ThemeData theme;

  const _NotificationSliverList({
    required this.notifications,
    required this.ref,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // We need WidgetRef available in the dismiss callback, so we capture
    // the notifier reference now (read is fine outside build methods of
    // stateless widgets used inside a ConsumerStatefulWidget descendant).
    final notifier = ref.read(notificationProvider.notifier);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final n = notifications[index];
        final typeColor = _colorForTypeStatic(n.type);

        // Tapping the card navigates based on notification type.
        void onTap() {
          ref.read(notificationProvider.notifier).markRead(n.id);
          switch (n.type) {
            case NotificationType.like:
            case NotificationType.comment:
              if (n.postId != null && n.worldId != null) {
                context.push('/explore/${n.worldId}?post=${n.postId}');
              } else if (n.worldId != null) {
                context.push('/explore/${n.worldId}');
              }
              break;
            case NotificationType.worldUnlocked:
            case NotificationType.mention:
              if (n.worldId != null) {
                context.push('/explore/${n.worldId}');
              }
              break;
            case NotificationType.tierUpgrade:
              context.push('/identity');
              break;
            case NotificationType.allegianceRequest:
              context.push('/identity?tab=allies');
              break;
            case NotificationType.welcome:
              context.push('/explore');
              break;
            case NotificationType.modAction:
              context.push('/settings');
              break;
            case NotificationType.ranking:
              context.push('/season');
              break;
            case NotificationType.streakReminder:
              context.push('/identity');
              break;
            case NotificationType.reactionMilestone:
              if (n.postId != null && n.worldId != null) {
                context.push('/explore/${n.worldId}?post=${n.postId}');
              } else {
                context.push('/identity');
              }
              break;
          }
        }

        return FadeIn(
          delayMs: index * 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.xs,
            ),
            child: Dismissible(
              key: ValueKey(n.id),
              direction: DismissDirection.horizontal,
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // Swipe right → mark as read, keep in list.
                  HapticFeedback.lightImpact();
                  notifier.markRead(n.id);
                  return false;
                } else {
                  // Swipe left → archive (mark as read and dismiss).
                  HapticFeedback.lightImpact();
                  notifier.markRead(n.id);
                  return true;
                }
              },
              background: _SwipeBackground(
                color: VColors.success,
                icon: Icons.check,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: Spacing.lg),
              ),
              secondaryBackground: _SwipeBackground(
                color: theme.colorScheme.outline.withValues(alpha: 0.45),
                icon: Icons.archive,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: Spacing.lg),
              ),
              child: _NotificationCard(
                notification: n,
                typeColor: typeColor,
                onTap: onTap,
                actions: n.type == NotificationType.allegianceRequest
                    ? _AllegianceRequestActions(notification: n)
                    : null,
              ),
            ),
          ),
        );
      }, childCount: notifications.length),
    );
  }

  static Color _colorForTypeStatic(NotificationType type) {
    return switch (type) {
      NotificationType.like => VColors.tertiary,
      NotificationType.comment => VColors.primary,
      NotificationType.worldUnlocked => VColors.success,
      NotificationType.tierUpgrade => VColors.secondary,
      NotificationType.welcome => VColors.primary,
      NotificationType.modAction => VColors.error,
      NotificationType.ranking => VColors.tertiary,
      NotificationType.streakReminder => VColors.warning,
      NotificationType.reactionMilestone => VColors.tertiary,
      NotificationType.mention => VColors.primary,
      NotificationType.allegianceRequest => VColors.tertiary,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe backgrounds
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;

  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
      ),
      alignment: alignment,
      padding: padding,
      child: Icon(icon, color: isDark ? VColors.onSurfaceDark : VColors.onSurface, size: IconSizes.lg),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enhanced notification card with glass styling
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final Color typeColor;
  final VoidCallback onTap;
  final Widget? actions;

  const _NotificationCard({
    required this.notification,
    required this.typeColor,
    required this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final n = notification;
    final unread = !n.read;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
        child: GlassPanel(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left accent border for unread ──
                    if (unread)
                      Container(
                        width: 3,
                        decoration: const BoxDecoration(
                          color: VColors.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(RadiusTokens.xl),
                            bottomLeft: Radius.circular(RadiusTokens.xl),
                          ),
                        ),
                      ),
                    // ── Card body ──
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Row(
                          children: [
                            // ── Type icon in tinted container ──
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  RadiusTokens.input,
                                ),
                              ),
                              child: Icon(
                                _iconForTypeStatic(n.type),
                                color: typeColor,
                                size: IconSizes.md,
                              ),
                            ),
                            const SizedBox(width: Spacing.md),
                            // ── Message ──
                            Expanded(
                              child: Text(
                                n.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: unread
                                      ? FontWeights.bold
                                      : FontWeights.regular,
                                  color: unread
                                      ? (isDark
                                          ? VColors.onSurfaceDark
                                          : VColors.onSurface)
                                      : (isDark
                                          ? VColors.onSurfaceVariantDark
                                          : VColors.onSurfaceVariant),
                                  height: LineHeight.body,
                                ),
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            // ── Relative timestamp ──
                            TimeAgo(
                              DateTime.fromMillisecondsSinceEpoch(n.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (actions != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    0,
                    Spacing.md,
                    Spacing.sm,
                  ),
                  child: actions!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForTypeStatic(NotificationType type) {
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

class _AllegianceRequestActions extends ConsumerWidget {
  final AppNotification notification;
  const _AllegianceRequestActions({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allyNotifier = ref.read(allyProvider.notifier);
    final allyState = ref.watch(allyProvider);

    String? findRequestId() {
      if (notification.allyRequestId != null) {
        return notification.allyRequestId;
      }
      final match = allyState.pendingRequests.where((r) {
        return notification.message.contains(r.requesterId) ||
            notification.message.contains(r.receiverId);
      }).firstOrNull;
      return match?.id;
    }

    final requestId = findRequestId();

    return Row(
      children: [
        Expanded(
          child: VButton(
            label: 'DECLINE',
            onPressed: requestId != null
                ? () async {
                    ref
                        .read(notificationProvider.notifier)
                        .markRead(notification.id);
                    await allyNotifier.declineRequest(requestId);
                  }
                : null,
            variant: ButtonVariant.outlined,
            size: ButtonSize.small,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: VButton(
            label: 'ACCEPT',
            onPressed: requestId != null
                ? () async {
                    ref
                        .read(notificationProvider.notifier)
                        .markRead(notification.id);
                    await allyNotifier.acceptRequest(requestId);
                  }
                : null,
            size: ButtonSize.small,
          ),
        ),
      ],
    );
  }
}
