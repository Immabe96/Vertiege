import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/world_navigation.dart';
import '../../state/world_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Wayfinding for nested world admin routes (DCX-019).
class WorldAdminBreadcrumb extends ConsumerWidget {
  final String worldId;
  final String sectionTitle;

  const WorldAdminBreadcrumb({
    super.key,
    required this.worldId,
    required this.sectionTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldProvider).worlds[worldId];
    final worldName = world?.name ?? 'World';

    return Row(
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () => context.push(exploreWorldPath(worldId)),
            child: Text(
              worldName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: VFontSize.bodyMd,
                fontWeight: VFontWeight.medium,
                color: VCommuneColors.textLink,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: VSpacing.xs),
          child: Icon(
            Icons.chevron_right,
            size: VIconSize.sm,
            color: VCommuneColors.textMuted,
          ),
        ),
        Flexible(
          child: Text(
            sectionTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: VFontSize.bodyMd,
              fontWeight: VFontWeight.semiBold,
              color: VCommuneColors.headerPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
