import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../../config/progression_glossary.dart';
import '../../config/world_capability_matrix.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../services/feature_flags.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/empty_state.dart';
import '../v_section_list.dart';

/// Marketplace dominion — economy entry (formerly part of Manage).
class WorldShopTab extends ConsumerWidget {
  final World world;
  final String worldId;
  final bool isJoined;

  const WorldShopTab({
    super.key,
    required this.world,
    required this.worldId,
    required this.isJoined,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final showMarket = WorldCapabilityMatrix.worldHasMarketplace(world);
    final showTreasury = WorldCapabilityMatrix.worldHasTreasury(world);
    final canList = WorldCapabilityMatrix.canCreateListing(
      resident,
      world,
      isJoined: isJoined,
    );
    final canTreasuryAdmin = WorldCapabilityMatrix.canManageTreasury(
      resident,
      world,
    );

    if (!isJoined) {
      return const AppEmptyState(
        title: 'Join to use the shop',
        description: 'Listings, treasury, and trades unlock after you join.',
        icon: Icons.storefront_outlined,
        variant: EmptyStateVariant.default_,
      );
    }

    final links = <VSectionTile>[
      if (FeatureFlags.marketplace && showMarket)
        VSectionTile(
          icon: Icons.storefront,
          label: 'Browse marketplace',
          onTap: () => context.push(
            worldMarketplacePath(worldId, member: isJoined),
          ),
        ),
      if (FeatureFlags.treasury && showTreasury)
        VSectionTile(
          icon: Icons.account_balance_wallet,
          label: canTreasuryAdmin ? 'World treasury (manage)' : 'World treasury',
          onTap: () => context.push(
            worldTreasuryPath(worldId, admin: canTreasuryAdmin),
          ),
        ),
    ];

    final prestigeColor = world.prestige >= 40
        ? VColors.tierApex
        : world.prestige >= 20
        ? VColors.primary
        : VColors.tierHustler;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: VSpacing.sm),
        Text(
          'Shop & economy',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          'Trade, list items, and fund the world treasury.',
          style: TextStyle(
            fontSize: VFontSize.bodySm,
            color: isDark
                ? VColors.onSurfaceVariantDark
                : VColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: VSpacing.md),
        if (links.isEmpty)
          const AppEmptyState(
            title: 'Economy unlocking',
            description:
                'This shop world needs more prestige before marketplace modules activate.',
            icon: Icons.hourglass_empty,
            variant: EmptyStateVariant.default_,
          )
        else
          VSectionList(title: 'Open', children: links),
        const SizedBox(height: VSpacing.md),
        VSurfaceCard(
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: prestigeColor),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: Text(
                    canList
                        ? '${ProgressionGlossary.worldPrestigeShort(world.prestige)} · you can create listings'
                        : (WorldCapabilityMatrix.blockReasonCreateListing(
                              resident,
                              world,
                              isJoined: isJoined,
                            ) ??
                            '${ProgressionGlossary.worldPrestigeShort(world.prestige)} · listing rules apply'),
                    style: TextStyle(
                      fontSize: VFontSize.bodySm,
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
        ),
        const SizedBox(height: VSpacing.xl),
      ],
    );
  }
}
