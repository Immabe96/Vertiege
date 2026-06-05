import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vertiege/ui/ui.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import '../../models/world.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../services/access_control.dart';
import '../../services/store_service.dart';
import '../../services/legacy_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_assets.dart';
import '../core/fade_in.dart';
import '../core/sovereign_card.dart';
import '../../ui/icons/v_icons.dart';
import 'world_icon.dart';
import 'world_banner.dart';
import '../../widgets/core/v_feedback.dart';

CardTier _getPrestigeTier(int prestige) {
  if (prestige >= 600) return CardTier.apex;
  if (prestige >= 300) return CardTier.elite;
  return CardTier.hustler;
}

class WorldCard extends ConsumerWidget {
  final World world;
  final int index;
  final bool wide;

  /// Clean list style for Discover — no prestige glow border.
  final bool plainStyle;

  const WorldCard({
    super.key,
    required this.world,
    this.index = 0,
    this.wide = false,
    this.plainStyle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final isLocked = resident != null && !canAccessWorld(resident, world);
    final tier = _getPrestigeTier(world.prestige);
    final layout = wide
        ? _WideLayout(world: world, isLocked: isLocked, plainStyle: plainStyle)
        : _SquareLayout(world: world, isLocked: isLocked, plainStyle: plainStyle);

    if (plainStyle) {
      return FadeIn(
        delayMs: index * 40,
        child: VSurfaceCard(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(exploreWorldPath(world.id)),
              borderRadius: BorderRadius.circular(VRadius.lg),
              child: layout,
            ),
          ),
        ),
      );
    }

    return FadeIn(
      delayMs: index * 60,
      child: SovereignCard(
        tier: tier,
        onTap: () => context.push(exploreWorldPath(world.id)),
        child: layout,
      ),
    );
  }
}

// ── Square layout (featured) ──────────────────────────────

class _SquareLayout extends StatelessWidget {
  final World world;
  final bool isLocked;
  final bool plainStyle;

  const _SquareLayout({
    required this.world,
    required this.isLocked,
    this.plainStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _BannerThumbnail(
          world: world,
          compact: false,
          plainStyle: plainStyle,
        ),
        _CardBody(world: world, isLocked: isLocked),
      ],
    );
  }
}

// ── Wide / rectangular layout (lists) ─────────────────────

class _WideLayout extends StatelessWidget {
  final World world;
  final bool isLocked;
  final bool plainStyle;

  const _WideLayout({
    required this.world,
    required this.isLocked,
    this.plainStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 120,
            child: _BannerThumbnail(
              world: world,
              compact: true,
              plainStyle: plainStyle,
            ),
          ),
          Expanded(
            child: _CardBody(world: world, isLocked: isLocked),
          ),
        ],
      ),
    );
  }
}

// ── Card body (text content) ──────────────────────────────

class _CardBody extends ConsumerWidget {
  final World world;
  final bool isLocked;

  const _CardBody({required this.world, required this.isLocked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canBoost = false;
    final worldAlliances = ref.watch(worldProvider).alliances
        .where((a) => a.worldId1 == world.id || a.worldId2 == world.id)
        .toList();
    final legacyTier = LegacyService.calculateLegacy(
      world.prestige,
      DateTime.fromMillisecondsSinceEpoch(world.createdAt > 0 ? world.createdAt : DateTime.now().millisecondsSinceEpoch),
    );

    return Padding(
      padding: const EdgeInsets.all(VSpacing.sm + 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            world.name,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: VFontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(VIcons.users, size: 12, color: VColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${world.memberCount} ${world.memberCount == 1 ? 'member' : 'members'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: VColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: VSpacing.sm),
              Text(
                '★ P${world.prestige}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: VFontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            world.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: VSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Badge(
                label: world.type.name,
                icon: Icons.public,
                color: theme.colorScheme.secondary,
              ),
              if (isLocked)
                _Badge(label: 'Locked', icon: Icons.lock, color: theme.colorScheme.error),
              if (legacyTier != LegacyTier.none)
                _Badge(
                  label: 'LEGACY: ${legacyTier.label}',
                  icon: Icons.auto_awesome,
                  color: legacyTier.color,
                ),
              for (final alliance in worldAlliances)
                _Badge(
                  label: 'ALLIED WITH ${alliance.allyName(world.id).toUpperCase()}',
                  icon: Icons.handshake,
                  color: VColors.tertiary,
                ),
            ],
          ),
          if (canBoost) ...[
            const SizedBox(height: VSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: VTouchTarget.iconButton,
              child: OutlinedButton.icon(
                onPressed: () => _handleBoost(context, ref),
                icon: const Icon(VIcons.rocket, size: VIconSize.sm),
                label: const Text('Boost'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VColors.tertiary,
                  side: const BorderSide(color: VColors.tertiary),
                  padding: const EdgeInsets.symmetric(horizontal: VSpacing.sm),
                  textStyle: const TextStyle(fontSize: VFontSize.labelSm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleBoost(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final result = await ref.read(worldProvider.notifier).boostWorld(world.id);
    if (!context.mounted) return;

    if (result == StorePurchaseState.purchased) {
      VFeedback.showMessage(context, '${world.name} boosted! +${World.boostActivityPoints} activity pts — improved Discover ranking.',);
    } else if (result == StorePurchaseState.error) {
      VFeedback.showMessage(context, 'Boost failed. Please try again.');
    }
  }
}

// ── Banner Thumbnail ──────────────────────────────────────

class _BannerThumbnail extends StatelessWidget {
  final World world;
  final bool compact;
  final bool plainStyle;

  const _BannerThumbnail({
    required this.world,
    this.compact = false,
    this.plainStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = compact ? double.infinity : 80.0;

    return SizedBox(
      height: compact ? null : 80,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'world-icon-${world.id}',
              child: WorldBanner(
                worldId: world.id,
                assetKey: world.assetKey,
                width: double.infinity,
                height: compact ? double.infinity : 80,
                worldType: world.type,
                prestige: world.prestige,
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

            // World icon overlaid at bottom-center (skip in plain discover cards)
            if (!compact && !plainStyle)
              Positioned(
                bottom: -6,
                left: 0,
                right: 0,
                child: Center(
                  child: WorldIcon(
                    worldId: world.assetKey,
                    size: VIconSize.md + 16,
                    tintColor: WorldAssets.colorForPrestige(world.prestige),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.sm, vertical: VSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: VIconSize.xs, color: color),
          const SizedBox(width: 3),
          Text(label,
            style: TextStyle(
              color: color,
              fontSize: VFontSize.labelSm,
              fontWeight: VFontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
