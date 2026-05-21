import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import '../../theme/v_colors.dart';
import '../../models/world.dart';
import '../../ui/icons/v_icons.dart';

class WorldInfoSheet extends StatefulWidget {
  final WorldBase world;
  final int members;
  final int posts;
  final int events;
  final VoidCallback onVisible;
  final VoidCallback onMembersTap;

  const WorldInfoSheet({
    super.key,
    required this.world,
    required this.members,
    required this.posts,
    required this.events,
    required this.onVisible,
    required this.onMembersTap,
  });

  @override
  State<WorldInfoSheet> createState() => _WorldInfoSheetState();
}

class _WorldInfoSheetState extends State<WorldInfoSheet> {
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_triggered && mounted) {
        _triggered = true;
        widget.onVisible();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final world = widget.world;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: VColors.glassBackground,
        borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
        border: Border.all(color: VColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.md,
              Spacing.sm,
            ),
            child: Text(
              world.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: LineHeight.body,
                color: cs.onSurface,
              ),
            ),
          ),

          // Sovereign + Prestige row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              children: [
                Icon(VIcons.sparkles, size: IconSizes.sm, color: cs.primary),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    'Sovereign: ${world.sovereignName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(VIcons.sparkles, size: IconSizes.sm, color: VColors.tertiary),
                const SizedBox(width: Spacing.xs),
                Text(
                  'Prestige ${world.prestige}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeights.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Divider
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm + 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatItem(
                  icon: Icons.people,
                  label: 'Members',
                  value: widget.members,
                  color: cs.primary,
                ),
                StatItem(
                  icon: Icons.forum,
                  label: 'Posts',
                  value: widget.posts,
                  color: VColors.primary,
                ),
                StatItem(
                  icon: Icons.event,
                  label: 'Events',
                  value: widget.events,
                  color: VColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const StatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(RadiusTokens.card),
          ),
          child: Icon(icon, size: IconSizes.md, color: color),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeights.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
