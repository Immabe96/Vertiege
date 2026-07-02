import 'package:flutter/material.dart';
import 'package:vertiege/ui/ui.dart';

import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Pinned toolbar for world detail — no edge-to-edge banner or text-on-image.
class WorldHeroBanner extends StatelessWidget {
  final World world;
  /// Retained for caller compatibility; app is dark-only.
  final bool isDark;
  final Color prestigeTierColor;
  final bool isJoined;
  final bool innerBoxIsScrolled;
  final Animation<double> scaleAnimation;
  final GlobalKey joinButtonKey;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback? onSettings;
  final VoidCallback? onOpenTools;
  final VoidCallback onJoin;

  const WorldHeroBanner({
    super.key,
    required this.world,
    this.isDark = true,
    required this.prestigeTierColor,
    required this.isJoined,
    required this.innerBoxIsScrolled,
    required this.scaleAnimation,
    required this.joinButtonKey,
    required this.onBack,
    required this.onShare,
    this.onSettings,
    this.onOpenTools,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collapsed = innerBoxIsScrolled;
    final fg = VColors.onSurfaceDark;
    final bg = VColors.surfaceDark;
    final divider = VColors.outlineDark;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bg,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(VIcons.chevronLeft),
        tooltip: 'Back',
        onPressed: onBack,
      ),
      title: collapsed
          ? Text(
              world.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.semiBold,
                color: fg,
              ),
            )
          : Text(
              'World',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.medium,
                color: VColors.onSurfaceVariantDark,
              ),
            ),
      actions: [
        if (onOpenTools != null)
          IconButton(
            icon: const Icon(VIcons.ellipsis),
            tooltip: 'World tools',
            onPressed: onOpenTools,
          ),
        IconButton(
          icon: const Icon(VIcons.share),
          tooltip: 'Share world',
          onPressed: onShare,
        ),
        if (onSettings != null)
          IconButton(
            icon: const Icon(VIcons.settings),
            tooltip: 'World settings',
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: divider),
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
