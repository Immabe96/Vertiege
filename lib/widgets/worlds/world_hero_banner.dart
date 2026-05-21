import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import '../../theme/v_colors.dart';
import '../../models/world.dart';
import 'world_banner.dart';
import '../../ui/icons/v_icons.dart';

class WorldHeroBanner extends StatelessWidget {
  final String worldId;
  final double scrollOffset;
  final String worldName;
  final bool isJoined;
  final Animation<double> scaleAnimation;
  final AnimationController joinAnimController;
  final GlobalKey joinButtonKey;
  final VoidCallback onJoin;
  final VoidCallback? onSettings;
  final WorldType worldType;
  final int prestige;

  const WorldHeroBanner({
    super.key,
    required this.worldId,
    required this.scrollOffset,
    required this.worldName,
    required this.isJoined,
    required this.scaleAnimation,
    required this.joinAnimController,
    required this.joinButtonKey,
    required this.onJoin,
    this.onSettings,
    this.worldType = WorldType.wealth,
    this.prestige = 0,
  });

  @override
  Widget build(BuildContext context) {
    const expandedHeight = 260.0;
    final theme = Theme.of(context);
    final parallaxOffset = (scrollOffset * 0.5).clamp(0.0, expandedHeight);
    final collapseProgress =
        (scrollOffset / (expandedHeight - kToolbarHeight - 48)).clamp(0.0, 1.0);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      actions: [
        if (onSettings != null)
          IconButton(
            icon: const Icon(VIcons.settings, size: IconSizes.md),
            tooltip: 'World settings',
            onPressed: onSettings,
          ),
        ScaleTransition(
          scale: scaleAnimation,
          child: AnimatedBuilder(
            animation: joinAnimController,
            builder: (context, _) {
              if (isJoined) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton.icon(
                    key: joinButtonKey,
                    onPressed: onJoin,
                    icon: const Icon(VIcons.logOut, size: IconSizes.sm),
                    label: const Text('Leave'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilledButton.icon(
                  key: joinButtonKey,
                  onPressed: onJoin,
                  icon: const Icon(VIcons.plus, size: IconSizes.sm),
                  label: const Text('Join'),
                  style: FilledButton.styleFrom(
                    backgroundColor: VColors.primary,
                    foregroundColor: VColors.onPrimary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          // Parallax banner
          Positioned(
            top: -parallaxOffset,
            left: 0,
            right: 0,
            height: expandedHeight,
            child: Hero(
              tag: 'world-icon-$worldId',
              child: WorldBanner(
                worldId: worldId,
                worldType: worldType,
                prestige: prestige,
              ),
            ),
          ),
          // Minimal text-safety fade that preserves banner colors.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: expandedHeight * 0.55,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      VColors.scrim.withValues(alpha: 0.24),
                      VColors.scrim.withValues(alpha: 0.44),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Title on banner (fades out on scroll)
          Positioned(
            left: Spacing.md,
            right: Spacing.md,
            bottom: 20,
            child: Opacity(
              opacity: (1.0 - collapseProgress).clamp(0.0, 1.0),
              child: Text(
                worldName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                  color: VColors.onPrimary,
                  letterSpacing: LetterSpacing.section,
                  shadows: const [
                    Shadow(
                      color: VColors.scrim,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
