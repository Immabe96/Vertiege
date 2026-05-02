import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../state/resident_provider.dart';
import '../../services/access_control.dart';
import '../core/fade_in.dart';
import 'world_icon.dart';

class WorldCard extends ConsumerWidget {
  final World world;
  final int index;

  const WorldCard({super.key, required this.world, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final isLocked = resident != null && !canAccessWorld(resident, world);
    final theme = Theme.of(context);

    return FadeIn(
      delayMs: index * 60,
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.1)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/explore/${world.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'world-icon-${world.id}',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: WorldIcon(worldId: world.id, size: 28),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(world.name,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            '${world.memberCount} members',
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(world.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Badge(
                      label: world.type.name,
                      icon: Icons.public,
                      color: theme.colorScheme.secondary,
                    ),
                    _Badge(
                      label: 'P ${world.prestige}',
                      icon: Icons.star,
                      color: theme.colorScheme.primary,
                    ),
                    if (isLocked)
                      _Badge(label: 'Locked', icon: Icons.lock, color: theme.colorScheme.error),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
