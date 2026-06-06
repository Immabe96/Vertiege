import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/worlds/world_icon.dart';
import '../../theme/v_animation.dart';
import 'v_world_switcher_sheet.dart';

/// Fixed left rail of joined **world** icons (fast-switch pattern; Vertiege lexicon).
class VWorldRail extends StatelessWidget {
  final List<World> worlds;
  final String? selectedWorldId;
  final ValueChanged<World> onWorldSelected;
  final VoidCallback onAddWorld;
  final Map<String, int> unreadByWorldId;
  final Set<String> mutedWorldIds;
  final void Function(World world)? onToggleMute;
  final VoidCallback? onQuickSwitch;

  static const double railWidth = 52;
  static const double iconSize = 48;
  /// WCAG minimum touch target (DCX-131).
  static const double minTouchTarget = 44;

  const VWorldRail({
    super.key,
    required this.worlds,
    required this.selectedWorldId,
    required this.onWorldSelected,
    required this.onAddWorld,
    this.unreadByWorldId = const {},
    this.mutedWorldIds = const {},
    this.onToggleMute,
    this.onQuickSwitch,
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
                  cacheExtent: 240,
                  itemCount: worlds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: VSpacing.sm),
                  itemBuilder: (context, index) {
                    final world = worlds[index];
                    final unread = unreadByWorldId[world.id] ?? 0;
                    final muted = mutedWorldIds.contains(world.id);
                    return _WorldRailItem(
                      world: world,
                      selected: world.id == selectedWorldId,
                      unreadCount: unread,
                      muted: muted,
                      onTap: () => onWorldSelected(world),
                      onLongPress: () => _showWorldContextMenu(
                        context,
                        world,
                        muted: muted,
                        onToggleMute: onToggleMute,
                        onQuickSwitch: onQuickSwitch,
                        worlds: worlds,
                        selectedWorldId: selectedWorldId,
                        onWorldSelected: onWorldSelected,
                      ),
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

void _showWorldContextMenu(
  BuildContext context,
  World world, {
  required bool muted,
  void Function(World world)? onToggleMute,
  VoidCallback? onQuickSwitch,
  List<World>? worlds,
  String? selectedWorldId,
  ValueChanged<World>? onWorldSelected,
}) {
  final residentLabel = world.memberCount == 1
      ? '1 resident'
      : '${world.memberCount} residents';

  showVSheet(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.md,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            world.name,
            style: const TextStyle(
              fontSize: VFontSize.headlineSm,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimary,
            ),
          ),
          const SizedBox(height: VSpacing.xxs),
          Text(
            residentLabel,
            style: const TextStyle(
              fontSize: VFontSize.bodyMd,
              color: VCommuneColors.textMuted,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          if (onQuickSwitch != null &&
              worlds != null &&
              worlds.length > 1 &&
              onWorldSelected != null)
            VTile(
              prefix: const Icon(Icons.swap_horiz),
              title: const Text('Switch world'),
              onPress: () {
                Navigator.pop(context);
                showWorldSwitcherSheet(
                  context,
                  worlds: worlds,
                  selectedWorldId: selectedWorldId,
                  onWorldSelected: onWorldSelected,
                );
              },
            ),
          VTile(
            prefix: const Icon(Icons.public_outlined),
            title: const Text('Open world'),
            onPress: () {
              Navigator.pop(context);
              context.push(exploreWorldPath(world.id));
            },
          ),
          VTile(
            prefix: const Icon(Icons.settings_outlined),
            title: const Text('World settings'),
            onPress: () {
              Navigator.pop(context);
              context.push('/explore/${world.id}/settings');
            },
          ),
          if (onToggleMute != null)
            VTile(
              prefix: Icon(
                muted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(muted ? 'Unmute notifications' : 'Mute notifications'),
              onPress: () {
                Navigator.pop(context);
                onToggleMute(world);
              },
            ),
        ],
      ),
    ),
    maxSize: 0.45,
  );
}

class _WorldRailItem extends StatelessWidget {
  final World world;
  final bool selected;
  final int unreadCount;
  final bool muted;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _WorldRailItem({
    required this.world,
    required this.selected,
    required this.unreadCount,
    this.muted = false,
    required this.onTap,
    this.onLongPress,
  });

  String get _tooltipMessage {
    final residents = world.memberCount == 1
        ? '1 resident'
        : '${world.memberCount} residents';
    if (muted) return '${world.name}\n$residents\nMuted';
    return '${world.name}\n$residents';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: world.name,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: VWorldRail.minTouchTarget,
          minHeight: VWorldRail.minTouchTarget,
        ),
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
                duration: VMotion.panel(context),
                curve: VMotion.curve(context),
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
            Tooltip(
              message: _tooltipMessage,
              preferBelow: false,
              verticalOffset: 20,
              triggerMode: TooltipTriggerMode.longPress,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  customBorder: const CircleBorder(),
                  splashColor: VCommuneColors.modifierActive,
                  highlightColor: VCommuneColors.modifierHover,
                  child: WorldIcon(
                    worldId: world.assetKey,
                    size: VWorldRail.iconSize,
                    useGlassContainer: false,
                    circular: true,
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 2,
                bottom: 0,
                child: unreadCount > 1
                    ? _UnreadPill(count: unreadCount)
                    : const _UnreadDot(),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Single-unread indicator — white dot without a count (DCX-075).
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: VCommuneColors.headerPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: VCommuneColors.surfaceTertiary, width: 2),
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: VWorldRail.minTouchTarget,
              minHeight: VWorldRail.minTouchTarget,
            ),
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
      ),
    );
  }
}
