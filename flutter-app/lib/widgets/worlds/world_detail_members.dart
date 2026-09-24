import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import '../../state/world_provider.dart';
import '../../utils/world_presence.dart';
import '../../theme/v_tokens.dart';
import '../../ui/cards/v_card.dart';
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Member avatars wrapped in VCard
        VCard(
          child: WorldMemberRow(
            members: members,
            isLoading: membersLoading,
            onlineCount: countOnlineWorldMembers(members),
            onTap: () => context.push(
              worldMembersPath(
                worldId,
                worldName: world.name,
                sovereignId: world.sovereignId,
              ),
            ),
          ),
        ),
        const SizedBox(height: VSpacing.sm),
        if (ref.read(worldProvider.notifier).featuresForWorld(worldId).events)
          WorldEventsCard(worldId: worldId, sovereignId: world.sovereignId),
        WorldLeaderboard(worldId: worldId),
        const SizedBox(height: VSpacing.md),
        WorldResidents(
          world: world,
          members: members,
          isLoading: membersLoading,
        ),
        const SizedBox(height: VSpacing.xxl),
      ],
    );
  }
}
