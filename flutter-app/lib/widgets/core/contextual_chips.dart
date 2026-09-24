import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/progression_access.dart';
import '../../router/progress_navigation.dart';
import '../../state/resident_provider.dart';
import '../../state/quest_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Dynamically renders contextual chips based on the resident's current state.
class ContextualChips extends ConsumerWidget {
  const ContextualChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final questState = ref.watch(questProvider);
    final worldState = ref.watch(worldProvider);

    final chips = <Widget>[];

    if (resident != null) {
      if (resident.tier.value == 1 &&
          resident.joinedWorldIds.isEmpty &&
          resident.streakCount == 0) {
        chips.add(
          _ContextChip(
            icon: Icons.auto_awesome,
            label: 'Getting Started',
            color: VColors.success,
            onTap: () => context.go('/identity'),
          ),
        );
      }

      if (ProgressionAccess.canAccessAscension(resident.tier.value)) {
        chips.add(
          _ContextChip(
            icon: Icons.shield,
            label: 'Ascension',
            color: Theme.of(context).colorScheme.primary,
            onTap: () => context.push('/hall-of-ascension'),
          ),
        );
      }

      final invitesCount = worldState.worlds.values
          .where((w) => !resident.joinedWorldIds.contains(w.id))
          .length;
      if (invitesCount > 0) {
        chips.add(
          _ContextChip(
            icon: Icons.mail,
            label: 'Invites ($invitesCount)',
            color: VColors.warning,
            onTap: () => context.go('/worlds'),
          ),
        );
      }
    }

    final activeQuests = questState.quests
        .where((q) => !q.claimed && !q.isComplete)
        .toList();
    if (activeQuests.isNotEmpty) {
      chips.add(
        _ContextChip(
          icon: Icons.bolt,
          label: 'Daily Quest',
          color: VColors.tertiary,
          onTap: () => context.push(progressPath(tab: ProgressTab.quests)),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .expand((chip) => [chip, const SizedBox(width: VSpacing.sm)])
              .toList(),
        ),
      ),
    );
  }
}

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
        duration: VAnimation.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(VRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: VIconSize.sm, color: color),
            const SizedBox(width: VSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: VFontSize.bodyMd,
                fontWeight: VFontWeight.semiBold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
