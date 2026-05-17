import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';

class WorldInviteSection extends StatelessWidget {
  final List<World> invites;
  final void Function(String worldId) onAccept;
  final void Function(String worldId) onDecline;

  const WorldInviteSection({
    super.key,
    required this.invites,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                        color: VColors.tertiary,
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              const Text(
                'WORLD INVITES',
                style: TextStyle(
                  fontSize: FontSizes.headlineMd,
                  fontWeight: FontWeights.semiBold,
                              color: VColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ...invites.map((world) {
            final iconData = _iconForWorldType(world.type);
            final memberLabel = '${world.memberCount} members';
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: GlassPanel(
                useBlur: false,
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: VColors.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      ),
                      child: Icon(
                        iconData,
                        size: IconSizes.md,
                  color: VColors.tertiary,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            world.name,
                            style: const TextStyle(
                              fontSize: FontSizes.headlineMd,
                              fontWeight: FontWeights.semiBold,
                  color: VColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            memberLabel,
                            style: const TextStyle(
                              fontSize: FontSizes.labelSm,
                              color: VColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: () => onAccept(world.id),
                          style: FilledButton.styleFrom(
                            backgroundColor: VColors.tertiary,
                            foregroundColor: VColors.onTertiary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: Spacing.sm,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: FontSizes.labelSm,
                              fontWeight: FontWeights.semiBold,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        OutlinedButton(
                          onPressed: () => onDecline(world.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VColors.onSurfaceVariant,
                            side: const BorderSide(
                              color: VColors.glassBorder,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: Spacing.sm,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              fontSize: FontSizes.labelSm,
                              fontWeight: FontWeights.semiBold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _iconForWorldType(WorldType type) {
    return switch (type) {
      WorldType.wealth => Icons.diamond,
      WorldType.profession => Icons.work,
      WorldType.dominion => Icons.shield,
    };
  }
}
