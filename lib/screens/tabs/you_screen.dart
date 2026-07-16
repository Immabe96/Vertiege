import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../../config/onboarding_funnel.dart';
import '../../services/onboarding_funnel_prefs.dart';
import '../../services/onboarding_funnel_sync.dart';
import '../../state/achievement_provider.dart';
import '../../state/resident_provider.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/identity/allies_preview_row.dart';
import '../../widgets/onboarding/first_steps_card.dart';
import 'identity_screen.dart';

/// You tab: sticky first-steps + profile honour wall.
class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({super.key});

  @override
  ConsumerState<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends ConsumerState<YouScreen> {
  bool _funnelDismissed = true;
  bool _funnelOpenedWorld = false;
  bool _funnelOpenedNexus = false;
  bool _funnelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFunnelPrefs();
  }

  Future<void> _loadFunnelPrefs() async {
    final dismissed = await OnboardingFunnelPrefs.isDismissed();
    final openedWorld = await OnboardingFunnelPrefs.hasOpenedWorld();
    final openedNexus = await OnboardingFunnelPrefs.hasOpenedNexus();
    if (!mounted) return;
    setState(() {
      _funnelDismissed = dismissed;
      _funnelOpenedWorld = openedWorld;
      _funnelOpenedNexus = openedNexus;
      _funnelLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final achievements = ref.watch(achievementProvider).userAchievements;

    final showFirstSteps = _funnelLoaded &&
        resident != null &&
        !_funnelDismissed &&
        !OnboardingFunnel.isComplete(
          resident: resident,
          achievements: achievements,
          openedWorld: _funnelOpenedWorld,
          openedNexus: _funnelOpenedNexus,
        );

    return VTabPage(
      title: 'You',
      headerActions: [
        VAccessibleHeaderAction(
          label: 'Achievements',
          icon: const Icon(VIcons.trophy),
          onPress: () => context.push('/achievements'),
        ),
        VAccessibleHeaderAction(
          label: 'Settings',
          icon: const Icon(VIcons.settings),
          onPress: () => context.push('/settings'),
        ),
      ],
      body: Column(
        children: [
          if (showFirstSteps)
            FirstStepsCard(
              resident: resident,
              userAchievements: achievements,
              openedWorld: _funnelOpenedWorld,
              openedNexus: _funnelOpenedNexus,
              sticky: true,
              onDismiss: () async {
                final uid = resident.id;
                await OnboardingFunnelSync.setDismissed(uid, true);
                if (mounted) setState(() => _funnelDismissed = true);
              },
            ),
          const AlliesPreviewRow(),
          const Expanded(child: IdentityScreen(embedded: true)),
        ],
      ),
    );
  }
}
