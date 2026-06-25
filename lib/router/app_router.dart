import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/resident_provider.dart';
import '../services/supabase.dart';
import '../services/analytics_service.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/the_gate_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/tabs/tab_layout.dart';
import '../screens/tabs/nexus_screen.dart';
import '../screens/tabs/explore_screen.dart';
import '../screens/tabs/chat_list_screen.dart';
import '../screens/tabs/you_screen.dart';
import '../screens/tabs/achievements_screen.dart';
import '../ui_spike/spike_settings_page.dart';

import '../screens/tabs/alerts_screen.dart';
import '../screens/world_detail_screen.dart';
import '../screens/chat_room_screen.dart';
import '../widgets/core/status_dot.dart';
import '../screens/resident_profile_screen.dart';
import '../screens/achievements/achievement_category.dart';
import '../screens/achievements/submit_achievement.dart';
import '../screens/settings_screen.dart';
import '../screens/create_world_screen.dart';
import '../screens/world_settings_screen.dart';
import '../screens/world_members_screen.dart';
import 'app_auth_redirect.dart';
import 'deep_link_redirects.dart';
import 'world_route_redirects.dart';
import 'deep_link_handlers.dart';
import '../screens/search_screen.dart';
import '../screens/connections_screen.dart';
import '../screens/cosmetics_shop_screen.dart';
import '../screens/hall_of_ascension_screen.dart';
import '../screens/journey/ascension_path_screen.dart';
import '../screens/auth/verifier_login_screen.dart';
import '../screens/verification_review_screen.dart';
import '../services/admin_access_service.dart';
import '../screens/audit_log_screen.dart';
import '../screens/post_comments_screen.dart';
import '../screens/thread_screen.dart';
import '../screens/world_marketplace_screen.dart';
import '../screens/world_polls_screen.dart';
import '../screens/world_treasury_screen.dart';
import '../screens/world_manage_screen.dart';
import '../screens/world_governance_screen.dart';
import '../screens/world_challenges_screen.dart';
import '../screens/world_jobs_screen.dart';
import '../screens/world_archive_screen.dart';
import '../screens/world_academy_screen.dart';
import '../screens/world_sanctuary_screen.dart';
import '../screens/progress_hub_screen.dart';
import '../screens/coin_history_screen.dart';
import 'progress_navigation.dart';
import '../screens/world_discovery_screen.dart';
import '../screens/twin_seal_setup_screen.dart';
import '../models/message.dart';
import '../widgets/core/empty_state.dart';
import '../screens/auth/auth_callback.dart';
import '../screens/splash_screen.dart';
import 'go_router_refresh.dart';
import 'navigation_keys.dart';
import 'v_page_transitions.dart';

/// Stable listenable — resident/auth changes refresh redirects only (no router rebuild).
final goRouterRefreshProvider = Provider<GoRouterRefresh>((ref) {
  final refresh = GoRouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(
    residentProvider.select(
      (s) => (
        s.isLoading,
        s.resident?.id,
        s.resident?.gateCompleted,
        s.resident?.tier.value,
      ),
    ),
    (_, __) => refresh.refresh(),
  );
  final client = maybeSupabase();
  if (client != null) {
    final sub = client.auth.onAuthStateChange.listen((_) => refresh.refresh());
    ref.onDispose(sub.cancel);
  }
  return refresh;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(goRouterRefreshProvider);

  return GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshListenable,
    observers: AnalyticsService.navigatorObservers,
    errorBuilder: (context, state) => Scaffold(
      body: AppEmptyState(
        title: 'Page not found',
        description: state.uri.path,
        icon: Icons.error_outline,
        variant: EmptyStateVariant.error,
        actionLabel: 'Go to Nexus',
        onAction: () => context.go('/'),
      ),
    ),
    redirect: (context, state) {
      final residentState = ref.read(residentProvider);
      final resident = residentState.resident;
      final isLoading = residentState.isLoading;
      final uri = state.uri;
      var location = uri.path;

      final verifierRedirect = redirectVerifierHostDeepLink(uri, location);
      if (verifierRedirect != null) return verifierRedirect;

      final authRedirect = redirectAuthHostDeepLink(uri, location);
      if (authRedirect != null) return authRedirect;

      final inviteRedirect = redirectInviteHostDeepLink(uri, location);
      if (inviteRedirect != null) return inviteRedirect;

      final residentsRedirect = redirectResidentsHostDeepLink(uri, location);
      if (residentsRedirect != null) return residentsRedirect;

      // Never interrupt deep-link auth callbacks or splash
      if (location == '/auth/callback' || location == '/splash') return null;

      final isVerifierRoute = location.startsWith('/verifier');
      final isVerifierLogin = location == '/verifier/login';
      final isInviteRoute = location.startsWith('/invite/');

      // Legacy admin URL → verifier portal
      if (location == '/admin/verifications') return '/verifier/review';

      final client = maybeSupabase();
      final hasSession = client?.auth.currentSession != null;
      final currentUser = client?.auth.currentUser;
      final isVerifier = AdminAccessService.isVerifierUser(currentUser);

      // ── Verifier portal (staff review; same session as main app) ───
      if (isVerifierRoute) {
        if (!hasSession) {
          return isVerifierLogin ? null : '/verifier/login';
        }
        if (!isVerifier) {
          return '/login';
        }
        if (isVerifierLogin) {
          return '/';
        }
        return null;
      }

      // Auth pages are always accessible (they handle their own state)
      final isAuthPage = location == '/login' || location == '/signup';

      final unauthRedirect = resolveUnauthenticatedRedirect(
        hasSession: hasSession,
        location: location,
        isAuthPage: isAuthPage || isInviteRoute,
      );
      if (unauthRedirect != null) return unauthRedirect;

      if (!isInviteRoute) {
        final onboardingRedirect = resolveResidentOnboardingRedirect(
          hasSession: hasSession,
          isLoading: isLoading,
          hasResident: resident != null,
          gateCompleted: resident?.gateCompleted ?? false,
          location: location,
          isAuthPage: isAuthPage,
        );
        if (onboardingRedirect != null) return onboardingRedirect;
      }

      if (resident == null) return null;

      final tier = resident.tier.value;
      if (location == '/create-world' &&
          !AdminAccessService.canCreateWorld(tierValue: tier)) {
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
                redirect: (context, state) {
                  final panel = state.uri.queryParameters['panel'];
                  if (panel == 'discover') return '/explore/discover';
                  final worldId = state.uri.queryParameters['world'];
                  if (worldId != null && worldId.isNotEmpty) {
                    return '/explore/$worldId';
                  }
                  return null;
                },
                builder: (context, state) => const NexusScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/achievements',
                builder: (context, state) => const AchievementsScreen(),
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
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/identity',
                builder: (context, state) => const YouScreen(),
              ),
            ],
          ),
        ],
      ),
      // Explore routes (outside tab shell — accessed via deep links)
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
              GoRoute(
                path: 'marketplace',
                builder: (context, state) => WorldMarketplaceScreen(
                  worldId: state.pathParameters['worldId']!,
                  isMember:
                      state.uri.queryParameters['member'] == 'true',
                ),
              ),
              GoRoute(
                path: 'polls',
                builder: (context, state) => WorldPollsScreen(
                  worldId: state.pathParameters['worldId']!,
                  isSovereignOrCouncil:
                      state.uri.queryParameters['admin'] == 'true',
                ),
              ),
              GoRoute(
                path: 'treasury',
                builder: (context, state) => WorldTreasuryScreen(
                  worldId: state.pathParameters['worldId']!,
                  isSovereignOrCouncil:
                      state.uri.queryParameters['admin'] == 'true',
                ),
              ),
              GoRoute(
                path: 'challenges',
                builder: (context, state) => WorldChallengesScreen(
                  worldId: state.pathParameters['worldId']!,
                  isSovereignOrCouncil:
                      state.uri.queryParameters['admin'] == 'true',
                ),
              ),
              GoRoute(
                path: 'jobs',
                builder: (context, state) => WorldJobsScreen(
                  worldId: state.pathParameters['worldId']!,
                  canManage:
                      state.uri.queryParameters['admin'] == 'true',
                ),
              ),
              GoRoute(
                path: 'archive',
                builder: (context, state) => WorldArchiveScreen(
                  worldId: state.pathParameters['worldId']!,
                ),
              ),
              GoRoute(
                path: 'academy',
                builder: (context, state) => WorldAcademyScreen(
                  worldId: state.pathParameters['worldId']!,
                  isSovereignOrCouncil:
                      state.uri.queryParameters['admin'] == 'true',
                ),
              ),
              GoRoute(
                path: 'sanctuary',
                builder: (context, state) => WorldSanctuaryScreen(
                  worldId: state.pathParameters['worldId']!,
                  isSovereignOrCouncil:
                      state.uri.queryParameters['admin'] == 'true',
                ),
              ),
              GoRoute(
                path: 'manage',
                builder: (context, state) => WorldManageScreen(
                  worldId: state.pathParameters['worldId']!,
                ),
              ),
              GoRoute(
                path: 'governance',
                builder: (context, state) => WorldGovernanceScreen(
                  worldId: state.pathParameters['worldId']!,
                  worldName: state.uri.queryParameters['name'],
                ),
              ),
              GoRoute(
                path: ':channelName',
                redirect: (context, state) {
                  final worldId = state.pathParameters['worldId']!;
                  final segment = state.pathParameters['channelName']!;
                  final reserved = redirectReservedWorldSubRoute(
                    worldId: worldId,
                    segment: segment,
                    query: state.uri.query,
                  );
                  if (reserved != null) return reserved;
                  return redirectMissingChannelId(
                    worldId: worldId,
                    channelName: segment,
                    queryParams: state.uri.queryParameters,
                  );
                },
                  builder: (context, state) => WorldChannelRouteHandler(
                  worldId: state.pathParameters['worldId']!,
                  channelId: state.uri.queryParameters['id'] ?? '',
                  channelName: state.pathParameters['channelName']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/you',
        redirect: (context, state) => '/identity',
      ),
      GoRoute(
        path: '/more',
        redirect: (context, state) => '/identity',
      ),
      vGoRoute(
        path: '/notifications',
        builder: (context, state) => const AlertsScreen(),
      ),
      vGoRoute(
        path: '/residents/:id',
        builder: (context, state) => ResidentProfileScreen(
          residentId: state.pathParameters['id']!,
          highlightAchievementId: state.uri.queryParameters['achievement'],
        ),
      ),
      // Full-screen DM (single route — profile, search, Home DMs).
      vGoRoute(
        path: '/chat/:roomId',
        panelSlide: true,
        builder: (context, state) => ChatRoomScreen(
          roomId: state.pathParameters['roomId']!,
          initialPresence: state.extra is Presence
              ? state.extra! as Presence
              : null,
          initialDraft: state.uri.queryParameters['draft'],
          initialMessageId: state.uri.queryParameters['message'],
        ),
      ),
      GoRoute(
        path: '/dm/:roomId',
        redirect: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final q = state.uri.query;
          return q.isEmpty ? '/chat/$roomId' : '/chat/$roomId?$q';
        },
      ),
      vGoRoute(
        path: '/shop',
        builder: (context, state) => const CosmeticsShopScreen(),
      ),
      vGoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      if (kDebugMode)
        vGoRoute(
          path: '/debug/ui-spike',
          builder: (context, state) =>
              SpikeSettingsPage.fromQuery(state.uri.queryParameters['backend']),
        ),
      vGoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      vGoRoute(
        path: '/following',
        builder: (context, state) => const FollowingScreen(),
      ),
      vGoRoute(
        path: '/allies',
        builder: (context, state) => const AlliesScreen(),
      ),
      vGoRoute(
        path: '/progress',
        builder: (context, state) {
          final tab =
              ProgressTab.fromQuery(state.uri.queryParameters['tab']) ??
              ProgressTab.quests;
          return ProgressHubScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/season',
        redirect: (_, __) => progressPath(tab: ProgressTab.season),
      ),
      GoRoute(
        path: '/challenges',
        redirect: (_, __) => progressPath(tab: ProgressTab.world),
      ),
      GoRoute(
        path: '/daily-quests',
        redirect: (_, __) => progressPath(tab: ProgressTab.quests),
      ),
      GoRoute(
        path: '/leagues',
        redirect: (_, __) => progressPath(tab: ProgressTab.league),
      ),
      vGoRoute(
        path: '/coin-history',
        builder: (context, state) => const CoinHistoryScreen(),
      ),
      vGoRoute(
        path: '/hall-of-ascension',
        builder: (context, state) => const HallOfAscensionScreen(),
      ),
      vGoRoute(
        path: '/ascension-path',
        builder: (context, state) => const AscensionPathScreen(),
      ),
      vGoRoute(
        path: '/create-world',
        builder: (context, state) => const CreateWorldScreen(),
      ),
      vGoRoute(
        path: '/campfire/:channelId',
        slideUp: true,
        builder: (context, state) => CampfireRouteHandler(
          channelId: state.pathParameters['channelId']!,
          channelName: state.uri.queryParameters['name'] ?? 'Campfire',
          worldId: state.uri.queryParameters['worldId'] ?? '',
          worldName: state.uri.queryParameters['worldName'] ?? '',
        ),
      ),
      vGoRoute(
        path: '/thread/:messageId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final parentMessage = extra?['message'] as ChannelMessage?;
          if (parentMessage == null) {
            return ThreadDeepLinkScreen(
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
      vGoRoute(
        path: '/audit-log/:worldId',
        builder: (context, state) => AuditLogScreen(
          worldId: state.pathParameters['worldId']!,
          worldName: state.uri.queryParameters['name'] ?? 'World',
        ),
      ),
      GoRoute(
        path: '/verifier/login',
        builder: (context, state) => const VerifierLoginScreen(),
      ),
      GoRoute(
        path: '/verifier/review',
        builder: (context, state) => const VerificationReviewScreen(),
      ),
      GoRoute(
        path: '/twin-seal',
        builder: (context, state) => const TwinSealSetupScreen(),
      ),
      GoRoute(
        path: '/invite/:code',
        builder: (context, state) =>
            AcceptInviteScreen(code: state.pathParameters['code']!),
      ),
      // Deep-link: notifications
      GoRoute(
        path: '/notifications/:id',
        builder: (context, state) =>
            NotificationDeepLink(notificationId: state.pathParameters['id']!),
      ),
      // Deep-link: post detail
      GoRoute(
        path: '/post/:postId',
        builder: (context, state) =>
            PostDeepLink(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: '/post/:postId/comments',
        builder: (context, state) => PostCommentsScreen(
          postId: state.pathParameters['postId']!,
        ),
      ),
    ],
  );
});
