import '../widgets/core/status_dot.dart';
import '../widgets/worlds/world_member_row.dart';
import 'presence_utils.dart';

int countOnlineWorldMembers(List<WorldMemberEntry> members) {
  return members
      .where(
        (entry) =>
            presenceFromLastSeenMs(entry.resident.lastSeenAt) ==
            Presence.online,
      )
      .length;
}
