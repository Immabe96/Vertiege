import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/world_provider.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';
import 'leaderboard.dart';
import 'world_events_card.dart';
import 'world_member_row.dart';
import 'world_residents.dart';

class WorldDetailMembers extends ConsumerWidget {
  final String worldId;
  final dynamic world;
  final List<WorldMemberEntry> members;
  final bool membersLoading;

  const WorldDetailMembers({
    super.key,
    required this.worldId,
    required this.world,
    required this.members,
    required this.membersLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Member avatars wrapped in GlassPanel
        VSurfacePanel(
          padding: const EdgeInsets.all(Spacing.md),
          child: WorldMemberRow(
            members: members,
            isLoading: membersLoading,
            onlineCount: math.min(8, (members.length * 0.4).round()),
            onTap: () => context.push(
              '/explore/$worldId/members'
              '?name=${Uri.encodeComponent(world.name)}'
              '&sovereign=${Uri.encodeComponent(world.sovereignId)}',
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        if (ref.read(worldProvider.notifier).featuresForWorld(worldId).events)
          WorldEventsCard(worldId: worldId, sovereignId: world.sovereignId),
        WorldLeaderboard(worldId: worldId),
        const SizedBox(height: Spacing.md),
        WorldResidents(world: world),
        const SizedBox(height: Spacing.xxl),
      ],
    );
  }
}
