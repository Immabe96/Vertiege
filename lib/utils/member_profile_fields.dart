import '../config/identity_verification.dart';
import '../widgets/core/status_dot.dart';
import 'presence_utils.dart';

/// Flatten world_members + embedded profiles row for UI.
Map<String, dynamic> flattenWorldMemberRow(Map<String, dynamic> row) {
  final profile = row['profiles'];
  if (profile is! Map<String, dynamic>) return row;
  return {
    ...row,
    'avatar_url': profile['avatar_url'] ?? row['avatar_url'],
    'tier': profile['tier'] ?? row['tier'],
    'total_xp': profile['total_xp'] ?? row['total_xp'],
    'last_seen_at': profile['last_seen_at'] ?? row['last_seen_at'],
    'verified_roles': profile['verified_roles'] ?? row['verified_roles'],
    'presence_mode': profile['presence_mode'] ?? row['presence_mode'],
    'custom_status': profile['custom_status'] ?? row['custom_status'],
    'avatar_frame_id': profile['avatar_frame_id'] ?? row['avatar_frame_id'],
  };
}

bool memberHasIdentityTick(Map<String, dynamic> member) {
  final roles = member['verified_roles'];
  if (roles is List) {
    for (final role in roles) {
      if (IdentityVerification.isIdentityProfession(role?.toString())) {
        return true;
      }
    }
  }
  return false;
}

Presence memberPresence(Map<String, dynamic> member) {
  return presenceFromStatusFields(
    presenceMode: member['presence_mode'] as String?,
    lastSeenRaw: member['last_seen_at'],
  );
}

int memberTotalXp(Map<String, dynamic> member) {
  final totalXp = (member['total_xp'] as num?)?.toInt();
  if (totalXp != null && totalXp > 0) return totalXp;
  final tier = (member['tier'] as num?)?.toInt() ?? 1;
  return switch (tier) {
    5 => 50000,
    4 => 10000,
    3 => 2000,
    2 => 500,
    _ => 0,
  };
}
