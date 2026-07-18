import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/world_page_ia.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../services/feature_flags.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import '../v_section_list.dart';
import 'world_treasury_glance.dart';

/// World overflow menu — members see belonging tools; council sees admin.
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
    final showMarket = FeatureFlags.marketplace && world.isMarketplace;
    final showTreasury = FeatureFlags.treasury;
    final showJobs = FeatureFlags.worldJobs;
    final showAcademy =
        FeatureFlags.worldAcademy &&
        world.dominionType == DominionType.academy;
    final showPolls = FeatureFlags.polls;

    return SingleChildScrollView(
      child: Column(
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
                  isAdminOrCouncil ? 'World tools' : 'In this world',
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
              'Join this world to open lounge, chat, and member tools.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: VColors.onSurfaceVariantDark,
              ),
            ),
          )
        else if (isAdminOrCouncil) ...[
          if (showTreasury)
            WorldTreasuryGlance(
              worldId: worldId,
              world: world,
              isAdminOrCouncil: true,
            ),
          VSectionList(
            title: 'Lead',
            children: [
              VSectionTile(
                icon: Icons.hub_outlined,
                label: 'Manage hub',
                detail: 'Lounge, polls, economy, roles',
                onTap: () {
                  onDismiss();
                  context.push(worldManagePath(worldId));
                },
              ),
              if (showMarket)
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
              if (showJobs)
                VSectionTile(
                  icon: Icons.work_outline,
                  label: 'Jobs',
                  detail: 'World gigs and bounties',
                  onTap: () {
                    onDismiss();
                    context.push(worldJobsPath(worldId, admin: true));
                  },
                ),
              if (showTreasury)
                VSectionTile(
                  icon: Icons.account_balance_outlined,
                  label: 'Treasury',
                  onTap: () {
                    onDismiss();
                    context.push(worldTreasuryPath(worldId, admin: true));
                  },
                ),
              if (showAcademy)
                VSectionTile(
                  icon: Icons.school_outlined,
                  label: 'Academy',
                  onTap: () {
                    onDismiss();
                    context.push(
                      '/explore/${Uri.encodeComponent(worldId)}/academy',
                    );
                  },
                ),
            ],
          ),
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
        ] else ...[
          // Members: belonging only — no admin toolbox.
          VSectionList(
            title: 'Participate',
            children: [
              VSectionTile(
                icon: Icons.forum_outlined,
                label: FeatureFlags.campfireEnabled
                    ? 'Lounge & Campfire'
                    : 'Lounge',
                detail: FeatureFlags.campfireEnabled
                    ? 'Voice and member spaces'
                    : 'Member lounge',
                onTap: () {
                  onDismiss();
                  context.push(worldManagePath(worldId));
                },
              ),
              if (showPolls)
                VSectionTile(
                  icon: Icons.how_to_vote_outlined,
                  label: 'Polls',
                  onTap: () {
                    onDismiss();
                    context.push(worldPollsPath(worldId));
                  },
                ),
              if (showMarket)
                VSectionTile(
                  icon: Icons.storefront_outlined,
                  label: 'Shop',
                  onTap: () {
                    onDismiss();
                    context.push(
                      worldMarketplacePath(worldId, member: true),
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
        ],
        VSectionList(
          title: 'More',
          children: [
            VSectionTile(
              icon: Icons.menu_book,
              label: 'Realm guide',
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
          ],
        ),
        const SizedBox(height: VSpacing.md),
        ],
      ),
    );
  }
}
