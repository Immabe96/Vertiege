import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/v_tokens.dart';
import '../../theme/colors.dart';
import '../../models/world.dart';
import '../../models/resident.dart';
import '../../models/channel.dart';
import '../../state/world_provider.dart';
import 'resource_vault.dart';
import 'chat_preview_panel.dart';
import 'alliance_section.dart';

class WorldHubTab extends ConsumerWidget {
  final String worldId;
  final World? world;
  final Resident? resident;
  final List<WorldChannel> channels;
  final Widget foundationSummary;

  const WorldHubTab({
    super.key,
    required this.worldId,
    required this.world,
    required this.resident,
    required this.channels,
    required this.foundationSummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (world == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isJoined = resident?.joinedWorldIds.contains(worldId) ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          foundationSummary,
          const SizedBox(height: VSpacing.lg),
          if (world!.prestige >= 20 || world!.type.name == 'dominion') ...[
            Text(
              'Features',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            Wrap(
              spacing: VSpacing.sm,
              runSpacing: VSpacing.sm,
              children: [
                if (world!.type.name == 'dominion' || world!.prestige >= 30)
                  _FeatureCard(
                    title: 'Marketplace',
                    icon: Icons.storefront,
                    color: VColors.primary,
                    onTap: () => context.push('/explore/$worldId/market'),
                  ),
                if (isJoined)
                  _FeatureCard(
                    title: 'Polls',
                    icon: Icons.how_to_vote,
                    color: VColors.warning,
                    onTap: () => context.push('/explore/$worldId/polls'),
                  ),
                if (world!.prestige >= 25)
                  _FeatureCard(
                    title: 'Treasury',
                    icon: Icons.account_balance,
                    color: VColors.success,
                    onTap: () => context.push('/explore/$worldId/treasury'),
                  ),
                if (isJoined)
                  _FeatureCard(
                    title: 'Challenges',
                    icon: VIcons.trophy,
                    color: VColors.tertiary,
                    onTap: () => context.push('/explore/$worldId/challenges'),
                  ),
              ],
            ),
            const SizedBox(height: VSpacing.lg),
          ],
          ResourceVault(
            worldId: worldId,
            channels: channels,
            vaultUnlocked: ref
                .read(worldProvider.notifier)
                .featuresForWorld(worldId)
                .vault,
          ),
          const SizedBox(height: VSpacing.lg),
          ChatPreviewPanel(worldId: worldId),
          const SizedBox(height: VSpacing.lg),
          AllianceSection(worldId: worldId, world: world!),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width:
              (MediaQuery.of(context).size.width -
                  VSpacing.md * 2 -
                  VSpacing.sm) /
              2,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark
                ? VColors.surfaceContainerDark
                : VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.lg),
            border: Border.all(
              color: isDark
                  ? VColors.outlineVariantDark.withValues(alpha: 0.28)
                  : VColors.outlineVariant.withValues(alpha: 0.55),
              width: 0.5,
            ),
            boxShadow: VShadow.sm,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  widget.icon,
                  color: widget.color.withValues(alpha: 0.2),
                  size: 64,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(VSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(VRadius.sm),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: VIconSize.md,
                      ),
                    ),
                    const SizedBox(height: VSpacing.md),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: VFontWeight.bold,
                        color: isDark
                            ? VColors.onSurfaceDark
                            : VColors.onSurface,
                        letterSpacing: 0.5,
                      ),
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
