import '../models/resident.dart';
import 'feature_flags.dart';
import 'permission_service.dart';

/// Post types the unified composer may expose (UI + future server RPC).
enum PostCapability {
  text,
  media,
  poll,
  scheduled,
  announcement,
  decree,
  pinned,
}

class PostCapabilityResult {
  final bool allowed;
  final String? reason;

  const PostCapabilityResult.allowed() : allowed = true, reason = null;

  const PostCapabilityResult.denied(this.reason) : allowed = false;
}

/// Shared capability checks for [PostInput] and future compose surfaces.
class PostCapabilities {
  static bool canAnnounce(
    Resident resident,
    String worldId,
    String? sovereignId,
  ) =>
      WorldPermissions.canAnnounce(resident, worldId, sovereignId);

  static bool canDecree(
    Resident resident,
    String worldId,
    String? sovereignId,
  ) =>
      WorldPermissions.canAnnounce(resident, worldId, sovereignId);

  static PostCapabilityResult check({
    required PostCapability capability,
    required Resident? resident,
    required String worldId,
    String? sovereignId,
  }) {
    if (resident == null) {
      return const PostCapabilityResult.denied('Sign in to post.');
    }
    switch (capability) {
      case PostCapability.text:
      case PostCapability.media:
        return const PostCapabilityResult.allowed();
      case PostCapability.announcement:
        return canAnnounce(resident, worldId, sovereignId)
            ? const PostCapabilityResult.allowed()
            : const PostCapabilityResult.denied(
                'Announcements require council or sovereign standing.',
              );
      case PostCapability.decree:
        return canDecree(resident, worldId, sovereignId)
            ? const PostCapabilityResult.allowed()
            : const PostCapabilityResult.denied(
                'Decrees require council or sovereign standing.',
              );
      case PostCapability.pinned:
        return canDecree(resident, worldId, sovereignId)
            ? const PostCapabilityResult.allowed()
            : const PostCapabilityResult.denied(
                'Pinning requires council or sovereign standing.',
              );
      case PostCapability.poll:
        if (!FeatureFlags.polls) {
          return const PostCapabilityResult.denied(
            'Polls are not enabled for this world yet.',
          );
        }
        return const PostCapabilityResult.allowed();
      case PostCapability.scheduled:
        return const PostCapabilityResult.denied(
          'Scheduled posts are not available yet.',
        );
    }
  }
}
