import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';
import '../../ui/buttons/v_button.dart';

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
                        VButton(
                          label: 'Accept',
                          onPressed: () => onAccept(world.id),
                          size: ButtonSize.small,
                        ),
                        const SizedBox(width: Spacing.sm),
                        VButton(
                          label: 'Decline',
                          onPressed: () => onDecline(world.id),
                          variant: ButtonVariant.outlined,
                          size: ButtonSize.small,
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
