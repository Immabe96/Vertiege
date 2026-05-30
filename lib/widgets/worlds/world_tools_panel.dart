import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/world_capability_matrix.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../services/feature_flags.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import '../v_section_list.dart';

/// World tools menu — used in end drawer or Forui bottom sheet.
class WorldToolsPanel extends ConsumerWidget {
  final World world;
  final String worldId;
  final bool isJoined;
  final bool isAdminOrCouncil;
  final VoidCallback onDismiss;
  final VoidCallback onShare;
  final VoidCallback? onSettings;
  final VoidCallback onOpenRealmGuide;

  const WorldToolsPanel({
    super.key,
    required this.world,
    required this.worldId,
    required this.isJoined,
    required this.isAdminOrCouncil,
    required this.onDismiss,
    required this.onShare,
    this.onSettings,
    required this.onOpenRealmGuide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final showMarket = WorldCapabilityMatrix.worldHasMarketplace(world);
    final showTreasury = WorldCapabilityMatrix.worldHasTreasury(world);
    final canTreasuryAdmin = WorldCapabilityMatrix.canManageTreasury(
      resident,
      world,
    );
    final showShopInDrawer = !world.isMarketplace;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            VSpacing.md,
            VSpacing.xs,
            VSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'World tools',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(VIcons.x),
                tooltip: 'Close',
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
        if (!isJoined)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            child: Text(
              'Join this world to use tools and earn reputation here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          if (showShopInDrawer &&
              (FeatureFlags.marketplace && showMarket ||
                  FeatureFlags.treasury && showTreasury))
            VSectionList(
              title: 'Economy',
              children: [
                if (FeatureFlags.treasury && showTreasury)
                  VSectionTile(
                    icon: Icons.account_balance_wallet,
                    label: 'Treasury',
                    onTap: () {
                      onDismiss();
                      context.push(
                        worldTreasuryPath(
                          worldId,
                          admin: canTreasuryAdmin,
                        ),
                      );
                    },
                  ),
                if (FeatureFlags.marketplace && showMarket)
                  VSectionTile(
                    icon: Icons.storefront,
                    label: 'Marketplace',
                    onTap: () {
                      onDismiss();
                      context.push(
                        worldMarketplacePath(worldId, member: isJoined),
                      );
                    },
                  ),
              ],
            ),
          VSectionList(
            title: 'Community',
            children: [
              if (FeatureFlags.polls)
                VSectionTile(
                  icon: Icons.how_to_vote,
                  label: 'Polls',
                  onTap: () {
                    onDismiss();
                    context.push(
                      worldPollsPath(
                        worldId,
                        admin: isAdminOrCouncil,
                      ),
                    );
                  },
                ),
              VSectionTile(
                icon: Icons.work_outline,
                label: 'Role board',
                onTap: () {
                  onDismiss();
                  context.push(
                    worldJobsPath(worldId, admin: isAdminOrCouncil),
                  );
                },
              ),
              VSectionTile(
                icon: Icons.menu_book_outlined,
                label: 'World archive',
                onTap: () {
                  onDismiss();
                  context.push(worldArchivePath(worldId));
                },
              ),
            ],
          ),
        ],
        VSectionList(
          title: 'More',
          children: [
            VSectionTile(
              icon: Icons.menu_book,
              label: 'Realm guide & growth',
              onTap: () {
                onDismiss();
                onOpenRealmGuide();
              },
            ),
            VSectionTile(
              icon: Icons.share_outlined,
              label: 'Share world',
              onTap: () {
                onDismiss();
                onShare();
              },
            ),
            if (onSettings != null)
              VSectionTile(
                icon: Icons.settings,
                label: 'World settings',
                onTap: () {
                  onDismiss();
                  onSettings!();
                },
              ),
          ],
        ),
        const SizedBox(height: VSpacing.md),
      ],
    );
  }
}
