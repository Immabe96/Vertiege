import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/resident_provider.dart';
import '../services/invite_service.dart';
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
import '../screens/tabs/create_post_screen.dart';
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
import '../screens/auth/auth_callback.dart';
import '../screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final resident = ref.watch(residentProvider).resident;
  final supabaseClient = Supabase.instance.client;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.uri.path;

      // Never interrupt deep-link auth callbacks or splash
      if (location == '/auth/callback' || location == '/splash') return null;

      // Auth pages are always accessible (they handle their own state)
      final isAuthPage =
          location == '/login' || location == '/signup';

      // Check for a cached Supabase session (synchronous)
      final hasSession = supabaseClient.auth.currentSession != null;

      if (!hasSession) {
        // Not authenticated — allow access only to auth pages
        if (!isAuthPage) return '/login';
        return null;
      }

      // Authenticated with a session
      if (resident == null) {
        // No resident profile yet — redirect to onboarding
        if (location != '/onboarding') return '/onboarding';
        return null;
      }

      // Authenticated with resident but hasn't completed The Gate
      // The Gate comes AFTER basic onboarding
      if (!gateCompletedCache) {
        if (location != '/the-gate' && location != '/onboarding') return '/the-gate';
        return null;
      }

      // Tier-gated routes — redirect home if not authorized
      final tier = resident.tier.value;
      if (location.startsWith('/admin') && tier < 4) return '/';
      if (location == '/create-world' && tier < 2) return '/';
      if (location == '/subscription' && tier < 2) return '/';

      // Authenticated with resident — redirect away from auth/onboarding/gate pages
      if (isAuthPage || location == '/onboarding' || location == '/the-gate') return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
                          worldName: state.uri.queryParameters['name'] ?? 'World',
                          sovereignId: state.uri.queryParameters['sovereign'] ?? '',
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
                    builder: (context, state) => ChatRoomScreen(
                      roomId: state.pathParameters['roomId']!,
                    ),
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
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/residents/:id',
        builder: (context, state) => ResidentProfileScreen(
          residentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsIndexScreen(),
        routes: [
          GoRoute(
            path: ':category',
            builder: (context, state) => AchievementCategoryScreen(
              category: state.pathParameters['category']!,
            ),
          ),
          GoRoute(
            path: 'submit',
            builder: (context, state) => const SubmitAchievementScreen(),
          ),
        ],
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
        path: '/shop',
        builder: (context, state) => const CosmeticsShopScreen(),
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
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/create-world',
        builder: (context, state) => const CreateWorldScreen(),
      ),
      GoRoute(
        path: '/admin/verifications',
        builder: (context, state) => const VerificationReviewScreen(),
      ),
      GoRoute(
        path: '/invite/:code',
        builder: (context, state) => _AcceptInviteScreen(
          code: state.pathParameters['code']!,
        ),
      ),
    ],
  );
});

class _AcceptInviteScreen extends ConsumerStatefulWidget {
  final String code;

  const _AcceptInviteScreen({required this.code});

  @override
  ConsumerState<_AcceptInviteScreen> createState() => _AcceptInviteScreenState();
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
      setState(() { _loading = false; _error = 'Invalid or expired invite code.'; });
      return;
    }

    final resident = ref.read(residentProvider).resident;
    if (resident == null) {
      setState(() { _loading = false; _error = 'Sign in to accept this invite.'; });
      return;
    }

    await InviteService.acceptInvite(invite.id, invite.worldId, resident.id);
    ref.read(residentProvider.notifier).joinWorld(invite.worldId);

    if (mounted) context.go('/explore/${invite.worldId}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Accept Invite')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link_off, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(_error ?? 'Something went wrong', style: theme.textTheme.bodyLarge),
                ],
              ),
      ),
    );
  }
}
