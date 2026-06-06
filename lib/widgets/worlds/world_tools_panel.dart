import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/world_page_ia.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import '../v_section_list.dart';
import 'world_treasury_glance.dart';

/// Short world overflow menu — full features live in [WorldManageScreen].
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
          WorldTreasuryGlance(
            worldId: worldId,
            world: world,
            isAdminOrCouncil: isAdminOrCouncil,
          ),
          VSectionList(
            title: 'Participate',
            children: [
              VSectionTile(
                icon: Icons.hub_outlined,
                label: 'Manage & participate',
                detail: 'Lounge, economy, polls, roles',
                onTap: () {
                  onDismiss();
                  context.push(worldManagePath(worldId));
                },
              ),
              if (world.isMarketplace)
                VSectionTile(
                  icon: Icons.storefront_outlined,
                  label: 'Shop',
                  detail: 'Marketplace listings',
                  onTap: () {
                    onDismiss();
                    context.push(
                      worldMarketplacePath(worldId, member: isJoined),
                    );
                  },
                ),
              VSectionTile(
                icon: Icons.work_outline,
                label: 'Jobs',
                detail: 'World gigs and bounties',
                onTap: () {
                  onDismiss();
                  context.push(worldJobsPath(worldId, admin: isAdminOrCouncil));
                },
              ),
            ],
          ),
          VSectionList(
            title: 'World features',
            children: [
              VSectionTile(
                icon: Icons.account_balance_outlined,
                label: 'Treasury',
                detail: 'World economy glance',
                onTap: () {
                  onDismiss();
                  context.push(
                    worldTreasuryPath(worldId, admin: isAdminOrCouncil),
                  );
                },
              ),
              if (world.dominionType == DominionType.academy)
                VSectionTile(
                  icon: Icons.school_outlined,
                  label: 'Academy',
                  detail: 'Courses and learning',
                  onTap: () {
                    onDismiss();
                    context.push(
                      '/explore/${Uri.encodeComponent(worldId)}/academy',
                    );
                  },
                ),
              if (WorldPageIa.hasFeedTab(world))
                VSectionTile(
                  icon: Icons.dynamic_feed_outlined,
                  label: 'World feed',
                  onTap: () {
                    onDismiss();
                    context.push(exploreWorldPath(worldId));
                  },
                ),
            ],
          ),
          if (isAdminOrCouncil)
            VSectionList(
              title: 'Moderation',
              children: [
                VSectionTile(
                  icon: Icons.gavel_outlined,
                  label: 'Governance',
                  detail: 'Votes, constitution, moderation',
                  onTap: () {
                    onDismiss();
                    context.push(
                      worldGovernancePath(worldId, worldName: world.name),
                    );
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
