import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/world_capability_matrix.dart';
import '../models/channel.dart';
import 'package:vertiege/ui/ui.dart';
import '../router/world_navigation.dart';
import '../services/feature_flags.dart';
import '../services/world_channel_access_service.dart';
import '../state/channel_provider.dart';
import '../state/resident_provider.dart';
import '../state/world_provider.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/quiet_gate_tile.dart';
import '../services/permission_service.dart';

/// Manage / Participate hub (Wave 10) with visible gate reasons.
class WorldManageScreen extends ConsumerStatefulWidget {
  final String worldId;

  const WorldManageScreen({super.key, required this.worldId});

  @override
  ConsumerState<WorldManageScreen> createState() => _WorldManageScreenState();
}

class _WorldManageScreenState extends ConsumerState<WorldManageScreen> {
  final _scrollController = ScrollController();
  final _socialKey = GlobalKey();
  final _economyKey = GlobalKey();
  final _governanceKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _jumpTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final worldId = widget.worldId;
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
    final isCouncil =
        resident != null &&
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

    final String? marketplaceGate;
    if (!isJoined) {
      marketplaceGate = 'Join this world to open the marketplace.';
    } else if (!WorldCapabilityMatrix.worldHasMarketplace(world)) {
      marketplaceGate =
          'Marketplace unlocks at world prestige '
          '${WorldCapabilityMatrix.minWorldPrestigeMarketplace}.';
    } else {
      marketplaceGate = null;
    }
    final treasuryGate = WorldCapabilityMatrix.blockReasonTreasuryDonate(
      resident,
      world,
      isJoined: isJoined,
    );

    return VHubPage(
      title: 'Manage & participate',
      showBack: true,
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(VSpacing.md),
        children: [
          if (!isJoined)
            const Padding(
              padding: EdgeInsets.only(bottom: VSpacing.md),
              child: AppEmptyState(
                title: 'Join to participate',
                description:
                    'Economy, Lounge, Campfire, and polls unlock after you join this world.',
                icon: Icons.group_add_outlined,
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Social'),
                  onPressed: () => _jumpTo(_socialKey),
                ),
                const SizedBox(width: VSpacing.xs),
                ActionChip(
                  label: const Text('Economy'),
                  onPressed: () => _jumpTo(_economyKey),
                ),
                if (isCouncil) ...[
                  const SizedBox(width: VSpacing.xs),
                  ActionChip(
                    label: const Text('Governance'),
                    onPressed: () => _jumpTo(_governanceKey),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: VSpacing.md),
          KeyedSubtree(
            key: _socialKey,
            child: VSectionList(
              title: 'Social',
              children: [
                QuietGateTile.section(
                  icon: Icons.forum_outlined,
                  label: 'Lounge & Campfire',
                  gate: (lounge == null && campfire == null)
                      ? 'No social channels in this world yet.'
                      : (loungeGate != null && campfireGate != null)
                      ? loungeGate ?? campfireGate
                      : null,
                  onOpen: (lounge != null || campfire != null)
                      ? () => _openLoungeCampfirePicker(
                          context,
                          worldId: worldId,
                          worldName: world.name,
                          lounge: lounge,
                          campfire: campfire,
                          loungeGate: loungeGate,
                          campfireGate:
                              campfireGate ??
                              (features.audioRooms
                                  ? null
                                  : 'Unlocks at prestige ${WorldChannelAccessService.campfirePrestige}.'),
                        )
                      : null,
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
                  onTap: isJoined
                      ? () => context.push(worldArchivePath(worldId))
                      : null,
                  enabled: isJoined,
                ),
              ],
            ),
          ),
          KeyedSubtree(
            key: _economyKey,
            child: VSectionList(
              title: 'Economy',
              children: [
                QuietGateTile.section(
                  icon: Icons.account_balance_wallet,
                  label: 'Treasury',
                  gate: treasuryGate,
                  onOpen: treasuryGate == null
                      ? () => context.push(
                          worldTreasuryPath(worldId, admin: isCouncil),
                        )
                      : null,
                ),
                QuietGateTile.section(
                  icon: Icons.storefront,
                  label: 'Marketplace',
                  gate: marketplaceGate,
                  onOpen: marketplaceGate == null
                      ? () => context.push(
                          worldMarketplacePath(worldId, member: isJoined),
                        )
                      : null,
                ),
              ],
            ),
          ),
          if (isCouncil)
            KeyedSubtree(
              key: _governanceKey,
              child: VSectionList(
                title: 'Governance',
                children: [
                  VSectionTile(
                    icon: Icons.gavel,
                    label: 'Approval queue',
                    onTap: () => context.push(
                      worldGovernancePath(worldId, worldName: world.name),
                    ),
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
            ),
        ],
      ),
    );
  }
}

void _openLoungeCampfirePicker(
  BuildContext context, {
  required String worldId,
  required String worldName,
  required WorldChannel? lounge,
  required WorldChannel? campfire,
  required String? loungeGate,
  required String? campfireGate,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lounge != null)
            ListTile(
              leading: const Icon(Icons.weekend_outlined),
              title: const Text('Lounge (text)'),
              subtitle: loungeGate != null
                  ? Text(loungeGate)
                  : const Text('Async chat channel'),
              enabled: loungeGate == null,
              onTap: loungeGate == null
                  ? () {
                      Navigator.pop(ctx);
                      context.push(
                        worldChannelDestinationPath(
                          worldId,
                          lounge,
                          worldName: worldName,
                        ),
                      );
                    }
                  : null,
            ),
          if (campfire != null)
            ListTile(
              leading: const Icon(Icons.local_fire_department),
              title: const Text('Campfire (voice)'),
              subtitle: Text(campfireGate ?? 'Live voice room for this world'),
              enabled: campfireGate == null,
              onTap: campfireGate == null
                  ? () {
                      Navigator.pop(ctx);
                      context.push(
                        worldChannelDestinationPath(
                          worldId,
                          campfire,
                          worldName: worldName,
                        ),
                      );
                    }
                  : null,
            ),
          const SizedBox(height: VSpacing.md),
        ],
      ),
    ),
  );
}
