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
import 'theme/design_system.dart';
import 'router/app_router.dart';
import 'screens/splash_screen.dart';

class VirtualStatusWorldsApp extends ConsumerStatefulWidget {
  const VirtualStatusWorldsApp({super.key});

  @override
  ConsumerState<VirtualStatusWorldsApp> createState() =>
      _VirtualStatusWorldsAppState();
}

class _VirtualStatusWorldsAppState
    extends ConsumerState<VirtualStatusWorldsApp> {
  bool _showSplash = true;
  bool _storesLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStores());
  }

  Future<void> _loadStores() async {
    try {
      await ref.read(themeProvider.notifier).loadTheme();
    } catch (_) { /* non-critical */ }
    try {
      await ref.read(worldProvider.notifier).loadWorlds();
    } catch (_) { /* degraded — worlds load on Explore screen */ }
    try {
      await ref.read(residentProvider.notifier).loadResident();
    } catch (_) { /* resident may be null, router redirects to onboarding */ }
    try {
      await ref.read(postProvider.notifier).loadPosts();
    } catch (_) { /* feed appears empty, user can pull-to-refresh */ }
    try {
      await ref.read(notificationProvider.notifier).loadNotifications();
    } catch (_) { /* notifications appear empty */ }
    try {
      await ref.read(achievementProvider.notifier).loadAchievements();
    } catch (_) { /* achievements appear empty */ }
    try {
      ref.read(eventProvider);
    } catch (_) {}
    try {
      ref.read(questProvider);
    } catch (_) {}
    try {
      ref.read(residentProvider.notifier).touchPresence();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _storesLoaded = true);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    if (_showSplash) {
      return MaterialApp(
        title: 'Vertiege',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeState.themeMode,
        home: AnimatedSwitcher(
          duration: AnimDurations.normal,
          child: _storesLoaded
              ? const SizedBox.shrink()
              : const SplashScreen(),
        ),
      );
    }

    final router = ref.watch(appRouterProvider);

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
