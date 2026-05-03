import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../state/resident_provider.dart';
import '../../services/access_control.dart';
import '../../theme/design_system.dart';
import '../../theme/colors.dart';
import '../core/fade_in.dart';
import 'world_icon.dart';
import 'world_banner.dart';

class WorldCard extends ConsumerWidget {
  final World world;
  final int index;

  const WorldCard({super.key, required this.world, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final isLocked = resident != null && !canAccessWorld(resident, world);
    final theme = Theme.of(context);

    // Simulated online count (in a real app this would come from presence data)
    final onlineCount = (world.memberCount * 0.35).round().clamp(1, 99);

    return FadeIn(
      delayMs: index * 60,
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
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
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/explore/${world.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Banner Thumbnail ─────────────────
              _BannerThumbnail(world: world, onlineCount: onlineCount),

              // ── Card Body ─────────────────
              Padding(
                padding: const EdgeInsets.all(Spacing.sm + 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // World name
                    Text(
                      world.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Online indicator
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.online,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$onlineCount online',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.online,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        // Member count
                        Icon(Icons.people, size: 10, color: theme.colorScheme.outline),
                        const SizedBox(width: 2),
                        Text(
                          '${world.memberCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      world.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacing.sm),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerThumbnail extends StatelessWidget {
  final World world;
  final int onlineCount;

  const _BannerThumbnail({required this.world, required this.onlineCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Banner SVG background
          Hero(
            tag: 'world-icon-${world.id}',
            child: WorldBanner(
              worldId: world.id,
              width: double.infinity,
              height: 80,
            ),
          ),

          // Subtle gradient overlay at bottom for icon readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 40,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      theme.colorScheme.surface.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // World icon overlaid at bottom-center of thumbnail
          Positioned(
            bottom: -6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: WorldIcon(worldId: world.id, size: IconSizes.md + 4),
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSizes.xs, color: color),
          const SizedBox(width: 3),
          Text(label,
            style: TextStyle(
              color: color,
              fontSize: FontSizes.caption - 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
