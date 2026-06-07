import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_assets.dart';
import 'world_banner.dart';

/// A glassmorphism-styled share card for social media.
///
/// Renders a 9:16 story-format card showing a world's procedural banner,
/// name, stats, tier badge, and a call-to-action tagline — all tinted by
/// the world's prestige tier color.
class WorldShareCard extends StatelessWidget {
  final World world;

  const WorldShareCard({super.key, required this.world});

  Color get _tierColor => WorldAssets.colorForPrestige(world.prestige);

  IconData get _worldTypeIcon {
    switch (world.type) {
      case WorldType.wealth:
        return Icons.diamond;
      case WorldType.profession:
        return Icons.work;
      case WorldType.dominion:
        return Icons.shield;
    }
  }

  String get _tierLabel {
    if (world.requiredProfession != null) {
      return world.requiredProfession!.toUpperCase();
    }
    if (world.requiredTier != null &&
        world.requiredTier! >= 1 &&
        world.requiredTier! <= 5) {
      const names = [
        '',
        'HUSTLER',
        'HIGH ROLLER',
        'ELITE',
        'OLD MONEY',
        'APEX',
      ];
      return 'TIER ${names[world.requiredTier!]}';
    }
    return 'OPEN';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 640,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(VRadius.xxxl),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: _tierColor.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Procedural Banner ──────────────────────────────
          SizedBox(
            width: 360,
            height: 260,
            child: WorldBanner(
              worldId: world.id,
              assetKey: world.assetKey,
              width: 360,
              height: 260,
              worldType: world.type,
              prestige: world.prestige,
            ),
          ),

          // ── Card Body ──────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Theme.of(context).colorScheme.surfaceBright, Theme.of(context).colorScheme.surface],
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.xl,
                vertical: VSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Tier badge with glow
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.lg,
                      vertical: VSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: _tierColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(VRadius.pill),
                      border: Border.all(
                        color: _tierColor.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _tierColor.withValues(alpha: 0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _worldTypeIcon,
                          size: VIconSize.sm,
                          color: _tierColor,
                        ),
                        const SizedBox(width: VSpacing.sm),
                        Text(
                          _tierLabel,
                          style: TextStyle(
                            fontSize: VFontSize.labelSm,
                            fontWeight: VFontWeight.bold,
                            color: _tierColor,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: VSpacing.lg),

                  // World name
                  Text(
                    world.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: VFontSize.headlineLg,
                      fontWeight: VFontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: VSpacing.sm),

                  // Description
                  Text(
                    world.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: VFontSize.bodyMd,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),

                  const Spacer(),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ShareStat(
                        icon: Icons.people,
                        value: '${world.memberCount}',
                        label: 'MEMBERS',
                        color: _tierColor,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      _ShareStat(
                        icon: Icons.auto_awesome,
                        value: '${world.prestige}',
                        label: 'PRESTIGE',
                        color: _tierColor,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      _ShareStat(
                        icon: Icons.local_fire_department,
                        value: '${world.activityScore}',
                        label: 'ACTIVITY',
                        color: _tierColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: VSpacing.xl),

                  // Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.xl,
                      vertical: VSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _tierColor.withValues(alpha: 0.08),
                          _tierColor.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        VRadius.md,
                      ),
                      border: Border.all(
                        color: _tierColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.diamond,
                          size: VIconSize.sm + 2,
                          color: _tierColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: VSpacing.sm),
                        Text(
                          'Join me on Vertiege',
                          style: TextStyle(
                            fontSize: VFontSize.bodyMd,
                            fontWeight: VFontWeight.semiBold,
                            color: _tierColor.withValues(alpha: 0.9),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: VSpacing.md),

                  // Sovereign attribution
                  Text(
                    'Sovereign: ${world.sovereignName}',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: Theme.of(context).colorScheme.outline,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tier-colored bottom accent bar ─────────────────
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _tierColor.withValues(alpha: 0.9),
                  _tierColor.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ShareStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: VIconSize.md, color: color.withValues(alpha: 0.7)),
        const SizedBox(height: VSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontSize: VFontSize.headlineMd,
            fontWeight: VFontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            color: Theme.of(context).colorScheme.outline,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
