import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vertiege/ui/ui.dart';
import '../config/achievements.dart';
import '../config/progression_glossary.dart';
import '../router/progress_navigation.dart';
import '../state/league_provider.dart';
import '../state/quest_provider.dart';
import '../state/resident_provider.dart';
import '../theme/v_tokens.dart';
import '../widgets/progression/prestige_noir_ui.dart';
import 'challenges_screen.dart';
import 'daily_quests_screen.dart';
import 'league_screen.dart';
import 'season_screen.dart';

/// Unified progress surface: quests, world challenges, season, league (Wave 22).
class ProgressHubScreen extends ConsumerStatefulWidget {
  final ProgressTab initialTab;

  const ProgressHubScreen({super.key, this.initialTab = ProgressTab.quests});

  @override
  ConsumerState<ProgressHubScreen> createState() => _ProgressHubScreenState();
}

class _ProgressHubScreenState extends ConsumerState<ProgressHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _tabLabels = ['Quests', 'World', 'Season', 'League'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  double _tierProgress(int totalXp, int tierNum) {
    final currentThreshold = xpThresholds[tierNum] ?? 0;
    final nextThreshold = tierNum < 5
        ? (xpThresholds[tierNum + 1] ?? totalXp + 1)
        : totalXp + 1;
    final tierProgress = totalXp - currentThreshold;
    final tierRequired = nextThreshold - currentThreshold;
    if (tierRequired <= 0) return 1.0;
    return (tierProgress / tierRequired).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final totalXp = resident?.totalXp ?? 0;
    final tierNum = resident?.tier.value ?? 1;

    return VHubPage(
      title: 'Progress',
      showBack: true,
      headerActions: [
        if (_tabs.index == 0)
          VHeaderAction(
            icon: const Icon(VIcons.rotateCw),
            onPress: () => ref.read(questProvider.notifier).loadQuests(),
          ),
        if (_tabs.index == 3)
          VHeaderAction(
            icon: const Icon(VIcons.rotateCw),
            onPress: () => ref.read(leagueProvider.notifier).loadLeague(),
          ),
      ],
      body: Column(
        children: [
          if (resident != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.lg,
                VSpacing.lg,
                VSpacing.lg,
                VSpacing.md,
              ),
              child: PrestigeXpHero(
                totalXp: totalXp,
                tierProgress: _tierProgress(totalXp, tierNum),
                metaLeft: ProgressionGlossary.xpToNextTier(totalXp, tierNum),
                metaRight: (_tabs.index != ProgressTab.quests.index &&
                        resident.streakCount > 0)
                    ? '${resident.streakCount}-day streak'
                    : null,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
            child: PrestigeSegmentTabs(
              labels: _tabLabels,
              selectedIndex: _tabs.index,
              onSelected: (index) => _tabs.animateTo(index),
            ),
          ),
          const SizedBox(height: VSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                DailyQuestsScreen(embedInHub: true),
                ChallengesScreen(embedInHub: true),
                SeasonScreen(embedInHub: true),
                LeagueScreen(embedInHub: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
