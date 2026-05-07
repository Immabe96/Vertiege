import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../theme/colors.dart';
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
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              const Text(
                'WORLD INVITES',
                style: TextStyle(
                  fontSize: FontSizes.headlineMd,
                  fontWeight: FontWeights.semiBold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ...invites.map((world) {
            final iconData = worldIconMap[world.icon] ?? Icons.public;
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
                        color: AppColors.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      ),
                      child: Icon(iconData, size: IconSizes.md, color: AppColors.tertiary),
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
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            memberLabel,
                            style: const TextStyle(
                              fontSize: FontSizes.labelSm,
                              color: AppColors.inkSecondary,
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
                            backgroundColor: AppColors.tertiary,
                            foregroundColor: AppColors.onTertiary,
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
                            foregroundColor: AppColors.inkSecondary,
                            side: const BorderSide(color: AppColors.glassBorder),
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
}
