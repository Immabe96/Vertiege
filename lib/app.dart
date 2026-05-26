import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:forui/forui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'state/ally_provider.dart';
import 'theme/app_theme.dart';
import 'theme/forui_theme.dart';
import 'router/app_router.dart';
import 'router/notification_navigation.dart';
import 'screens/splash_screen.dart';
import 'services/daily_reward_service.dart';
import 'services/storage_service.dart';
import 'services/store_service.dart';
import 'services/push_service.dart';
import 'services/push_token_service.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporter.dart';
import 'config/build_info.dart';
import 'services/feature_flags.dart';
import 'services/firebase_bootstrap.dart';
import 'services/supabase.dart';
import 'services/supabase_bootstrap.dart';
import 'services/firebase_messaging_handlers.dart';
import 'services/local_notification_service.dart';
import 'services/chat_notification_scope.dart';
import 'widgets/core/daily_reward_dialog.dart';
import 'widgets/core/offline_banner.dart';
import 'widgets/core/v_app_banner.dart';
import 'widgets/core/v_feedback.dart';

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
  bool _supabaseBootstrapFailed = false;
  String? _maintenanceBanner;
  bool _buildBlocked = false;
  String? _pendingNotificationRoute;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startup());
    });
  }

  void _attachRuntimeListeners() {
    unawaited(
      LocalNotificationService.initialize(
        onNavigate: (route) {
          if (!mounted) return;
          ref.read(appRouterProvider).go(route);
        },
      ),
    );
    _flushPendingNotificationRoute();
    _notificationRouteSubscription ??=
        PushTokenService.notificationRoutes.listen((route) {
      if (!mounted) return;
      if (_showSplash) {
        _pendingNotificationRoute = route;
        return;
      }
      ref.read(appRouterProvider).go(route);
    });
    _foregroundPushSubscription ??=
        PushTokenService.foregroundMessages.listen(_showForegroundPush);
  }

  Future<void> _startup() async {
    // Never block the splash on network — bootstrap runs in parallel.
    unawaited(_bootstrapServices());

    await Future<void>.delayed(const Duration(milliseconds: 1800));

    final hasSession = maybeSupabase()?.auth.currentSession != null;
    if (hasSession && mounted) {
      final waitStart = DateTime.now();
      while (mounted && ref.read(residentProvider).isLoading) {
        if (DateTime.now().difference(waitStart) >
            const Duration(seconds: 6)) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    _refreshRemoteGates();

    if (!mounted) return;
    setState(() => _showSplash = false);
    _attachRuntimeListeners();
    _flushPendingNotificationRoute();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _startBackgroundLoads();
      });
    });
  }

  Future<void> _bootstrapServices() async {
    try {
      await FirebaseBootstrap.initializeCore().timeout(
        const Duration(seconds: 6),
      );
    } catch (e, st) {
      debugPrint('Firebase core bootstrap skipped: $e');
      CrashReporter.instance.recordError(
        e,
        st,
        hint: 'firebase bootstrap startup',
      );
    }

    unawaited(
      FirebaseBootstrap.initializeDeferred().catchError((Object e, StackTrace st) {
        CrashReporter.instance.recordError(
          e,
          st,
          hint: 'firebase deferred startup',
        );
      }),
    );

    if (!Supabase.instance.isInitialized) {
      final result = await SupabaseBootstrap.initialize();
      if (result != SupabaseBootstrapResult.ready) {
        debugPrint('Supabase bootstrap not ready: $result');
        if (mounted) setState(() => _supabaseBootstrapFailed = true);
        return;
      }
    }

    if (!mounted) return;
    unawaited(ref.read(residentProvider.notifier).loadResident());
    unawaited(ref.read(worldProvider.notifier).loadWorlds());
  }

  /// Fire-and-forget secondary loads after login/home is visible.
  void _startBackgroundLoads() {
    unawaited(_safeLoad('posts', ref.read(postProvider.notifier).loadPosts));
    unawaited(
      _safeLoad('bookmarks', ref.read(postProvider.notifier).loadBookmarks),
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
        if (_showSplash) {
          _pendingNotificationRoute = initialRoute;
        } else {
          ref.read(appRouterProvider).go(initialRoute);
        }
      }
      await PushService.initialize(userId: resident.id);
      unawaited(ref.read(allyProvider.notifier).loadAll(resident.id));
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

  void _refreshRemoteGates() {
    final banner = FeatureFlags.maintenanceBanner.trim();
    final minBuild = FeatureFlags.minimumBuild;
    _maintenanceBanner = banner.isEmpty ? null : banner;
    _buildBlocked = kAppBuildNumber < minBuild;
  }

  void _flushPendingNotificationRoute() {
    final route = _pendingNotificationRoute;
    if (route == null || !mounted || _showSplash) return;
    _pendingNotificationRoute = null;
    ref.read(appRouterProvider).go(route);
  }

  void _retryAfterOffline() {
    if (!_isOnline) return;
    unawaited(ref.read(residentProvider.notifier).loadResident());
    unawaited(ref.read(worldProvider.notifier).loadWorlds());
  }

  void _showStatusSnackbar(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      VFeedback.showMessage(context, message);
    });
  }

  void _showForegroundPush(RemoteMessage message) {
    final type = message.data['type']?.toString() ?? '';
    if (type == 'dmMessage') {
      return;
    }
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
    if (notification.type == NotificationType.dmMessage) {
      final roomId = notification.roomId;
      if (roomId != null &&
          ChatNotificationScope.shouldSuppressDm(roomId)) {
        return;
      }
    }
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
      if (route == null) {
        VFeedback.showMessage(context, '$title\n$body');
        return;
      }
      VFeedback.showWithAction(
        context,
        message: '$title\n$body',
        actionLabel: 'Open',
        onAction: () => ref.read(appRouterProvider).go(route),
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
    NotificationType.dmMessage => 'New message',
    NotificationType.allegianceRequest => 'Allegiance request',
    NotificationType.achievementApproved => 'Achievement verified',
    NotificationType.achievementRejected => 'Achievement review',
  };

  String? _routeForNotification(AppNotification notification) =>
      routeForNotification(notification);

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
    if (state == AppLifecycleState.resumed) {
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        ref.read(residentProvider.notifier).checkStreakRisk();
      }
    }
    if (state == AppLifecycleState.paused) {
      StorageService.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(residentMilestoneListenerProvider);
    ref.listen<ResidentState>(residentProvider, (previous, next) {
      final resident = next.resident;
      if (resident == null) return;
      if (previous?.resident?.id != resident.id) {
        unawaited(_initializeResidentServices(resident.id));
        unawaited(ref.read(residentProvider.notifier).touchPresence());
        _checkDailyReward();
      }
    });
    ref.listen<NotificationState>(
      notificationProvider,
      _showRealtimeNotification,
    );

    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);
    final textScaler = TextScaler.linear(themeState.textScale);

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
      builder: (context, child) {
        final shell = _withForui(
          context,
          textScaler,
          Column(
            children: [
              if (_buildBlocked)
                VAppBanner(
                  variant: .destructive,
                  message:
                      'This build is outdated (v$kAppBuildNumber). '
                      'Please update Vertiege from the store.',
                )
              else if (_maintenanceBanner != null)
                VAppBanner(message: _maintenanceBanner!)
              else if (_supabaseBootstrapFailed)
                VAppBanner(
                  message:
                      'Cloud sync is unavailable. Check .env and network, then restart.',
                  action: TextButton(
                    onPressed: () {
                      setState(() => _supabaseBootstrapFailed = false);
                      unawaited(_bootstrapServices());
                    },
                    child: const Text('Retry'),
                  ),
                ),
              Expanded(
                child: OfflineBanner(
                  show: !_isOnline,
                  onRetry: _retryAfterOffline,
                  child: child!,
                ),
              ),
            ],
          ),
          isDark: useDarkForui,
        );
        if (!_showSplash) return shell;
        return Stack(
          fit: StackFit.expand,
          children: [
            shell,
            const Positioned.fill(child: SplashScreen()),
          ],
        );
      },
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
