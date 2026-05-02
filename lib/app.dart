import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/theme_provider.dart';
import 'state/resident_provider.dart';
import 'state/notification_provider.dart';
import 'state/achievement_provider.dart';
import 'state/post_provider.dart';
import 'state/world_provider.dart';
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
    _loadStores();
  }

  Future<void> _loadStores() async {
    await Future.wait(<Future<void>>[
      ref.read(themeProvider.notifier).loadTheme(),
      ref.read(worldProvider.notifier).loadWorlds(),
      ref.read(residentProvider.notifier).loadResident(),
      ref.read(postProvider.notifier).loadPosts(),
      ref.read(notificationProvider.notifier).loadNotifications(),
      ref.read(achievementProvider.notifier).loadAchievements(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
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
