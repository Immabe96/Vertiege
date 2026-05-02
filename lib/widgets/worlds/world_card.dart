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
      child: Card(
        elevation: isLocked ? 0 : 1,
        color: isLocked ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/explore/${world.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'world-icon-${world.id}',
                      child: WorldIcon(worldId: world.id, size: 40),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(world.name, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(world.description,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    _Chip(label: world.type.name, color: theme.colorScheme.secondary),
                    _Chip(label: 'Prestige ${world.prestige}', color: theme.colorScheme.primary),
                    if (isLocked) _Chip(label: 'Locked', color: theme.colorScheme.error),
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
