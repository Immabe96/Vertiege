import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:forui/forui.dart';
import 'models/notification.dart';
import 'state/theme_provider.dart';
import 'state/resident_provider.dart';
import 'state/notification_provider.dart';
import 'state/achievement_provider.dart';
import 'state/post_provider.dart';
import 'state/world_provider.dart';
import 'state/event_provider.dart';
import 'state/quest_provider.dart';
import 'state/league_provider.dart';
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
import 'services/firebase_bootstrap.dart';
import 'services/firebase_messaging_handlers.dart';
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
  StreamSubscription<RemoteMessage>? _foregroundPushSubscription;
  String? _residentServicesInitializedFor;
  final Set<String> _recentNotificationSnackIds = {};

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
    _foregroundPushSubscription = PushTokenService.foregroundMessages.listen(
      _showForegroundPush,
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
    unawaited(_safeLoad('league', ref.read(leagueProvider.notifier).loadLeague));
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
    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      await _initializeResidentServices(resident.id);
    }
  }

  Future<void> _initializeResidentServices(String residentId) async {
    if (_residentServicesInitializedFor == residentId) return;
    _residentServicesInitializedFor = residentId;

    try {
      final resident = ref.read(residentProvider).resident;
      if (resident == null || resident.id != residentId) return;

      CrashReporter.instance.setUser(resident.id, name: resident.name);
      unawaited(AnalyticsService.setUser(resident.id));
      final initialRoute = await PushTokenService.initializeForResident(
        resident.id,
      );
      if (initialRoute != null && mounted) {
        ref.read(appRouterProvider).go(initialRoute);
      }
      await PushService.initialize(userId: resident.id);
      unawaited(
        _safeLoad(
          'notifications',
          ref.read(notificationProvider.notifier).loadNotifications,
        ),
      );
      unawaited(_safeLoad('posts', ref.read(postProvider.notifier).loadPosts));
      unawaited(
        _safeLoad('bookmarks', ref.read(postProvider.notifier).loadBookmarks),
      );

      final fbOk = FirebaseBootstrap.isInitialized;
      unawaited(
        StorageService.setString('fb_status', fbOk ? 'connected' : 'offline'),
      );
      if (!fbOk) {
        final err = '${FirebaseBootstrap.lastError ?? "unknown"}';
        unawaited(StorageService.setString('fb_error', err));
      } else {
        unawaited(StorageService.remove('fb_error'));
      }
    } catch (e) {
      _residentServicesInitializedFor = null;
      debugPrint('PushService init failed: $e');
      _showStatusSnackbar('Notification setup needs attention.');
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

  void _showStatusSnackbar(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _showForegroundPush(RemoteMessage message) {
    final id =
        message.data['notification_id'] ??
        message.data['notificationId'] ??
        message.messageId ??
        message.sentTime?.millisecondsSinceEpoch.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final title = message.notification?.title ?? 'Vertiege';
    final body =
        message.notification?.body ??
        message.data['message']?.toString() ??
        'You have a new notification.';
    _showInAppNotification(
      id: id.toString(),
      title: title,
      body: body,
      route: routeFromRemoteMessage(message),
    );
  }

  void _showRealtimeNotification(
    NotificationState? previous,
    NotificationState next,
  ) {
    if (previous == null || previous.isLoading) return;
    final previousIds = previous.notifications.map((n) => n.id).toSet();
    final fresh = next.notifications
        .where((n) => !n.read && !previousIds.contains(n.id))
        .toList();
    if (fresh.isEmpty) return;

    final notification = fresh.first;
    _showInAppNotification(
      id: notification.id,
      title: _notificationTitle(notification.type),
      body: notification.message,
      route: _routeForNotification(notification),
    );
  }

  void _showInAppNotification({
    required String id,
    required String title,
    required String body,
    String? route,
  }) {
    if (!mounted || !_markNotificationSnackShown(id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$title\n$body', maxLines: 3),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: route == null
              ? null
              : SnackBarAction(
                  label: 'Open',
                  onPressed: () => ref.read(appRouterProvider).go(route),
                ),
        ),
      );
    });
  }

  bool _markNotificationSnackShown(String id) {
    if (_recentNotificationSnackIds.contains(id)) return false;
    _recentNotificationSnackIds.add(id);
    Timer(const Duration(seconds: 30), () {
      _recentNotificationSnackIds.remove(id);
    });
    return true;
  }

  String _notificationTitle(NotificationType type) => switch (type) {
    NotificationType.like => 'New reaction',
    NotificationType.comment => 'New comment',
    NotificationType.worldUnlocked => 'World unlocked',
    NotificationType.tierUpgrade => 'Tier upgraded',
    NotificationType.welcome => 'Welcome',
    NotificationType.modAction => 'Moderation update',
    NotificationType.ranking => 'World ranking',
    NotificationType.streakReminder => 'Streak reminder',
    NotificationType.reactionMilestone => 'Reaction milestone',
    NotificationType.mention => 'Mention',
    NotificationType.allegianceRequest => 'Allegiance request',
  };

  String _routeForNotification(AppNotification notification) {
    if (notification.postId != null) return '/post/${notification.postId}';
    if (notification.worldId != null) return '/explore/${notification.worldId}';
    return '/notifications/${notification.id}';
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
    _foregroundPushSubscription?.cancel();
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
    ref.listen<ResidentState>(residentProvider, (previous, next) {
      final resident = next.resident;
      if (resident == null) return;
      unawaited(_initializeResidentServices(resident.id));
    });
    ref.listen<NotificationState>(
      notificationProvider,
      _showRealtimeNotification,
    );

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
