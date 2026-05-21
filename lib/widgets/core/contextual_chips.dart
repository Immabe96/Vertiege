import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/resident_provider.dart';
import '../../state/quest_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

/// Dynamically renders contextual chips based on the resident's current state:
/// - New resident (tier 1, no worlds joined, no streak)
/// - Active daily quests available
/// - Council membership (tier >= oldMoney)
/// - Pending world invites
class ContextualChips extends ConsumerWidget {
  const ContextualChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final questState = ref.watch(questProvider);
    final worldState = ref.watch(worldProvider);

    final chips = <Widget>[];
    int invitesCount = 0;

    if (resident != null) {
      // ── New resident (< 7 days proxy) ──
      if (resident.tier.value == 1 &&
          resident.joinedWorldIds.isEmpty &&
          resident.streakCount == 0) {
        chips.add(
          _ContextChip(
            icon: Icons.auto_awesome,
            label: 'Getting Started',
            color: VColors.success,
            onTap: () => context.push('/onboarding'),
          ),
        );
      }

      // ── Council member ──
      if (resident.tier.value >= 4 || resident.verifiedRoles.isNotEmpty) {
        chips.add(
          _ContextChip(
            icon: Icons.shield,
            label: 'Governance',
            color: VColors.primary,
            onTap: () => context.push('/hall-of-ascension'),
          ),
        );
      }

      // ── Pending world invites ──
      final allWorlds = worldState.worlds.values.toList();
      invitesCount = allWorlds
          .where((w) => !resident.joinedWorldIds.contains(w.id))
          .length;
      if (invitesCount > 0) {
        chips.add(
          _ContextChip(
            icon: Icons.mail,
            label: 'Invites ($invitesCount)',
            color: VColors.warning,
            onTap: () => context.go('/explore'),
          ),
        );
      }
    }

    // ── Active quest ──
    final activeQuests = questState.quests
        .where((q) => !q.claimed && !q.isComplete)
        .toList();
    if (activeQuests.isNotEmpty) {
      chips.add(
        _ContextChip(
          icon: Icons.bolt,
          label: 'Daily Quest',
          color: VColors.tertiary,
          onTap: () => context.push('/ascension-path'),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .expand((chip) => [chip, const SizedBox(width: Spacing.sm)])
              .toList(),
        ),
      ),
    );
  }
}

/// A single contextual chip styled similarly to FilterPill but with
/// category-specific coloring.
class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ContextChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: IconSizes.sm, color: color),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: FontSizes.body,
                fontWeight: FontWeights.semiBold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
