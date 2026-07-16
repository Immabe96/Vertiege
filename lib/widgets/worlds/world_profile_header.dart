import 'package:flutter/material.dart';
import 'package:vertiege/ui/ui.dart';
import 'package:go_router/go_router.dart';

import '../../config/progression_glossary.dart';
import '../../config/world_page_ia.dart';
import '../core/progression_help_button.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import 'world_banner.dart';
import 'world_here_subtitle.dart';
import 'world_icon.dart';

/// Icon + name + chevron — chat-first world identity (no hero banner).
class WorldCompactHeader extends StatelessWidget {
  final World world;
  final VoidCallback? onTap;
  final Widget? trailing;

  const WorldCompactHeader({
    super.key,
    required this.world,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = VColors.onSurfaceVariantDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          child: Row(
            children: [
              WorldIcon(
                worldId: world.assetKey,
                size: VWorldIconSize.list,
                useGlassContainer: false,
              ),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Text(
                  world.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: VColors.onSurfaceDark,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.expand_more, size: VIconSize.md, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal world identity block — contained banner, typography on surface.
///
/// Used below the pinned app bar on [WorldDetailScreen] (not over the image).
/// Set [compact] on the chat path (joined residents) to drop the hero banner card.
class WorldProfileHeader extends StatelessWidget {
  final World world;
  final String worldId;
  final Color prestigeTierColor;
  final String tierLabel;
  final bool isJoined;
  final bool compact;
  final Animation<double> scaleAnimation;
  final GlobalKey joinButtonKey;
  final VoidCallback onJoin;
  final VoidCallback? onHeaderTap;

  const WorldProfileHeader({
    super.key,
    required this.world,
    required this.worldId,
    required this.prestigeTierColor,
    required this.tierLabel,
    required this.isJoined,
    this.compact = false,
    required this.scaleAnimation,
    required this.joinButtonKey,
    required this.onJoin,
    this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return WorldCompactHeader(
        world: world,
        onTap: onHeaderTap ?? () => context.push(exploreWorldPath(worldId)),
      );
    }

    final theme = Theme.of(context);
    final muted = VColors.onSurfaceVariantDark;
    final surface = VColors.surfaceContainerLowDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        VSpacing.xs,
      ),
      child: VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.lg),
                child: AspectRatio(
                  aspectRatio: 2.35,
                  child: Hero(
                    tag: 'world-icon-$worldId',
                    child: WorldBanner(
                      worldId: world.id,
                      assetKey: world.assetKey,
                      width: double.infinity,
                      height: double.infinity,
                      worldType: world.type,
                      prestige: world.prestige,
                      contained: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorldIcon(
                    worldId: world.assetKey,
                    size: VWorldIconSize.header,
                    useGlassContainer: false,
                  ),
                  const SizedBox(width: VSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: VSpacing.xs,
                          runSpacing: VSpacing.xs,
                          children: [
                            _Tag(
                              label: WorldPageIa.worldKindLabel(world),
                              color: prestigeTierColor,
                            ),
                            _Tag(
                              label: ProgressionGlossary.worldEntryGateLabel(
                                world,
                                tierLabel,
                              ),
                              color: muted,
                              outline: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: VSpacing.sm),
                        Text(
                          world.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: VFontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: VSpacing.xxs),
                        WorldHereSubtitleText(
                          world: world,
                          isJoined: isJoined,
                          tierLabel: tierLabel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (world.hasSovereign || world.isUnclaimed) ...[
                const SizedBox(height: VSpacing.sm),
                Material(
                  color: surface,
                  borderRadius: BorderRadius.circular(VRadius.md),
                  child: InkWell(
                    onTap: world.sovereignId.isNotEmpty
                        ? () => context.push(
                            residentProfilePath(world.sovereignId),
                          )
                        : null,
                    borderRadius: BorderRadius.circular(VRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.sm,
                        vertical: VSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: VIconSize.sm,
                            color: prestigeTierColor,
                          ),
                          const SizedBox(width: VSpacing.sm),
                          Expanded(
                            child: Text(
                              WorldPageIa.adminStatusLabel(world),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                                fontWeight: VFontWeight.medium,
                              ),
                            ),
                          ),
                          if (world.sovereignId.isNotEmpty)
                            Icon(
                              Icons.chevron_right,
                              size: VIconSize.sm,
                              color: muted,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (world.description.trim().isNotEmpty) ...[
                const SizedBox(height: VSpacing.sm),
                Text(
                  world.description.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: VSpacing.md),
              const Align(
                alignment: Alignment.centerRight,
                child: ProgressionHelpButton(
                  focus: ProgressionFocus.worldPrestige,
                  iconSize: VIconSize.sm,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              ScaleTransition(
                scale: scaleAnimation,
                child: VButton(
                  key: joinButtonKey,
                  onPressed: onJoin,
                  variant: isJoined
                      ? ButtonVariant.outlined
                      : ButtonVariant.filled,
                  label: isJoined
                      ? 'Leave world'
                      : world.isUnclaimed
                      ? 'Join & claim admin'
                      : 'Join world',
                ),
              ),
            ],
          ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final bool outline;

  const _Tag({
    required this.label,
    required this.color,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: VSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: outline ? 0.35 : 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: VFontSize.labelSm,
          fontWeight: VFontWeight.semiBold,
          color: color,
        ),
      ),
    );
  }
}
