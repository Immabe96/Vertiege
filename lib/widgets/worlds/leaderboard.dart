import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/world_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/fade_in.dart';
import '../core/loading_state.dart';
import '../profile/cosmetic_avatar.dart';

class WorldLeaderboard extends ConsumerStatefulWidget {
  final String worldId;
  final int maxItems;

  const WorldLeaderboard({
    super.key,
    required this.worldId,
    this.maxItems = 10,
  });

  @override
  ConsumerState<WorldLeaderboard> createState() => _WorldLeaderboardState();
}

class _WorldLeaderboardState extends ConsumerState<WorldLeaderboard> {
  List<_RankedResident> _residents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void didUpdateWidget(WorldLeaderboard old) {
    super.didUpdateWidget(old);
    if (old.worldId != widget.worldId) _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    try {
      final members = await WorldService.getMembers(widget.worldId);
      final all =
          members
              .where((m) => (m['rep'] as int? ?? 0) > 0)
              .map(
                (m) => _RankedResident(
                  id:
                      m['resident_id'] as String? ??
                      m['resident_name'] as String? ??
                      'member',
                  name: m['resident_name'] as String? ?? 'Member',
                  avatarUrl: m['avatar_url'] as String?,
                  rep: m['rep'] as int? ?? 0,
                ),
              )
              .toList()
            ..sort((a, b) => b.rep.compareTo(a.rep));

      if (mounted) {
        setState(() {
          _residents = all.take(widget.maxItems).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: VLoadingCard(),
      );
    }

    if (_residents.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: VColors.glassBackground,
          borderRadius: BorderRadius.circular(VRadius.md),
          border: Border.all(color: VColors.glassBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.leaderboard_outlined,
                size: VIconSize.xl,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: VSpacing.sm),
              Text(
                'Leaderboard',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                'Be the first to earn reputation in this world',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: VColors.glassBackground,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: VColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.leaderboard,
                  size: VIconSize.md,
                  color: VColors.achievementFinance,
                ),
                const SizedBox(width: VSpacing.sm),
                Text(
                  'Leaderboard',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            ..._residents.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final resident = entry.value;
              return FadeIn(
                delayMs: rank * 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.xs),
                  child: Row(
                    children: [
                      _RankBadge(rank: rank),
                      const SizedBox(width: VSpacing.sm),
                      CosmeticAvatar(
                        imageUrl: resident.avatarUrl,
                        seed: resident.id,
                        size: 36,
                      ),
                      const SizedBox(width: VSpacing.sm),
                      Expanded(
                        child: Text(
                          resident.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: VFontWeight.regular,
                          ),
                        ),
                      ),
                      Text(
                        '${resident.rep} rep',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RankedResident {
  final String id;
  final String name;
  final String? avatarUrl;
  final int rep;
  const _RankedResident({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.rep,
  });
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final IconData icon;
    switch (rank) {
      case 1:
        bg = VColors.tertiary;
        icon = Icons.emoji_events;
      case 2:
        bg = VColors.outline;
        icon = Icons.military_tech;
      case 3:
        bg = VColors.outlineVariant;
        icon = Icons.workspace_premium;
      default:
        return Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: VFontSize.labelMd,
              fontWeight: VFontWeight.bold,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg.withValues(alpha: 0.15),
        border: Border.all(color: bg, width: 1.5),
      ),
      child: Icon(icon, size: VIconSize.sm, color: bg),
    );
  }
}
