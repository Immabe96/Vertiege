import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/world_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';

class AllianceSection extends ConsumerWidget {
  final String worldId;
  final dynamic world;

  const AllianceSection({super.key, required this.worldId, required this.world});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alliances = ref
        .watch(worldProvider)
        .alliances
        .where((a) => a.worldId1 == worldId || a.worldId2 == worldId)
        .toList();

    if (alliances.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: GlassPanel(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const Text(
                  'ALLIANCES',
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.semiBold,
                    color: AppColors.tertiary,
                    letterSpacing: LetterSpacing.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            ...alliances.map((alliance) {
              final allyName = alliance.allyName(worldId);
              final allyId = alliance.allieOf(worldId);
              final allyWorld = ref.watch(worldProvider).worlds[allyId];
              final memberCount = allyWorld?.memberCount ?? 0;
              final iconStr = allyWorld?.icon ?? 'earth';

              const iconMap = {
                'public': Icons.public,
                'landscape': Icons.landscape,
                'science': Icons.science,
                'account_balance': Icons.account_balance,
                'rocket': Icons.rocket,
                'palette': Icons.palette,
                'music_note': Icons.music_note,
                'code': Icons.code,
                'earth': Icons.public,
              };
              final iconData = iconMap[iconStr] ?? Icons.public;

              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: GlassPanel(
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
                              allyName,
                              style: const TextStyle(
                                fontSize: FontSizes.headlineMd,
                                fontWeight: FontWeights.semiBold,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '$memberCount members',
                              style: const TextStyle(
                                fontSize: FontSizes.labelSm,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => context.push('/explore/$allyId'),
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
                          'VISIT',
                          style: TextStyle(
                            fontSize: FontSizes.labelSm,
                            fontWeight: FontWeights.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
