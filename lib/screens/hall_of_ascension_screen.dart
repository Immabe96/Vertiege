import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/achievement.dart';
import '../state/resident_provider.dart';
import '../state/achievement_provider.dart';
import '../state/world_provider.dart';
import '../theme/v_colors.dart';
import '../forui/v_hub_page.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/core/prestige_up_dialog.dart';
import '../widgets/profile/luminary_nameplate.dart';
import '../widgets/profile/cosmetic_avatar.dart';

class HallOfAscensionScreen extends ConsumerStatefulWidget {
  const HallOfAscensionScreen({super.key});

  @override
  ConsumerState<HallOfAscensionScreen> createState() =>
      _HallOfAscensionScreenState();
}

class _HallOfAscensionScreenState extends ConsumerState<HallOfAscensionScreen> {


  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final canAscend = ref.watch(residentProvider.select((s) {
      final r = s.resident;
      return r != null && r.tier.value >= 5 && r.totalXp >= 50000;
    }));

    return VHubPage(
      title: 'Hall of Ascension',
      showBack: true,
      headerActions: [
        FButton(
          onPress: () => context.push('/ascension-path'),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map, size: VIconSize.sm),
              SizedBox(width: VSpacing.xs),
              Text('Journey'),
            ],
          ),
        ),
      ],
      body: Column(
        children: [
          if (resident != null) ...[
            _PrestigeHeader(
              resident: resident,
              canAscend: canAscend,
            ),
          ],
          Expanded(
            child: FTabs(
              expands: true,
              scrollable: true,
              control: const FTabControl.managed(),
              children: [
                FTabEntry(label: const Text('TOTAL XP'), child: _XpLeaderboard()),
                FTabEntry(label: const Text('WORLD PRESTIGE'), child: _PrestigeLeaderboard()),
                FTabEntry(label: const Text('ACHIEVEMENTS'), child: _AchievementLeaderboard()),
                FTabEntry(label: const Text('REFERRALS'), child: _ReferralLeaderboard()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Prestige Header ──────────────────────────────────────

class _PrestigeHeader extends ConsumerWidget {
  final dynamic resident;
  final bool canAscend;

  const _PrestigeHeader({required this.resident, required this.canAscend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prestigeStars = resident.prestigeStars as int;
    final prestigeTitle = prestigeStars == 0
        ? 'Apex'
        : (prestigeStars == 1 ? 'Apex I' : 'Apex $prestigeStars');

    return Padding(
      padding: const EdgeInsets.all(VSpacing.md),
      child: _Card(
        padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              ...List.generate(
                prestigeStars,
                (i) => Padding(
                  padding: EdgeInsets.only(right: i < prestigeStars - 1 ? 4 : 0),
                  child: const Icon(Icons.star, color: VColors.tertiary, size: 24),
                ),
              ),
              if (prestigeStars == 0)
                const Icon(
                  Icons.star_border,
                  color: VColors.tertiary,
                  size: 24,
                ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prestigeTitle,
                      style: TextStyle(
                        fontSize: VFontSize.headlineLg,
                        fontWeight: VFontWeight.bold,
                        color: VColors.tertiary,
                      ),
                    ),
                    Text(
                      prestigeStars == 0
                          ? 'Reach 50,000 XP to ascend'
                          : 'Prestige Level $prestigeStars',
                      style: TextStyle(
                        fontSize: VFontSize.bodySm,
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canAscend) ...[
            const SizedBox(height: VSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final success = await ref
                      .read(residentProvider.notifier)
                      .ascendToPrestige();
                  if (success && context.mounted) {
                    PrestigeUpDialog.show(
                      context,
                      prestigeLevel: 1,
                      newPrestigeStars: prestigeStars + 1,
                    );
                  }
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('ASCEND TO PRESTIGE'),
                style: FilledButton.styleFrom(
                  backgroundColor: VColors.tertiary,
                  foregroundColor: VColors.onTertiary,
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
                ),
              ),
            ),
          ],
        ],
      ),
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

Color _rankColor(int rank, {required bool isDark}) {
  switch (rank) {
    case 1:
      return VColors.tertiary;
    case 2:
      return VColors.primary;
    case 3:
      return VColors.secondary;
    default:
      return isDark ? VColors.glassBorderDark : VColors.glassBorder;
  }
}

Color _rankGlowColor(int rank) {
  switch (rank) {
    case 1:
      return VColors.tertiary;
    case 2:
      return VColors.primary;
    case 3:
      return VColors.secondary;
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
      return const ScreenLoading.list();
    }

    final entries = <_LeaderEntry>[
      _LeaderEntry(
        id: resident.id,
        name: resident.name,
        tier: resident.tier.value,
        avatarUrl: resident.avatarUrl,
        score: achievementState.totalXp,
        title: resident.title,
      ),
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

    final entries = worlds
        .take(20)
        .map(
          (w) => _LeaderEntry(
            id: w.id,
            name: w.name,
            tier: w.prestige >= 600 ? 5 : (w.prestige >= 300 ? 3 : 1),
            avatarUrl: '',
            score: w.prestige,
          ),
        )
        .toList();

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
        _LeaderEntry(
          id: resident.id,
          name: resident.name,
          tier: resident.tier.value,
          avatarUrl: resident.avatarUrl,
          score: verifiedCount,
          title: resident.title,
        ),
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
        _LeaderEntry(
          id: resident.id,
          name: resident.name,
          tier: resident.tier.value,
          avatarUrl: resident.avatarUrl,
          score: resident.referredBy != null ? 1 : 0,
          title: resident.title,
        ),
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (entries.isEmpty) {
    return const AppEmptyState(
      title: 'No rankings yet',
      description: 'Rankings will appear once residents start earning here.',
      icon: Icons.leaderboard_outlined,
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(VSpacing.md),
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      final rank = index + 1;
      final isTop3 = rank <= 3;
      final glowColor = _rankGlowColor(rank);

      return FadeIn(
        delayMs: index * 50,
        child: Padding(
          padding: const EdgeInsets.only(bottom: VSpacing.sm),
          child: _Card(
            padding: const EdgeInsets.all(VSpacing.md),
            border: isTop3
                ? Border.all(
                    color: glowColor.withValues(alpha: 0.4),
                  )
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
                      color: _rankColor(rank, isDark: isDark)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(VRadius.sm),
                      border: isTop3
                          ? Border.all(
                              color: _rankColor(rank, isDark: isDark),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: VFontSize.headlineMd,
                          fontWeight: VFontWeight.bold,
                          color: _rankColor(rank, isDark: isDark),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: VSpacing.md),
                  // Avatar
                  CosmeticAvatar(imageUrl: entry.avatarUrl, size: 40),
                  const SizedBox(width: VSpacing.md),
                  // Name + Title
                  Expanded(
                    child: LuminaryNameplate(
                      name: entry.name,
                      tier: entry.tier,
                      fontSize: VFontSize.bodyMd,
                      title: entry.title,
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  // Score
                  Text(
                    '${entry.score}',
                    style: TextStyle(
                      fontSize: VFontSize.headlineMd,
                      fontWeight: VFontWeight.bold,
                      color: VColors.tertiary,
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

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Border? border;

  const _Card({required this.child, this.padding, this.border});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: border ?? Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}
