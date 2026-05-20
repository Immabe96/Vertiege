import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/resident_provider.dart';
import '../state/notification_provider.dart';
import '../state/post_provider.dart';
import '../services/supabase.dart';
import '../services/invite_service.dart';
import '../services/chat_service.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/the_gate_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/tabs/tab_layout.dart';
import '../screens/tabs/nexus_screen.dart';
import '../screens/tabs/explore_screen.dart';
import '../screens/tabs/chat_list_screen.dart';
import '../screens/tabs/identity_screen.dart';
import '../screens/tabs/more_screen.dart';

import '../screens/tabs/alerts_screen.dart';
import '../screens/world_detail_screen.dart';
import '../screens/world_channel_screen.dart';
import '../screens/chat_room_screen.dart';
import '../screens/resident_profile_screen.dart';
import '../screens/achievements/achievements_index.dart';
import '../screens/achievements/achievement_category.dart';
import '../screens/achievements/submit_achievement.dart';
import '../screens/settings_screen.dart';
import '../screens/create_world_screen.dart';
import '../screens/world_settings_screen.dart';
import '../screens/world_members_screen.dart';
import '../screens/search_screen.dart';
import '../screens/cosmetics_shop_screen.dart';
import '../screens/hall_of_ascension_screen.dart';
import '../screens/journey/ascension_path_screen.dart';
import '../screens/season_screen.dart';
import '../screens/verification_review_screen.dart';
import '../screens/audit_log_screen.dart';
import '../screens/campfire_screen.dart';
import '../screens/thread_screen.dart';
import '../screens/challenges_screen.dart';
import '../screens/league_screen.dart';
import '../screens/world_discovery_screen.dart';
import '../screens/twin_seal_setup_screen.dart';
import '../models/message.dart';
import '../widgets/core/empty_state.dart';
import '../screens/auth/auth_callback.dart';
import '../screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final residentState = ref.watch(
    residentProvider.select((s) => (s.resident, s.isLoading)),
  );
  final resident = residentState.$1;
  final isLoading = residentState.$2;
  final supabaseClient = maybeSupabase();

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.uri.path;

      // Never interrupt deep-link auth callbacks or splash
      if (location == '/auth/callback' || location == '/splash') return null;

      // Auth pages are always accessible (they handle their own state)
      final isAuthPage = location == '/login' || location == '/signup';

      // Check for a cached Supabase session (synchronous)
      final hasSession = supabaseClient?.auth.currentSession != null;

      if (!hasSession) {
        // Not authenticated — allow access only to auth pages
        if (!isAuthPage) return '/login';
        return null;
      }

      // Authenticated with a session
      if (isLoading) return null;

      if (resident == null) {
        // No resident profile yet — redirect to onboarding
        if (location != '/onboarding') return '/onboarding';
        return null;
      }

      // Authenticated with resident but hasn't completed The Gate
      // Onboarding + Gate are now merged into a single flow
      final gateDone = resident.gateCompleted;
      if (!gateDone) {
        if (location != '/onboarding') {
          return '/onboarding';
        }
        return null;
      }

      // Tier-gated routes — redirect home if not authorized
      final tier = resident.tier.value;
      if (location.startsWith('/admin') && tier < 4) return '/';
      if (location == '/create-world' && tier < 2) return '/';
      if (location == '/subscription' && tier < 2) return '/';

      // Authenticated with resident — redirect away from auth/onboarding pages
      if (isAuthPage || location == '/onboarding' || location == '/the-gate') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/the-gate',
        builder: (context, state) => const TheGateScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabLayout(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const NexusScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
                routes: [
                  GoRoute(
                    path: 'discover',
                    builder: (context, state) => const WorldDiscoveryScreen(),
                  ),
                  GoRoute(
                    path: ':worldId',
                    builder: (context, state) => WorldDetailScreen(
                      worldId: state.pathParameters['worldId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: ':channelName',
                        builder: (context, state) => WorldChannelScreen(
                          worldId: state.pathParameters['worldId']!,
                          channelId: state.uri.queryParameters['id'] ?? '',
                          channelName: state.pathParameters['channelName']!,
                        ),
                      ),
                      GoRoute(
                        path: 'settings',
                        builder: (context, state) => WorldSettingsScreen(
                          worldId: state.pathParameters['worldId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'members',
                        builder: (context, state) => WorldMembersScreen(
                          worldId: state.pathParameters['worldId']!,
                          worldName:
                              state.uri.queryParameters['name'] ?? 'World',
                          sovereignId:
                              state.uri.queryParameters['sovereign'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: ':roomId',
                    builder: (context, state) =>
                        ChatRoomScreen(roomId: state.pathParameters['roomId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/identity',
                builder: (context, state) => const IdentityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/residents/:id',
        builder: (context, state) =>
            ResidentProfileScreen(residentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsIndexScreen(),
        routes: [
          GoRoute(
            path: 'submit',
            builder: (context, state) => const SubmitAchievementScreen(),
          ),
          GoRoute(
            path: ':category',
            builder: (context, state) => AchievementCategoryScreen(
              category: state.pathParameters['category']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/shop',
        builder: (context, state) => const CosmeticsShopScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/season',
        builder: (context, state) => const SeasonScreen(),
      ),
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        path: '/leagues',
        builder: (context, state) => const LeagueScreen(),
      ),
      GoRoute(
        path: '/hall-of-ascension',
        builder: (context, state) => const HallOfAscensionScreen(),
      ),
      GoRoute(
        path: '/ascension-path',
        builder: (context, state) => const AscensionPathScreen(),
      ),
      GoRoute(
        path: '/create-world',
        builder: (context, state) => const CreateWorldScreen(),
      ),
      GoRoute(
        path: '/campfire/:channelId',
        builder: (context, state) => CampfireScreen(
          channelId: state.pathParameters['channelId']!,
          channelName: state.uri.queryParameters['name'] ?? 'Campfire',
          worldId: state.uri.queryParameters['worldId'] ?? '',
          worldName: state.uri.queryParameters['worldName'] ?? '',
        ),
      ),
      GoRoute(
        path: '/thread/:messageId',
        builder: (context, state) {
          // ThreadScreen needs a parent message — passed via extra
          final extra = state.extra as Map<String, dynamic>?;
          final parentMessage = extra?['message'] as ChannelMessage?;
          if (parentMessage == null) {
            return _ThreadDeepLinkScreen(
              messageId: state.pathParameters['messageId']!,
            );
          }
          return ThreadScreen(
            channelId: extra?['channelId'] ?? '',
            worldId: extra?['worldId'] ?? '',
            parentMessage: parentMessage,
            channelName: extra?['channelName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/audit-log/:worldId',
        builder: (context, state) => AuditLogScreen(
          worldId: state.pathParameters['worldId']!,
          worldName: state.uri.queryParameters['name'] ?? 'World',
        ),
      ),
      GoRoute(
        path: '/admin/verifications',
        builder: (context, state) => const VerificationReviewScreen(),
      ),
      GoRoute(
        path: '/twin-seal',
        builder: (context, state) => const TwinSealSetupScreen(),
      ),
      GoRoute(
        path: '/invite/:code',
        builder: (context, state) =>
            _AcceptInviteScreen(code: state.pathParameters['code']!),
      ),
      // Deep-link: notifications
      GoRoute(
        path: '/notifications/:id',
        builder: (context, state) => _NotificationDeepLink(
          notificationId: state.pathParameters['id']!,
        ),
      ),
      // Deep-link: post detail
      GoRoute(
        path: '/post/:postId',
        builder: (context, state) => _PostDeepLink(
          postId: state.pathParameters['postId']!,
        ),
      ),
    ],
  );
});

class _AcceptInviteScreen extends ConsumerStatefulWidget {
  final String code;

  const _AcceptInviteScreen({required this.code});

  @override
  ConsumerState<_AcceptInviteScreen> createState() =>
      _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<_AcceptInviteScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accept();
  }

  Future<void> _accept() async {
    final invite = await InviteService.validateInvite(widget.code);
    if (invite == null || !invite.isValid) {
      setState(() {
        _loading = false;
        _error = 'Invalid or expired invite code.';
      });
      return;
    }

    final resident = ref.read(residentProvider).resident;
    if (resident == null) {
      setState(() {
        _loading = false;
        _error = 'Sign in to accept this invite.';
      });
      return;
    }

    await InviteService.acceptInvite(invite.id, invite.worldId, resident.id);
    await ref.read(residentProvider.notifier).joinWorld(invite.worldId);

    if (mounted) context.go('/explore/${invite.worldId}');
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

class _ThreadDeepLinkScreen extends StatefulWidget {
  final String messageId;

  const _ThreadDeepLinkScreen({required this.messageId});

  @override
  State<_ThreadDeepLinkScreen> createState() => _ThreadDeepLinkScreenState();
}

class _ThreadDeepLinkScreenState extends State<_ThreadDeepLinkScreen> {
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
          DateTime.tryParse(
            row['created_at']?.toString() ?? '',
          )?.millisecondsSinceEpoch ??
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
///
/// Reads the notification from the provider, marks it read,
/// and redirects to the relevant target screen.
class _NotificationDeepLink extends ConsumerWidget {
  final String notificationId;

  const _NotificationDeepLink({required this.notificationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationProvider).notifications;
    final notif = notifs.where((n) => n.id == notificationId).firstOrNull;

    // Mark as read
    if (notif != null && !notif.read) {
      Future.microtask(() {
        ref.read(notificationProvider.notifier).markRead(notificationId);
      });
    }

    // Redirect based on notification data
    final target = notif?.worldId != null
        ? '/explore/${notif!.worldId}'
        : '/';
    Future.microtask(() => context.go(target));

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
///
/// Resolves the post's world and navigates to the world detail feed
/// where the post can be viewed in context.
class _PostDeepLink extends ConsumerStatefulWidget {
  final String postId;

  const _PostDeepLink({required this.postId});

  @override
  ConsumerState<_PostDeepLink> createState() => _PostDeepLinkState();
}

class _PostDeepLinkState extends ConsumerState<_PostDeepLink> {
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
      final post = posts.where((p) => p.id == widget.postId).firstOrNull;
      if (post != null && mounted) {
        context.go('/explore/${post.worldId}');
        return;
      }
      // Fallback: navigate to nexus
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Post not found'; });
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
