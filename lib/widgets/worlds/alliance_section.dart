import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';
import '../../ui/buttons/v_button.dart';

class AllianceSection extends ConsumerWidget {
  final String worldId;
  final dynamic world;

  const AllianceSection({
    super.key,
    required this.worldId,
    required this.world,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alliances = ref
        .watch(worldProvider)
        .alliances
        .where((a) => a.worldId1 == worldId || a.worldId2 == worldId)
        .toList();

    if (alliances.isEmpty) return const SizedBox.shrink();

    return Padding(

      child: FCard(

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: VColors.tertiary,

                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const Text(
                  'ALLIANCES',
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.semiBold,
                    color: VColors.tertiary,
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

                child: FCard(

                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: VColors.tertiary.withValues(alpha: 0.12),

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
                              allyName,
                              style: TextStyle(
                                fontSize: FontSizes.headlineMd,
                                fontWeight: FontWeights.semiBold,
                                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                              ),
                            ),
                            Text(
                              '$memberCount members',
                              style: TextStyle(
                                fontSize: FontSizes.labelSm,
                                color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VButton(
                        label: 'VISIT',
                        onPressed: () => context.push('/explore/$allyId'),
                        size: ButtonSize.small,
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
