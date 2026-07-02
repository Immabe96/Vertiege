import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/invite_service.dart';
import '../services/supabase.dart';
import '../services/notification_service.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../state/resident_provider.dart';
import '../state/notification_provider.dart';
import '../state/post_provider.dart';
import '../state/chat_provider.dart';
import '../screens/world_channel_screen.dart';
import '../screens/campfire_screen.dart';
import '../screens/thread_screen.dart';
import '../widgets/core/empty_state.dart';
import 'world_navigation.dart';
import 'notification_navigation.dart';

/// Remembers last channel when deep-linking into a world channel.
class WorldChannelRouteHandler extends ConsumerStatefulWidget {
  final String worldId;
  final String channelId;
  final String channelName;

  const WorldChannelRouteHandler({super.key, 
    required this.worldId,
    required this.channelId,
    required this.channelName,
  });

  @override
  ConsumerState<WorldChannelRouteHandler> createState() =>
      _WorldChannelRouteHandlerState();
}

class _WorldChannelRouteHandlerState
    extends ConsumerState<WorldChannelRouteHandler> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.channelId.isNotEmpty) {
        ref.read(chatProvider.notifier).rememberLastChannel(
              worldId: widget.worldId,
              channelId: widget.channelId,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WorldChannelScreen(
      worldId: widget.worldId,
      channelId: widget.channelId,
      channelName: widget.channelName,
    );
  }
}

class CampfireRouteHandler extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;
  final String worldId;
  final String worldName;

  const CampfireRouteHandler({super.key, 
    required this.channelId,
    required this.channelName,
    required this.worldId,
    required this.worldName,
  });

  @override
  ConsumerState<CampfireRouteHandler> createState() =>
      _CampfireRouteHandlerState();
}

class _CampfireRouteHandlerState extends ConsumerState<CampfireRouteHandler> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.worldId.isEmpty) return;
      ref.read(chatProvider.notifier).rememberLastChannel(
            worldId: widget.worldId,
            channelId: widget.channelId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CampfireScreen(
      channelId: widget.channelId,
      channelName: widget.channelName,
      worldId: widget.worldId,
      worldName: widget.worldName,
    );
  }
}

class AcceptInviteScreen extends ConsumerStatefulWidget {
  final String code;

  const AcceptInviteScreen({super.key, required this.code});

  @override
  ConsumerState<AcceptInviteScreen> createState() =>
      _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accept();
  }

  Future<void> _accept() async {
    unawaited(
      AnalyticsService.logEvent(
        AnalyticsEvents.inviteOpened,
        parameters: {'has_code': widget.code.isNotEmpty},
      ),
    );
    final invite = await InviteService.validateInvite(widget.code);
    if (!mounted) return;
    if (invite == null || !invite.isValid) {
      setState(() {
        _loading = false;
        _error = 'Invalid or expired invite code.';
      });
      return;
    }

    final resident = ref.read(residentProvider).resident;
    if (!mounted) return;
    if (resident == null || !resident.gateCompleted) {
      await InviteService.savePendingInviteCode(widget.code);
      unawaited(AnalyticsService.logEvent(AnalyticsEvents.inviteSavedPending));
      if (!mounted) return;
      final hasSession = maybeSupabase()?.auth.currentSession != null;
      context.go(hasSession ? '/onboarding' : '/login');
      return;
    }

    final result = await InviteService.redeemInviteCode(
      code: widget.code,
      residentId: resident.id,
      residentName: resident.name,
    );
    if (!mounted) return;
    if (!result.succeeded) {
      unawaited(AnalyticsService.logEvent(AnalyticsEvents.inviteRedeemFailed));
      setState(() {
        _loading = false;
        _error = result.errorMessage ?? 'Something went wrong';
      });
      return;
    }
    await ref.read(residentProvider.notifier).joinWorld(result.worldId!);
    unawaited(
      AnalyticsService.logEvent(
        AnalyticsEvents.inviteCompleted,
        parameters: {'world_id': result.worldId!},
      ),
    );
    if (!mounted) return;
    context.go(exploreWorldPath(result.worldId!));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Accept Invite')),
      body: Center(
        child: _loading
            ? const FCircularProgress()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link_off,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error ?? 'Something went wrong',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
      ),
    );
  }
}

class ThreadDeepLinkScreen extends StatefulWidget {
  final String messageId;

  const ThreadDeepLinkScreen({super.key, required this.messageId});

  @override
  State<ThreadDeepLinkScreen> createState() => _ThreadDeepLinkScreenState();
}

class _ThreadDeepLinkScreenState extends State<ThreadDeepLinkScreen> {
  late final Future<ChannelMessage?> _messageFuture;

  @override
  void initState() {
    super.initState();
    _messageFuture = _loadMessage();
  }

  Future<ChannelMessage?> _loadMessage() async {
    final row = await ChatService.getChannelMessage(widget.messageId);
    if (row == null) return null;
    return ChannelMessage(
      id: row['id'] ?? '',
      channelId: row['channel_id'] ?? '',
      senderId: row['sender_id'] ?? '',
      senderName: row['sender_name'] ?? '',
      senderAvatar: row['sender_avatar'],
      content: row['content'] ?? '',
      imageUrl: row['image_url'],
      isPinned: row['is_pinned'] ?? false,
      threadId: row['thread_id'],
      threadCount: row['thread_count'] ?? 0,
      isThreadStarter: row['is_thread_starter'] ?? false,
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '')
              ?.millisecondsSinceEpoch ??
          0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChannelMessage?>(
      future: _messageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Thread')),
            body: const Center(child: FCircularProgress()),
          );
        }

        final message = snapshot.data;
        if (message == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Thread')),
            body: AppEmptyState(
              title: 'Thread unavailable',
              description:
                  'The original message could not be found or is no longer available.',
              icon: Icons.forum_outlined,
              variant: EmptyStateVariant.error,
              actionLabel: 'Back to Nexus',
              onAction: () => context.go('/'),
            ),
          );
        }

        return ThreadScreen(
          channelId: message.channelId,
          worldId: '',
          parentMessage: message,
          channelName: 'Thread',
        );
      },
    );
  }
}

/// Deep-link handler for notification taps.
class NotificationDeepLink extends ConsumerStatefulWidget {
  final String notificationId;

  const NotificationDeepLink({super.key, required this.notificationId});

  @override
  ConsumerState<NotificationDeepLink> createState() =>
      _NotificationDeepLinkState();
}

class _NotificationDeepLinkState extends ConsumerState<NotificationDeepLink> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    var notifs = ref.read(notificationProvider).notifications;
    var notif =
        notifs.where((n) => n.id == widget.notificationId).firstOrNull;

    // Fallback: fetch from server if not in memory
    if (notif == null && isSupabaseConfigured()) {
      try {
        final residentId = ref.read(residentProvider).resident?.id;
        if (residentId != null) {
          final serverNotifs =
              await NotificationService.getNotifications(residentId);
          notif = serverNotifs
              .where((n) => n.id == widget.notificationId)
              .firstOrNull;
        }
      } catch (_) {}
    }

    if (notif != null && !notif.read) {
      ref.read(notificationProvider.notifier).markRead(widget.notificationId);
    }

    if (!context.mounted) return;
    if (notif != null) {
      final route = routeForNotification(notif);
      if (route != null && route.isNotEmpty) {
        context.go(route);
        return;
      }
    }
    context.go('/notifications');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppEmptyState(
          title: 'Opening...',
          icon: Icons.open_in_new,
          actionLabel: 'Go Home',
          onAction: () => context.go('/'),
        ),
      ),
    );
  }
}

/// Deep-link handler for post detail links.
class PostDeepLink extends ConsumerStatefulWidget {
  final String postId;

  const PostDeepLink({super.key, required this.postId});

  @override
  ConsumerState<PostDeepLink> createState() => _PostDeepLinkState();
}

class _PostDeepLinkState extends ConsumerState<PostDeepLink> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final posts = ref.read(postProvider).posts;
      var post = posts.where((p) => p.id == widget.postId).firstOrNull;
      if (post == null && isSupabaseConfigured()) {
        final row = await getSupabase()
            .from('posts')
            .select('world_id')
            .eq('id', widget.postId)
            .maybeSingle();
        final worldId = row?['world_id'] as String?;
        if (worldId != null && mounted) {
          await ref
              .read(postProvider.notifier)
              .ensurePostVisible(widget.postId);
          if (!mounted) return;
          context.go(exploreWorldPath(worldId, postId: widget.postId));
          return;
        }
      }
      if (post != null && mounted) {
        await ref.read(postProvider.notifier).ensurePostVisible(widget.postId);
        if (!mounted) return;
        context.go(exploreWorldPath(post.worldId, postId: widget.postId));
        return;
      }
      if (mounted) context.go('/notifications');
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Post not found';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: AppEmptyState(
        title: 'Post unavailable',
        description: _error ?? 'This post could not be found.',
        icon: Icons.article_outlined,
        variant: EmptyStateVariant.error,
        actionLabel: 'Go Home',
        onAction: () => context.go('/'),
      ),
    );
  }
}
