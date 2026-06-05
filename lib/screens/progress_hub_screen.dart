import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vertiege/ui/ui.dart';
import '../router/progress_navigation.dart';
import '../state/league_provider.dart';
import '../state/quest_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return VHubPage(
      title: 'Progress',
      showBack: true,
      headerActions: [
        if (_tabs.index == 0)
          FHeaderAction(
            icon: const Icon(FIcons.rotateCw),
            onPress: () => ref.read(questProvider.notifier).loadQuests(),
          ),
        if (_tabs.index == 3)
          FHeaderAction(
            icon: const Icon(FIcons.rotateCw),
            onPress: () => ref.read(leagueProvider.notifier).loadLeague(),
          ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Quests'),
              Tab(text: 'World'),
              Tab(text: 'Season'),
              Tab(text: 'League'),
            ],
          ),
          const Divider(height: 1),
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
