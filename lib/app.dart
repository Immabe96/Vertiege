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
import 'state/ally_provider.dart';
import 'state/chat_provider.dart';
import 'theme/v_theme.dart';
import 'theme/forui_theme.dart';
import 'router/app_router.dart';
import 'router/navigation_keys.dart';
import 'router/notification_navigation.dart';
import 'screens/splash_screen.dart';
import 'services/daily_reward_service.dart';
import 'services/storage_service.dart';
import 'services/store_service.dart';
import 'services/push_service.dart';
import 'services/achievement_realtime_service.dart';
import 'services/resident_realtime_service.dart';
import 'services/push_token_service.dart';
import 'services/analytics_events.dart';
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
import 'widgets/core/whats_new_dialog.dart';
import 'widgets/core/mutation_outbox_sync_banner.dart';
import 'widgets/core/offline_banner.dart';
import 'widgets/core/v_app_banner.dart';
import 'widgets/core/v_feedback.dart';
import 'ui/buttons/v_button.dart';
import 'widgets/nexus/nexus_moment_sheet.dart';

class VirtualStatusWorldsApp extends ConsumerStatefulWidget {
  const VirtualStatusWorldsApp({super.key});

  @override
  ConsumerState<VirtualStatusWorldsApp> createState() =>
      _VirtualStatusWorldsAppState();
}

class _VirtualStatusWorldsAppState extends ConsumerState<VirtualStatusWorldsApp>
    with WidgetsBindingObserver {
  final bool _showSplash = false;
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
    _refreshRemoteGates();

    final hasSession = maybeSupabase()?.auth.currentSession != null;
    if (!hasSession) return;

    unawaited(_bootstrapServices());
    _attachRuntimeListeners();
    _flushPendingNotificationRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _scheduleBackgroundLoads();
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

    if (!SupabaseBootstrap.isReady) {
      final result = await SupabaseBootstrap.initialize();
      if (result != SupabaseBootstrapResult.ready) {
        debugPrint('Supabase bootstrap not ready: $result');
        if (mounted) setState(() => _supabaseBootstrapFailed = true);
        return;
      }
    }

    if (!mounted) return;
    unawaited(ref.read(residentProvider.notifier).loadResident());
  }

  /// Staggered secondary loads so Nexus stays responsive after sign-in.
  void _scheduleBackgroundLoads() {
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      unawaited(_safeLoad('posts', ref.read(postProvider.notifier).loadPosts));
      unawaited(_safeLoad('worlds', ref.read(worldProvider.notifier).loadWorlds));
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      unawaited(
        _safeLoad(
          'notifications',
          ref.read(notificationProvider.notifier).loadNotifications,
        ),
      );
    });
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      unawaited(
        _safeLoad('bookmarks', ref.read(postProvider.notifier).loadBookmarks),
      );
      unawaited(
        _safeLoad(
          'achievements',
          ref.read(achievementProvider.notifier).loadAchievements,
        ),
      );
    });
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      unawaited(_safeLoad('events', ref.read(eventProvider.notifier).loadEvents));
      unawaited(_safeLoad('quests', ref.read(questProvider.notifier).loadQuests));
      unawaited(_safeLoad('league', ref.read(leagueProvider.notifier).loadLeague));
      final residentId = ref.read(residentProvider).resident?.id;
      if (residentId != null) {
        unawaited(
          _safeLoad(
            'dm_rooms',
            () => ref.read(chatProvider.notifier).loadDmRooms(residentId),
          ),
        );
      }
      unawaited(_safeInitResidentServices());
    });
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      unawaited(_safeInitStore());
    });
  }

  void _onResidentSignedIn() {
    void afterReady() {
      if (!mounted) return;
      _attachRuntimeListeners();
      _flushPendingNotificationRoute();
      _scheduleBackgroundLoads();
    }

    if (!FirebaseBootstrap.isInitialized) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        unawaited(_bootstrapServices().then((_) => afterReady()));
      });
    } else {
      Future<void>.delayed(const Duration(milliseconds: 500), afterReady);
    }
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      final resident = ref.read(residentProvider).resident;
      if (!mounted || resident == null) return;
      unawaited(_initializeResidentServices(resident.id));
    });
  }

  Future<void> _safeInitResidentServices() async {
    try {
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        await _initializeResidentServices(resident.id);
      }
    } catch (e) {
      debugPrint('Resident services init failed: $e');
    }
  }

  Future<void> _safeInitStore() async {
    try {
      await StoreService.init();
    } catch (e) {
      debugPrint('StoreService init failed: $e');
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
      await AchievementRealtimeService.initialize(
        userId: resident.id,
        onVerified: () {
          if (!mounted) return;
          unawaited(
            ref
                .read(achievementProvider.notifier)
                .reloadAndCelebrateRemoteVerifications(),
          );
        },
      );
      await ResidentRealtimeService.initialize(
        userId: resident.id,
        onGamificationChange: () {
          if (!mounted) return;
          unawaited(
            ref
                .read(residentProvider.notifier)
                .refreshFromServerAndCelebrateTier(),
          );
        },
        onIdentityVerified: () {
          if (!mounted) return;
          unawaited(
            ref.read(residentProvider.notifier).loadResident().then((_) {
              if (!mounted) return;
              VFeedback.showMessage(
                context,
                'Identity verified — your resident tick is now active.',
              );
            }),
          );
        },
      );
      unawaited(ref.read(allyProvider.notifier).loadAll(resident.id));
      // Posts, bookmarks, notifications, DMs load after splash via _startBackgroundLoads.

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

  void _refreshChatFromForegroundDmPush(RemoteMessage message) {
    final roomId =
        message.data['room_id'] ??
        message.data['roomId'] ??
        message.data['dm_room_id'];
    if (roomId is! String || roomId.isEmpty) return;

    final chat = ref.read(chatProvider.notifier);
    chat.subscribeToDm(roomId);
    unawaited(chat.loadDmMessages(roomId));

    final residentId = ref.read(residentProvider).resident?.id;
    if (residentId != null) {
      final hasRoom = ref.read(chatProvider).dmRooms.any((r) => r['id'] == roomId);
      if (!hasRoom) {
        unawaited(chat.loadDmRooms(residentId));
      }
    }
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
    if (ChatNotificationScope.shouldSuppressRemote(
      type: type,
      roomId: message.data['room_id']?.toString(),
      channelId: message.data['channel_id']?.toString(),
    )) {
      return;
    }
    if (type == 'dmMessage') {
      _refreshChatFromForegroundDmPush(message);
      return;
    }
    if (type == 'achievementApproved') {
      unawaited(
        ref
            .read(achievementProvider.notifier)
            .reloadAndCelebrateRemoteVerifications(),
      );
    }
    if (type == 'identityVerified') {
      unawaited(ref.read(residentProvider.notifier).loadResident());
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
    if (ChatNotificationScope.shouldSuppressNotification(notification)) {
      return;
    }
    if (notification.type == NotificationType.achievementApproved) {
      unawaited(
        ref
            .read(achievementProvider.notifier)
            .reloadAndCelebrateRemoteVerifications(),
      );
    }
    if (notification.type == NotificationType.identityVerified) {
      unawaited(ref.read(residentProvider.notifier).loadResident());
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
    NotificationType.identityVerified => 'Identity verified',
    NotificationType.identityRejected => 'Identity review',
    NotificationType.jobApplicationAccepted => 'Role application',
    NotificationType.jobApplicationRejected => 'Role application',
    NotificationType.governanceProposalApproved => 'Proposal approved',
    NotificationType.governanceProposalRejected => 'Proposal declined',
    NotificationType.unknown => '',
  };

  String? _routeForNotification(AppNotification notification) =>
      routeForNotification(notification);

  void _checkWhatsNew() {
    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      final dialogContext = appRootNavigatorKey.currentContext;
      if (dialogContext == null) return;
      await showWhatsNewDialogIfNeeded(dialogContext);
    });
  }

  void _checkDailyReward() {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final todayKey = DailyRewardService.todayKey();
    StorageService.getString(todayKey).then((claimed) {
      if (claimed == 'true' || !mounted) return;

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        final dialogContext = appRootNavigatorKey.currentContext;
        if (dialogContext == null) return;
        final reward = DailyRewardService.getDailyReward(resident.id);

        DailyRewardDialog.show(
          dialogContext,
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

  Future<void> _tryDailyStreakCheckIn() async {
    final result = await ref.read(residentProvider.notifier).checkInToday();
    if (!mounted || result == null) return;
    final dialogContext = appRootNavigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) return;
    if (result.shieldUsed) {
      unawaited(
        AnalyticsService.logEvent(AnalyticsEvents.streakShieldUsed),
      );
      VFeedback.showMessage(
        dialogContext,
        'Streak shield used — your streak continues.',
      );
    } else if (result.bonusXp > 0) {
      VFeedback.showMessage(
        dialogContext,
        'Day ${result.streak} streak · +${result.bonusXp} XP',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(postProvider.notifier).setRealtimePaused(false));
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        unawaited(ref.read(residentProvider.notifier).touchPresence());
        ref.read(residentProvider.notifier).checkStreakRisk();
        unawaited(_tryDailyStreakCheckIn());
      }
    }
    if (state == AppLifecycleState.paused) {
      unawaited(ref.read(postProvider.notifier).setRealtimePaused(true));
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
        _onResidentSignedIn();
        unawaited(ref.read(residentProvider.notifier).touchPresence());
        _checkDailyReward();
        _checkWhatsNew();
        unawaited(_tryDailyStreakCheckIn());
      }
    });
    ref.listen<NotificationState>(
      notificationProvider,
      _showRealtimeNotification,
    );
    ref.listen<AchievementState>(achievementProvider, (previous, next) {
      final prevIds = previous?.recentlyUnlockedIds ?? const [];
      for (final id in next.recentlyUnlockedIds) {
        if (prevIds.contains(id)) continue;
        VFeedback.showAchievementUnlock(
          context,
          achievementId: id,
          subtitle: 'Verified — share your Nexus moment?',
          onShareToNexus: () => showNexusMomentSheet(context, achievementId: id),
        );
      }
    });

    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);
    final textScaler = TextScaler.linear(themeState.textScale);

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
      theme: VTheme.dark,
      darkTheme: VTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        final shell = _applyA11yColorAdjustments(
          themeState,
          _withForui(
          context,
          textScaler,
          themeState,
          Column(
            children: [
              if (_buildBlocked)
                const VAppBanner(
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
                  action: VButton(
                    label: 'Retry',
                    onPressed: () {
                      setState(() => _supabaseBootstrapFailed = false);
                      unawaited(_bootstrapServices());
                    },
                    variant: ButtonVariant.text,
                    size: ButtonSize.small,
                  ),
                ),
              const MutationOutboxSyncBanner(),
              Expanded(
                child: OfflineBanner(
                  show: !_isOnline,
                  onRetry: _retryAfterOffline,
                  child: child!,
                ),
              ),
            ],
          ),
        ),
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

  Widget _applyA11yColorAdjustments(ThemeState state, Widget child) {
    final c = state.effectiveContrast;
    if (state.saturation == 1.0 && c == 1.0) return child;
    final s = state.saturation;
    final translate = (1 - c) * 128;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        c * s, 0, 0, 0, translate,
        0, c * s, 0, 0, translate,
        0, 0, c * s, 0, translate,
        0, 0, 0, 1, 0,
      ]),
      child: child,
    );
  }

  Widget _withForui(
    BuildContext context,
    TextScaler textScaler,
    ThemeState themeState,
    Widget child,
  ) {
    final materialColor = Theme.of(context).colorScheme.surface;
    final forui = VertiegeForuiTheme.dark;
    return FTheme(
      data: forui,
      child: FToaster(
        child: FTooltipGroup(
          child: Material(
            color: materialColor,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
