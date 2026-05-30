import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/world_capability_matrix.dart';
import '../models/channel.dart';
import '../forui/v_hub_page.dart';
import '../models/world.dart';
import '../router/world_navigation.dart';
import '../services/feature_flags.dart';
import '../services/world_channel_access_service.dart';
import '../state/channel_provider.dart';
import '../state/resident_provider.dart';
import '../state/world_provider.dart';
import '../theme/v_tokens.dart';
import '../widgets/v_section_list.dart';
import '../services/permission_service.dart';

/// Manage / Participate hub (Wave 10) with visible gate reasons.
class WorldManageScreen extends ConsumerWidget {
  final String worldId;

  const WorldManageScreen({super.key, required this.worldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldProvider).worlds[worldId];
    final resident = ref.watch(residentProvider).resident;
    if (world == null) {
      return const VHubPage(
        title: 'World',
        showBack: true,
        body: Center(child: Text('World not found')),
      );
    }

    final features = ref.read(worldProvider.notifier).featuresForWorld(worldId);
    final channels = ref.watch(channelProvider).channelsByWorld[worldId] ?? [];
    final isJoined = resident?.joinedWorldIds.contains(worldId) ?? false;
    final isCouncil = resident != null &&
        WorldPermissions.canManageSettings(
          resident,
          worldId,
          world.sovereignId,
        );

    WorldChannel? lounge;
    WorldChannel? campfire;
    for (final ch in channels) {
      if (WorldChannelAccessService.isLoungeChannel(ch)) lounge = ch;
      if (WorldChannelAccessService.isCampfireChannel(ch)) campfire = ch;
    }

    String? loungeGate;
    String? campfireGate;
    if (lounge != null && resident != null) {
      loungeGate = WorldChannelAccessService.decision(
        world: world,
        channel: lounge,
        features: features,
        resident: resident,
      ).reason;
    }
    if (campfire != null && resident != null) {
      campfireGate = WorldChannelAccessService.decision(
        world: world,
        channel: campfire,
        features: features,
        resident: resident,
      ).reason;
    }

    final marketplaceGate = WorldCapabilityMatrix.blockReasonCreateListing(
      resident,
      world,
      isJoined: isJoined,
    );
    final treasuryGate = WorldCapabilityMatrix.blockReasonTreasuryDonate(
      resident,
      world,
      isJoined: isJoined,
    );

    return VHubPage(
      title: 'Manage & participate',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.md),
        children: [
          if (!isJoined)
            const Padding(
              padding: EdgeInsets.only(bottom: VSpacing.md),
              child: Text('Join this world to use economy and community tools.'),
            ),
          VSectionList(
            title: 'Social',
            children: [
              _gateTile(
                icon: Icons.weekend_outlined,
                label: 'Lounge',
                gate: loungeGate,
                enabled: isJoined && loungeGate == null && lounge != null,
                onTap: lounge == null
                    ? null
                    : () => context.push(
                          worldChannelDestinationPath(
                            worldId,
                            lounge!,
                            worldName: world.name,
                          ),
                        ),
              ),
              _gateTile(
                icon: Icons.local_fire_department,
                label: 'Campfire',
                gate: campfireGate ??
                    (features.audioRooms
                        ? null
                        : 'Unlocks at prestige ${WorldChannelAccessService.campfirePrestige}.'),
                enabled: isJoined && campfireGate == null && campfire != null,
                onTap: campfire == null
                    ? null
                    : () => context.push(
                          worldChannelDestinationPath(
                            worldId,
                            campfire!,
                            worldName: world.name,
                          ),
                        ),
              ),
              if (FeatureFlags.polls)
                VSectionTile(
                  icon: Icons.how_to_vote,
                  label: 'Polls',
                  onTap: isJoined
                      ? () => context.push(
                            worldPollsPath(worldId, admin: isCouncil),
                          )
                      : null,
                  enabled: isJoined,
                ),
              VSectionTile(
                icon: Icons.work_outline,
                label: 'Role board',
                onTap: isJoined
                    ? () => context.push(
                          worldJobsPath(worldId, admin: isCouncil),
                        )
                    : null,
                enabled: isJoined,
              ),
              VSectionTile(
                icon: Icons.menu_book_outlined,
                label: 'Archive',
                onTap: isJoined ? () => context.push(worldArchivePath(worldId)) : null,
                enabled: isJoined,
              ),
            ],
          ),
          VSectionList(
            title: 'Economy',
            children: [
              _gateTile(
                icon: Icons.account_balance_wallet,
                label: 'Treasury',
                gate: treasuryGate,
                enabled: isJoined && treasuryGate == null,
                onTap: () => context.push(
                  worldTreasuryPath(worldId, admin: isCouncil),
                ),
              ),
              _gateTile(
                icon: Icons.storefront,
                label: 'Marketplace',
                gate: marketplaceGate ??
                    (!WorldCapabilityMatrix.worldHasMarketplace(world)
                        ? 'Unlocks at prestige ${WorldCapabilityMatrix.minWorldPrestigeMarketplace}.'
                        : null),
                enabled: isJoined &&
                    WorldCapabilityMatrix.worldHasMarketplace(world),
                onTap: () => context.push(
                  worldMarketplacePath(worldId, member: isJoined),
                ),
              ),
            ],
          ),
          if (isCouncil) ...[
            VSectionList(
              title: 'Governance',
              children: [
                VSectionTile(
                  icon: Icons.gavel,
                  label: 'Approval queue',
                  onTap: () => context.push(worldGovernancePath(worldId)),
                ),
                VSectionTile(
                  icon: Icons.history,
                  label: 'Audit log',
                  onTap: () => context.push(
                    auditLogPath(worldId, worldName: world.name),
                  ),
                ),
                VSectionTile(
                  icon: Icons.settings,
                  label: 'World settings',
                  onTap: () => context.push(worldSettingsPath(worldId)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _gateTile({
    required IconData icon,
    required String label,
    required String? gate,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VSectionTile(
          icon: icon,
          label: label,
          enabled: enabled,
          onTap: onTap,
        ),
        if (gate != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.lg,
              0,
              VSpacing.lg,
              VSpacing.sm,
            ),
            child: Text(
              gate,
              style: const TextStyle(fontSize: VFontSize.labelSm),
            ),
          ),
      ],
    );
  }
}
