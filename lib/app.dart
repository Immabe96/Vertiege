import 'dart:async';
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
import 'screens/splash_screen.dart';
import 'services/daily_reward_service.dart';
import 'services/storage_service.dart';
import 'widgets/core/daily_reward_dialog.dart';

class VirtualStatusWorldsApp extends ConsumerStatefulWidget {
  const VirtualStatusWorldsApp({super.key});

  @override
  ConsumerState<VirtualStatusWorldsApp> createState() =>
      _VirtualStatusWorldsAppState();
}

class _VirtualStatusWorldsAppState
    extends ConsumerState<VirtualStatusWorldsApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Timer FIRST — guaranteed to fire regardless of anything else
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSplash = false);
    });
    // Loads run independently in the background after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try { _startBackgroundLoads(); } catch (_) {}
      try { _checkDailyReward(); } catch (_) {}
    });
  }

  /// Fire-and-forget all data loads independently. No provider blocks another.
  void _startBackgroundLoads() {
    // Each provider loads independently — failures are silent and non-blocking
    ref.read(themeProvider.notifier).loadTheme(); // fire-and-forget
    unawaited(_safeLoad('worlds', ref.read(worldProvider.notifier).loadWorlds));
    unawaited(_safeLoad('resident', ref.read(residentProvider.notifier).loadResident));
    unawaited(_safeLoad('posts', ref.read(postProvider.notifier).loadPosts));
    unawaited(_safeLoad('bookmarks', ref.read(postProvider.notifier).loadBookmarks));
    unawaited(_safeLoad('notifications', ref.read(notificationProvider.notifier).loadNotifications));
    unawaited(_safeLoad('achievements', ref.read(achievementProvider.notifier).loadAchievements));
    unawaited(_safeLoad('events', ref.read(eventProvider.notifier).loadEvents));
    unawaited(_safeLoad('quests', ref.read(questProvider.notifier).loadQuests));
    ref.read(residentProvider.notifier).touchPresence(); // fire-and-forget
  }

  Future<void> _safeLoad(String name, Future<void> Function() load) async {
    try {
      await load().timeout(const Duration(seconds: 5));
    } catch (_) {
      debugPrint('Splash: $name load failed/timed out');
    }
  }

  void _checkDailyReward() {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final todayKey = DailyRewardService.todayKey();
    StorageService.getString(todayKey).then((claimed) {
      if (claimed == 'true' || !mounted) return;

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        final reward = DailyRewardService.getDailyReward(resident.id);

        DailyRewardDialog.show(
          context,
          reward: reward,
          onCollect: () {
            StorageService.setString(todayKey, 'true');
            if (reward.isShield) {
              ref.read(residentProvider.notifier).addStreakShield();
            } else if (reward.xpValue > 0) {
              ref.read(residentProvider.notifier).addXpFromDailyReward(reward.xpValue);
            }
          },
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        title: 'Vertiege',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      );
    }

    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Vertiege',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      themeMode: themeState.themeMode,
      routerConfig: router,
    );
  }
}
