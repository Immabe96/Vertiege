import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/theme_provider.dart';
import 'state/resident_provider.dart';
import 'state/notification_provider.dart';
import 'state/achievement_provider.dart';
import 'state/post_provider.dart';
import 'state/world_provider.dart';
import 'state/event_provider.dart';
import 'state/quest_provider.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

class VirtualStatusWorldsApp extends ConsumerStatefulWidget {
  const VirtualStatusWorldsApp({super.key});

  @override
  ConsumerState<VirtualStatusWorldsApp> createState() => _VirtualStatusWorldsAppState();
}

class _VirtualStatusWorldsAppState extends ConsumerState<VirtualStatusWorldsApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStores());
  }

  Future<void> _loadStores() async {
    // Defer to post-frame to avoid rebuilding ProviderScope during build
    await ref.read(themeProvider.notifier).loadTheme();
    await ref.read(worldProvider.notifier).loadWorlds();
    await ref.read(residentProvider.notifier).loadResident();
    await ref.read(postProvider.notifier).loadPosts();
    await ref.read(notificationProvider.notifier).loadNotifications();
    await ref.read(achievementProvider.notifier).loadAchievements();
    ref.read(eventProvider);
    ref.read(questProvider);
    ref.read(residentProvider.notifier).touchPresence();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final isLoading = ref.watch(residentProvider).isLoading;
    final router = ref.watch(appRouterProvider);

    if (isLoading) {
      return MaterialApp(
        title: 'Vertiege',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeState.themeMode,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading worlds...'),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Vertiege',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeState.themeMode,
      routerConfig: router,
    );
  }
}
