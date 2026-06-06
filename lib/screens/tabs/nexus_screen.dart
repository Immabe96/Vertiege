import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vertiege/ui/ui.dart';

import '../../router/search_navigation.dart';
import '../../services/notification_onboarding_prefs.dart';
import '../../services/onboarding_funnel_prefs.dart';
import '../../services/onboarding_funnel_sync.dart';
import '../../services/world_service.dart';
import '../../state/notification_provider.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/tab_aware_sheet.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/nexus/nexus_feed_body.dart';
import '../../widgets/onboarding/notification_permission_sheet.dart';
import '../tabs/nexus_notifications_sheet.dart';

class NexusScreen extends ConsumerStatefulWidget {
  const NexusScreen({super.key});

  @override
  ConsumerState<NexusScreen> createState() => _NexusScreenState();
}

class _NexusScreenState extends ConsumerState<NexusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_onNexusOpened());
    });
  }

  void _syncNexusRealtime() {
    final joinedIds =
        ref
            .read(residentProvider)
            .resident
            ?.joinedWorldIds
            .where(WorldService.isRemoteWorldId)
            .toSet() ??
        {};
    unawaited(ref.read(postProvider.notifier).setNexusRealtimeScope(joinedIds));
  }

  Future<void> _onNexusOpened() async {
    _syncNexusRealtime();
    final residentId = ref.read(residentProvider).resident?.id;
    if (residentId != null) {
      await OnboardingFunnelSync.markOpenedNexus(residentId);
    } else {
      await OnboardingFunnelPrefs.markOpenedNexus();
    }
    if (!mounted) return;
    final welcome = await OnboardingFunnelPrefs.consumeJustFinishedOnboarding();
    if (welcome && mounted) {
      VFeedback.showMessage(
        context,
        'Welcome! Your Nexus feed fills as you join worlds and share standing.',
      );
    }
    if (!mounted) return;
    if (await NotificationOnboardingPrefs.shouldPrompt()) {
      await showNotificationPermissionSheet(context);
    }
  }

  void _showNotifications() {
    showTabAwareModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const NexusNotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      residentProvider.select((s) => s.resident?.joinedWorldIds),
      (previous, next) {
        if (previous == next) return;
        _syncNexusRealtime();
      },
    );

    final theme = Theme.of(context);

    final headerActions = <Widget>[
      VAccessibleHeaderAction(
        label: 'Search residents and worlds',
        icon: Icon(VIcons.search),
        onPress: () => openGlobalSearch(context),
      ),
      VAccessibleHeaderAction(
        label: 'Notifications',
        icon: Consumer(
          builder: (context, ref, _) {
            final unread = ref.watch(
              notificationProvider.select(
                (s) => s.notifications.where((n) => !n.read).length,
              ),
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(VIcons.bell),
                if (unread > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: VColors.error,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: VColors.onError,
                          fontSize: VFontSize.labelSm,
                          fontWeight: VFontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        onPress: _showNotifications,
      ),
    ];

    return VTabPage(
      header: VHeader(
        title: Text(
          'Vertiege',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
        suffixes: headerActions,
      ),
      body: const NexusFeedBody(),
    );
  }
}
