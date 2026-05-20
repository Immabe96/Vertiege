import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:forui/forui.dart';
import 'state/theme_provider.dart';
import 'state/resident_provider.dart';
import 'state/notification_provider.dart';
import 'state/achievement_provider.dart';
import 'state/post_provider.dart';
import 'state/world_provider.dart';
import 'state/event_provider.dart';
import 'state/quest_provider.dart';
import 'theme/app_theme.dart';
import 'theme/forui_theme.dart';
import 'router/app_router.dart';
import 'screens/splash_screen.dart';
import 'services/daily_reward_service.dart';
import 'services/storage_service.dart';
import 'services/store_service.dart';
import 'services/push_service.dart';
import 'services/push_token_service.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporter.dart';
import 'widgets/core/daily_reward_dialog.dart';
import 'widgets/core/offline_banner.dart';

class VirtualStatusWorldsApp extends ConsumerStatefulWidget {
  const VirtualStatusWorldsApp({super.key});

  @override
  ConsumerState<VirtualStatusWorldsApp> createState() =>
      _VirtualStatusWorldsAppState();
}

class _VirtualStatusWorldsAppState extends ConsumerState<VirtualStatusWorldsApp>
    with WidgetsBindingObserver {
  bool _showSplash = true;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<String>? _notificationRouteSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted) setState(() => _isOnline = !offline);
    });
    _notificationRouteSubscription = PushTokenService.notificationRoutes.listen(
      (route) {
        if (!mounted) return;
        ref.read(appRouterProvider).go(route);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBackgroundLoads();
      _waitForCriticalLoads();
      _checkDailyReward();
    });
  }

  Future<void> _waitForCriticalLoads() async {
    try {
      await Future.wait([
        ref.read(residentProvider.notifier).loadResident(),
        ref.read(worldProvider.notifier).loadWorlds(),
      ]).timeout(const Duration(seconds: 3));
    } catch (_) {}
    if (mounted) setState(() => _showSplash = false);
  }

  /// Fire-and-forget all data loads independently. No provider blocks another.
  void _startBackgroundLoads() {
    // Each provider loads independently — failures are silent and non-blocking
    ref.read(themeProvider.notifier).loadFromPrefs(); // fire-and-forget
    unawaited(_safeLoad('worlds', ref.read(worldProvider.notifier).loadWorlds));
    unawaited(
      _safeLoad('resident', ref.read(residentProvider.notifier).loadResident),
    );
    unawaited(_safeLoad('posts', ref.read(postProvider.notifier).loadPosts));
    unawaited(
      _safeLoad('bookmarks', ref.read(postProvider.notifier).loadBookmarks),
    );
    unawaited(
      _safeLoad(
        'notifications',
        ref.read(notificationProvider.notifier).loadNotifications,
      ),
    );
    unawaited(
      _safeLoad(
        'achievements',
        ref.read(achievementProvider.notifier).loadAchievements,
      ),
    );
    unawaited(_safeLoad('events', ref.read(eventProvider.notifier).loadEvents));
    unawaited(_safeLoad('quests', ref.read(questProvider.notifier).loadQuests));
    ref.read(residentProvider.notifier).touchPresence(); // fire-and-forget

    // Initialize push notifications and IAP store
    unawaited(_safeInitServices());
  }

  Future<void> _safeInitServices() async {
    try {
      await StoreService.init();
    } catch (e) {
      debugPrint('StoreService init failed: $e');
    }
    try {
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        CrashReporter.instance.setUser(resident.id, name: resident.name);
        unawaited(AnalyticsService.setUser(resident.id));
        final initialRoute = await PushTokenService.initializeForResident(
          resident.id,
        );
        if (initialRoute != null && mounted) {
          ref.read(appRouterProvider).go(initialRoute);
        }
        await PushService.initialize(userId: resident.id);
      }
    } catch (e) {
      debugPrint('PushService init failed: $e');
    }
  }

  Future<void> _safeLoad(String name, Future<void> Function() load) async {
    try {
      await load().timeout(const Duration(seconds: 5));
    } catch (e, st) {
      debugPrint('Splash: $name load failed/timed out');
      CrashReporter.instance.recordError(
        e,
        st,
        hint: 'splash background load: $name',
      );
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
              ref
                  .read(residentProvider.notifier)
                  .addXpFromDailyReward(reward.xpValue);
            }
          },
        );
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _notificationRouteSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      StorageService.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);
    final textScaler = TextScaler.linear(themeState.textScale);

    if (_showSplash) {
      return MaterialApp(
        title: 'Vertiege',
        debugShowCheckedModeBanner: false,
        supportedLocales: FLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...FLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const SplashScreen(),
        builder: (context, child) =>
            _withForui(context, textScaler, child!, isDark: false),
      );
    }

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final useDarkForui = switch (themeState.scheme) {
      ThemeScheme.light => false,
      ThemeScheme.dark => true,
      ThemeScheme.system => platformBrightness == Brightness.dark,
    };

    return MaterialApp.router(
      title: 'Vertiege',
      debugShowCheckedModeBanner: false,
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...FLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeState.themeMode,
      routerConfig: router,
      builder: (context, child) => _withForui(
        context,
        textScaler,
        OfflineBanner(show: !_isOnline, child: child!),
        isDark: useDarkForui,
      ),
    );
  }

  Widget _withForui(
    BuildContext context,
    TextScaler textScaler,
    Widget child, {
    required bool isDark,
  }) {
    return FTheme(
      data: isDark ? VertiegeForuiTheme.dark : VertiegeForuiTheme.light,
      child: FToaster(
        child: FTooltipGroup(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child,
          ),
        ),
      ),
    );
  }
}
