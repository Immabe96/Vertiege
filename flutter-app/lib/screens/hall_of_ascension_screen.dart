import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/resident_provider.dart';
import '../state/world_provider.dart';
import '../state/leaderboard_provider.dart';
import '../theme/v_colors.dart';
import 'package:vertiege/ui/ui.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardProvider.notifier).loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final canAscend = ref.watch(
      residentProvider.select((s) {
        final r = s.resident;
        return r != null && r.tier.value >= 5 && r.totalXp >= 50000;
      }),
    );

    return VHubPage(
      title: 'Hall of Ascension',
      showBack: true,
      headerActions: [
        VButton(
          label: 'Journey',
          icon: const Icon(Icons.map, size: VIconSize.sm),
          onPressed: () => context.push('/ascension-path'),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.md,
              VSpacing.sm,
              VSpacing.md,
              0,
            ),
            child: _SeasonNarrativeBanner(
              onOpenSeason: () => context.push('/season'),
            ),
          ),
          if (resident != null) ...[
            _PrestigeHeader(resident: resident, canAscend: canAscend),
          ],
          Expanded(
            child: VTabs(
              scrollable: true,
              tabs: [
                VTabEntry(
                  label: const Text('TOTAL XP'),
                  child: _XpLeaderboard(),
                ),
                VTabEntry(
                  label: const Text('WORLD PRESTIGE'),
                  child: _PrestigeLeaderboard(),
                ),
                VTabEntry(
                  label: const Text('ACHIEVEMENTS'),
                  child: _AchievementLeaderboard(),
                ),
                VTabEntry(
                  label: const Text('REFERRALS'),
                  child: _ReferralLeaderboard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonNarrativeBanner extends StatelessWidget {
  final VoidCallback onOpenSeason;

  const _SeasonNarrativeBanner({required this.onOpenSeason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: VColors.glassBackgroundDark,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(color: VColors.glassBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Season 1 is live',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: VFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'Ascension Leagues track your weekly XP against peers. Season cohorts track your world\'s growth together — different ladders, same journey.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
          const SizedBox(height: VSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: VButton(
              label: 'View season standings',
              variant: ButtonVariant.text,
              size: ButtonSize.small,
              onPressed: onOpenSeason,
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
                    padding: EdgeInsets.only(
                      right: i < prestigeStars - 1 ? 4 : 0,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: VColors.tertiary,
                      size: 24,
                    ),
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
                        style: const TextStyle(
                          fontSize: VFontSize.headlineLg,
                          fontWeight: VFontWeight.bold,
                          color: VColors.tertiary,
                        ),
                      ),
                      Text(
                        prestigeStars == 0
                            ? 'Reach 50,000 XP to ascend'
                            : 'Prestige Level $prestigeStars',
                        style: const TextStyle(
                          fontSize: VFontSize.bodySm,
                          color: VColors.onSurfaceVariantDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canAscend) ...[
              const SizedBox(height: VSpacing.md),
              VButton(
                label: 'ASCEND TO PRESTIGE',
                isFullWidth: true,
                icon: const Icon(Icons.auto_awesome),
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

Color _rankColor(int rank) {
  switch (rank) {
    case 1:
      return VColors.tertiary;
    case 2:
      return VColors.primary;
    case 3:
      return VColors.secondary;
    default:
      return VColors.glassBorderDark;
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
    final leaderboardState = ref.watch(leaderboardProvider);

    if (leaderboardState.isLoading) {
      return const ScreenLoading.list();
    }

    if (leaderboardState.error != null) {
      return AppErrorState(
        message: leaderboardState.error!,
        onRetry: () => ref.read(leaderboardProvider.notifier).loadLeaderboard(),
      );
    }

    final entries = leaderboardState.xpEntries
        .map(
          (e) => _LeaderEntry(
            id: e.userId,
            name: e.name,
            tier: e.tier,
            avatarUrl: e.avatarUrl,
            score: e.totalXp,
            title: e.title,
          ),
        )
        .toList();

    return _buildLeaderboardList(context, ref, entries);
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
    final leaderboardState = ref.watch(leaderboardProvider);

    if (leaderboardState.isLoading) {
      return const ScreenLoading.list();
    }

    if (leaderboardState.error != null) {
      return AppErrorState(
        message: leaderboardState.error!,
        onRetry: () => ref.read(leaderboardProvider.notifier).loadLeaderboard(),
      );
    }

    final entries = leaderboardState.achievementEntries
        .map(
          (e) => _LeaderEntry(
            id: e.userId,
            name: e.name,
            tier: e.tier,
            avatarUrl: e.avatarUrl,
            score: e.totalXp,
            title: e.title,
          ),
        )
        .toList();

    return _buildLeaderboardList(context, ref, entries);
  }
}

// ── Referral Leaderboard ────────────────────────────────

class _ReferralLeaderboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardState = ref.watch(leaderboardProvider);

    if (leaderboardState.isLoading) {
      return const ScreenLoading.list();
    }

    if (leaderboardState.error != null) {
      return AppErrorState(
        message: leaderboardState.error!,
        onRetry: () => ref.read(leaderboardProvider.notifier).loadLeaderboard(),
      );
    }

    final entries = leaderboardState.referralEntries
        .map(
          (e) => _LeaderEntry(
            id: e.userId,
            name: e.name,
            tier: e.tier,
            avatarUrl: e.avatarUrl,
            score: e.totalXp,
            title: e.title,
          ),
        )
        .toList();

    return _buildLeaderboardList(context, ref, entries);
  }
}

// ── Shared Leaderboard List Builder ─────────────────────

Widget _buildLeaderboardList(
  BuildContext context,
  WidgetRef ref,
  List<_LeaderEntry> entries,
) {
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
                      borderRadius: BorderRadius.circular(VRadius.sm),
                      border: isTop3
                          ? Border.all(color: _rankColor(rank), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: VFontSize.headlineMd,
                          fontWeight: VFontWeight.bold,
                          color: _rankColor(rank),
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
                    style: const TextStyle(
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
    return Container(
      padding: padding ?? const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerDark,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: border ?? Border.all(color: VColors.outlineVariantDark),
      ),
      child: child,
    );
  }
}
