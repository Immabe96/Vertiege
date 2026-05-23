import 'package:flutter/material.dart';

import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import 'world_banner.dart';

/// Collapsible world hero for [NestedScrollView] — pinned bar with name + actions on scroll.
class WorldHeroBanner extends StatelessWidget {
  final String worldId;
  final World world;
  final double expandedHeight;
  final bool isDark;
  final Color prestigeTierColor;
  final String tierLabel;
  final bool isJoined;
  final bool innerBoxIsScrolled;
  final Animation<double> scaleAnimation;
  final AnimationController joinAnimController;
  final GlobalKey joinButtonKey;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback? onSettings;
  final VoidCallback onJoin;

  const WorldHeroBanner({
    super.key,
    required this.worldId,
    required this.world,
    required this.expandedHeight,
    required this.isDark,
    required this.prestigeTierColor,
    required this.tierLabel,
    required this.isJoined,
    required this.innerBoxIsScrolled,
    required this.scaleAnimation,
    required this.joinAnimController,
    required this.joinButtonKey,
    required this.onBack,
    required this.onShare,
    this.onSettings,
    required this.onJoin,
  });

  Color get _collapsedFg =>
      isDark ? VColors.onSurfaceDark : VColors.onSurface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collapsed = innerBoxIsScrolled;
    final toolbarFg = collapsed ? _collapsedFg : Colors.white;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      foregroundColor: toolbarFg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        color: toolbarFg,
        onPressed: onBack,
      ),
      title: collapsed
          ? Text(
              world.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
                color: _collapsedFg,
              ),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share world',
          color: toolbarFg,
          onPressed: onShare,
        ),
        if (onSettings != null)
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'World settings',
            color: toolbarFg,
            onPressed: onSettings,
          ),
        if (collapsed)
          Padding(
            padding: const EdgeInsets.only(right: VSpacing.xs),
            child: ScaleTransition(
              scale: scaleAnimation,
              child: _CollapsedJoinChip(
                isJoined: isJoined,
                prestigeTierColor: prestigeTierColor,
                joinButtonKey: joinButtonKey,
                onJoin: onJoin,
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: prestigeTierColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: prestigeTierColor.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              SizedBox(
                height: expandedHeight,
                width: double.infinity,
                child: Hero(
                  tag: 'world-icon-$worldId',
                  child: WorldBanner(
                    worldId: world.id,
                    assetKey: world.assetKey,
                    width: double.infinity,
                    height: expandedHeight,
                    worldType: world.type,
                    prestige: world.prestige,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.35, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.md,
                          vertical: VSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: prestigeTierColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(VRadius.md),
                          border: Border.all(
                            color: prestigeTierColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          world.requiredProfession != null
                              ? tierLabel.toUpperCase()
                              : 'TIER $tierLabel'.toUpperCase(),
                          style: TextStyle(
                            fontSize: VFontSize.labelMd,
                            fontWeight: VFontWeight.semiBold,
                            color: prestigeTierColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: VSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              world.name,
                              style: const TextStyle(
                                fontSize: VFontSize.headlineLg,
                                fontWeight: VFontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: VSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: VSpacing.sm,
                              vertical: VSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: VColors.tertiary,
                              borderRadius: BorderRadius.circular(VRadius.pill),
                              boxShadow: [
                                BoxShadow(
                                  color: VColors.tertiary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield,
                                  size: 12,
                                  color: VColors.onTertiary,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'SOVEREIGN',
                                  style: TextStyle(
                                    fontSize: VFontSize.labelMd,
                                    fontWeight: VFontWeight.bold,
                                    color: VColors.onTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (world.description.trim().isNotEmpty) ...[
                        const SizedBox(height: VSpacing.xs),
                        Text(
                          world.description.trim(),
                          style: TextStyle(
                            fontSize: VFontSize.bodyMd,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.3,
                            shadows: const [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: VSpacing.lg),
                      Row(
                        children: [
                          ScaleTransition(
                            scale: scaleAnimation,
                            child: AnimatedBuilder(
                              animation: joinAnimController,
                              builder: (context, _) {
                                final btnBg = isJoined
                                    ? VColors.error
                                    : prestigeTierColor;
                                final btnFg = isJoined
                                    ? VColors.onError
                                    : VColors.onPrimary;
                                return Semantics(
                                  button: true,
                                  label: isJoined
                                      ? 'Leave world'
                                      : 'Join world',
                                  child: FilledButton(
                                    key: joinButtonKey,
                                    onPressed: onJoin,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: btnBg,
                                      foregroundColor: btnFg,
                                      minimumSize: const Size(
                                        VTouchTarget.minimum,
                                        VTouchTarget.minimum,
                                      ),
                                    ),
                                    child: Text(
                                      isJoined ? 'LEAVE WORLD' : 'JOIN WORLD',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsedJoinChip extends StatelessWidget {
  final bool isJoined;
  final Color prestigeTierColor;
  final GlobalKey joinButtonKey;
  final VoidCallback onJoin;

  const _CollapsedJoinChip({
    required this.isJoined,
    required this.prestigeTierColor,
    required this.joinButtonKey,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isJoined ? 'Leave world' : 'Join world',
      child: TextButton(
        key: joinButtonKey,
        onPressed: onJoin,
        style: TextButton.styleFrom(
          foregroundColor: isJoined ? VColors.error : prestigeTierColor,
          minimumSize: const Size(VTouchTarget.minimum, 36),
        ),
        child: Text(isJoined ? 'Leave' : 'Join'),
      ),
    );
  }
}
