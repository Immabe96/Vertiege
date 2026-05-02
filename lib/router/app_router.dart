import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/resident_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/tabs/tab_layout.dart';
import '../screens/tabs/nexus_screen.dart';
import '../screens/tabs/explore_screen.dart';
import '../screens/tabs/chat_list_screen.dart';
import '../screens/tabs/identity_screen.dart';
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
import '../screens/auth/auth_callback.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final resident = ref.watch(residentProvider).resident;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.uri.path;
      final isOnboarding = location == '/onboarding';
      final isAuthCallback = location == '/auth/callback';

      if (isAuthCallback) return null;

      if (resident == null && !isOnboarding) return '/onboarding';
      if (resident != null && isOnboarding) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
                          channelId: '',
                          channelName: state.pathParameters['channelName']!,
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alerts',
                builder: (context, state) => const AlertsScreen(),
              ),
            ],
          ),
        ],
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
        path: '/create-world',
        builder: (context, state) => const CreateWorldScreen(),
      ),
    ],
  );
});
