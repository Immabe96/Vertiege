import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
      child: VSurfacePanel(
        padding: const EdgeInsets.all(VSpacing.lg),
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
                    borderRadius: BorderRadius.circular(VRadius.sm),
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                const Text(
                  'ALLIANCES',
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.semiBold,
                    color: VColors.tertiary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
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
                padding: const EdgeInsets.only(bottom: VSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(VSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? VColors.surfaceDark
                        : VColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: VColors.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(VRadius.sm),
                        ),
                        child: Icon(
                          iconData,
                          size: VIconSize.md,
                          color: VColors.tertiary,
                        ),
                      ),
                      const SizedBox(width: VSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              allyName,
                              style: TextStyle(
                                fontSize: VFontSize.headlineMd,
                                fontWeight: VFontWeight.semiBold,
                                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                              ),
                            ),
                            Text(
                              '$memberCount members',
                              style: TextStyle(
                                fontSize: VFontSize.labelSm,
                                color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VButton(
                        label: 'VISIT',
                        onPressed: () => context.push(exploreWorldPath(allyId)),
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
