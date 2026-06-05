import 'package:flutter/material.dart';

import '../../models/world.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/worlds/world_icon.dart';
import '../shell/v_overlapping_panels.dart';

/// Fixed left rail of joined **world** icons (fast-switch pattern; Vertiege lexicon).
class VWorldRail extends StatelessWidget {
  final List<World> worlds;
  final String? selectedWorldId;
  final ValueChanged<World> onWorldSelected;
  final VoidCallback onAddWorld;
  final Map<String, int> unreadByWorldId;

  static const double railWidth = 48;
  static const double iconSize = 40;

  const VWorldRail({
    super.key,
    required this.worlds,
    required this.selectedWorldId,
    required this.onWorldSelected,
    required this.onAddWorld,
    this.unreadByWorldId = const {},
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VCommuneColors.surfaceTertiary,
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: railWidth,
          child: Column(
            children: [
              const SizedBox(height: VSpacing.sm),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.xs),
                  itemCount: worlds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: VSpacing.sm),
                  itemBuilder: (context, index) {
                    final world = worlds[index];
                    final unread = unreadByWorldId[world.id] ?? 0;
                    return _WorldRailItem(
                      world: world,
                      selected: world.id == selectedWorldId,
                      unreadCount: unread,
                      onTap: () => onWorldSelected(world),
                    );
                  },
                ),
              ),
              _AddWorldButton(onTap: onAddWorld),
              const SizedBox(height: VSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldRailItem extends StatelessWidget {
  final World world;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  const _WorldRailItem({
    required this.world,
    required this.selected,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: world.name,
      child: SizedBox(
        width: VWorldRail.railWidth,
        height: VWorldRail.iconSize + VSpacing.xs,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: VOverlappingPanels.animationDuration,
                curve: VOverlappingPanels.animationCurve,
                width: 4,
                height: selected ? 20 : 0,
                margin: const EdgeInsets.only(left: 2),
                decoration: const BoxDecoration(
                  color: VCommuneColors.headerPrimary,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(VRadius.xs),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                splashColor: VCommuneColors.modifierActive,
                highlightColor: VCommuneColors.modifierHover,
                child: ClipOval(
                  child: WorldIcon(
                    worldId: world.assetKey,
                    size: VWorldRail.iconSize,
                    useGlassContainer: false,
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 2,
                bottom: 0,
                child: _UnreadPill(count: unreadCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _UnreadPill extends StatelessWidget {
  final int count;

  const _UnreadPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: VCommuneColors.headerPrimary,
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(color: VCommuneColors.surfaceTertiary, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: VCommuneColors.surfaceFloating,
          fontSize: VFontSize.labelSm,
          fontWeight: VFontWeight.bold,
          height: VLineHeight.label,
        ),
      ),
    );
  }
}

class _AddWorldButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddWorldButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Discover worlds',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: VCommuneColors.modifierActive,
          highlightColor: VCommuneColors.modifierHover,
          child: Container(
            width: VWorldRail.iconSize,
            height: VWorldRail.iconSize,
            decoration: const BoxDecoration(
              color: VCommuneColors.surfaceSecondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              size: VIconSize.lg,
              color: VCommuneColors.statusOnline,
            ),
          ),
        ),
      ),
    );
  }
}
