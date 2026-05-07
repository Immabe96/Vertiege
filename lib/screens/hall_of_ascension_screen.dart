import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/achievement.dart';
import '../state/resident_provider.dart';
import '../state/achievement_provider.dart';
import '../state/world_provider.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/profile/luminary_nameplate.dart';
import '../widgets/profile/cosmetic_avatar.dart';

class HallOfAscensionScreen extends ConsumerStatefulWidget {
  const HallOfAscensionScreen({super.key});

  @override
  ConsumerState<HallOfAscensionScreen> createState() =>
      _HallOfAscensionScreenState();
}

class _HallOfAscensionScreenState extends ConsumerState<HallOfAscensionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hall of Ascension'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/ascension-path'),
            icon: const Icon(Icons.map, size: IconSizes.sm),
            label: const Text(
              'View Your Journey',
              style: TextStyle(fontSize: FontSizes.labelSm),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.tertiary,
            unselectedLabelColor: AppColors.inkMuted,
            labelStyle: const TextStyle(
              fontSize: FontSizes.labelSm,
              fontWeight: FontWeights.semiBold,
              letterSpacing: LetterSpacing.label,
            ),
            isScrollable: true,
            tabs: const [
              Tab(text: 'TOTAL XP'),
              Tab(text: 'WORLD PRESTIGE'),
              Tab(text: 'ACHIEVEMENTS'),
              Tab(text: 'REFERRALS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _XpLeaderboard(),
                _PrestigeLeaderboard(),
                _AchievementLeaderboard(),
                _ReferralLeaderboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard Entry ────────────────────────────────────

class _LeaderEntry {
  final String id;
  final String name;
  final int tier;
  final String avatarUrl;
  final int score;
  final String? title;

  const _LeaderEntry({
    required this.id,
    required this.name,
    required this.tier,
    required this.avatarUrl,
    required this.score,
    this.title,
  });
}

Color _rankColor(int rank) {
  switch (rank) {
    case 1:
      return AppColors.tertiary;
    case 2:
      return AppColors.silver;
    case 3:
      return AppColors.bronze;
    default:
      return AppColors.glassBorder;
  }
}

Color _rankGlowColor(int rank) {
  switch (rank) {
    case 1:
      return AppColors.tertiary;
    case 2:
      return AppColors.primary;
    case 3:
      return AppColors.hustler;
    default:
      return Colors.transparent;
  }
}

// ── XP Leaderboard ──────────────────────────────────────

class _XpLeaderboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementState = ref.watch(achievementProvider);
    final resident = ref.watch(residentProvider).resident;

    if (resident == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Build entries from current resident data + sample entries (debug only)
    final entries = <_LeaderEntry>[
      _LeaderEntry(
        id: resident.id,
        name: resident.name,
        tier: resident.tier.value,
        avatarUrl: resident.avatarUrl,
        score: achievementState.totalXp,
        title: resident.title,
      ),
      if (kDebugMode) ...[
        _LeaderEntry(id: 's1', name: 'Aria Voss', tier: 5, avatarUrl: '', score: 52000, title: 'the Relentless'),
        _LeaderEntry(id: 's2', name: 'Kai Zenith', tier: 5, avatarUrl: '', score: 48700),
        _LeaderEntry(id: 's3', name: 'Luna Frost', tier: 4, avatarUrl: '', score: 43100, title: 'the Storyteller'),
        _LeaderEntry(id: 's4', name: 'Marcus Cole', tier: 4, avatarUrl: '', score: 37500),
        _LeaderEntry(id: 's5', name: 'Nova Hart', tier: 4, avatarUrl: '', score: 29100, title: 'the Wayfarer'),
        _LeaderEntry(id: 's6', name: 'Orion Shade', tier: 3, avatarUrl: '', score: 18500),
        _LeaderEntry(id: 's7', name: 'Sage River', tier: 3, avatarUrl: '', score: 15200),
        _LeaderEntry(id: 's8', name: 'Vex Crow', tier: 3, avatarUrl: '', score: 12100),
        _LeaderEntry(id: 's9', name: 'Zara Nyx', tier: 2, avatarUrl: '', score: 9800),
        _LeaderEntry(id: 's10', name: 'Ash Dune', tier: 2, avatarUrl: '', score: 7200),
      ],
    ]..sort((a, b) => b.score.compareTo(a.score));

    return _buildLeaderboardList(context, ref, entries.take(20).toList());
  }
}

// ── Prestige Leaderboard ────────────────────────────────

class _PrestigeLeaderboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldState = ref.watch(worldProvider);
    final worlds = worldState.worlds.values.toList()
      ..sort((a, b) => b.prestige.compareTo(a.prestige));

    final entries = worlds.take(20).map((w) => _LeaderEntry(
          id: w.id,
          name: w.name,
          tier: w.prestige >= 600 ? 5 : (w.prestige >= 300 ? 3 : 1),
          avatarUrl: '',
          score: w.prestige,
        )).toList();

    return _buildLeaderboardList(context, ref, entries);
  }
}

// ── Achievement Leaderboard ─────────────────────────────

class _AchievementLeaderboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementState = ref.watch(achievementProvider);
    final resident = ref.watch(residentProvider).resident;
    final verifiedCount = achievementState.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .length;

    final entries = <_LeaderEntry>[
      if (resident != null)
        _LeaderEntry(id: resident.id, name: resident.name, tier: resident.tier.value, avatarUrl: resident.avatarUrl, score: verifiedCount, title: resident.title),
      _LeaderEntry(id: 's1', name: 'Aria Voss', tier: 5, avatarUrl: '', score: 47, title: 'the Ancient'),
      _LeaderEntry(id: 's2', name: 'Kai Zenith', tier: 5, avatarUrl: '', score: 42),
      _LeaderEntry(id: 's3', name: 'Luna Frost', tier: 4, avatarUrl: '', score: 38, title: 'the Seasoned'),
      _LeaderEntry(id: 's4', name: 'Marcus Cole', tier: 4, avatarUrl: '', score: 35),
      _LeaderEntry(id: 's5', name: 'Nova Hart', tier: 4, avatarUrl: '', score: 31),
      _LeaderEntry(id: 's6', name: 'Orion Shade', tier: 3, avatarUrl: '', score: 28),
      _LeaderEntry(id: 's7', name: 'Sage River', tier: 3, avatarUrl: '', score: 25, title: 'the Pathfinder'),
      _LeaderEntry(id: 's8', name: 'Vex Crow', tier: 3, avatarUrl: '', score: 22),
      _LeaderEntry(id: 's9', name: 'Zara Nyx', tier: 2, avatarUrl: '', score: 18),
      _LeaderEntry(id: 's10', name: 'Ash Dune', tier: 2, avatarUrl: '', score: 15),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return _buildLeaderboardList(context, ref, entries.take(20).toList());
  }
}

// ── Referral Leaderboard ────────────────────────────────

class _ReferralLeaderboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;

    final entries = <_LeaderEntry>[
      if (resident != null)
        _LeaderEntry(id: resident.id, name: resident.name, tier: resident.tier.value, avatarUrl: resident.avatarUrl, score: resident.referredBy != null ? 1 : 0, title: resident.title),
      _LeaderEntry(id: 's1', name: 'Aria Voss', tier: 5, avatarUrl: '', score: 24, title: 'the Voice'),
      _LeaderEntry(id: 's2', name: 'Kai Zenith', tier: 5, avatarUrl: '', score: 19),
      _LeaderEntry(id: 's3', name: 'Luna Frost', tier: 4, avatarUrl: '', score: 15),
      _LeaderEntry(id: 's4', name: 'Marcus Cole', tier: 4, avatarUrl: '', score: 12),
      _LeaderEntry(id: 's5', name: 'Nova Hart', tier: 4, avatarUrl: '', score: 9),
      _LeaderEntry(id: 's6', name: 'Orion Shade', tier: 3, avatarUrl: '', score: 7),
      _LeaderEntry(id: 's7', name: 'Sage River', tier: 3, avatarUrl: '', score: 5),
      _LeaderEntry(id: 's8', name: 'Vex Crow', tier: 3, avatarUrl: '', score: 4),
      _LeaderEntry(id: 's9', name: 'Zara Nyx', tier: 2, avatarUrl: '', score: 3),
      _LeaderEntry(id: 's10', name: 'Ash Dune', tier: 2, avatarUrl: '', score: 2),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return _buildLeaderboardList(context, ref, entries.take(20).toList());
  }
}

// ── Shared Leaderboard List Builder ─────────────────────

Widget _buildLeaderboardList(
  BuildContext context,
  WidgetRef ref,
  List<_LeaderEntry> entries,
) {
  if (entries.isEmpty) {
    return const Center(
      child: Text(
        'No data available yet',
        style: TextStyle(color: AppColors.inkMuted),
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(Spacing.md),
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      final rank = index + 1;
      final isTop3 = rank <= 3;
      final glowColor = _rankGlowColor(rank);

      return FadeIn(
        delayMs: index * 50,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: GlassPanel(
            padding: const EdgeInsets.all(Spacing.md),
            border: isTop3
                ? Border.all(color: glowColor.withValues(alpha: 0.4))
                : null,
            child: Container(
              decoration: isTop3
                  ? BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.08),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _rankColor(rank).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      border: isTop3
                          ? Border.all(color: _rankColor(rank), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: FontSizes.headlineMd,
                          fontWeight: FontWeights.bold,
                          color: _rankColor(rank),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  // Avatar
                  CosmeticAvatar(
                    imageUrl: entry.avatarUrl,
                    size: 40,
                  ),
                  const SizedBox(width: Spacing.md),
                  // Name + Title
                  Expanded(
                    child: LuminaryNameplate(
                      name: entry.name,
                      tier: entry.tier,
                      fontSize: FontSizes.bodyMd,
                      title: entry.title,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  // Score
                  Text(
                    '${entry.score}',
                    style: const TextStyle(
                      fontSize: FontSizes.headlineMd,
                      fontWeight: FontWeights.bold,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
