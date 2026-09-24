import '../models/post.dart';
import '../services/world_service.dart';

/// Tag appended to Nexus proof-moment posts on the standing feed.
const String verifiedMomentHashtag = '#VerifiedMoment';

const String _verifiedMomentPrefix = 'Just verified:';

/// True for posts shared from the verify → Nexus flow.
bool isVerifiedMomentPost(Post post) {
  if (post.worldId == 'nexus') return true;
  final content = post.content;
  return content.contains(verifiedMomentHashtag) ||
      content.startsWith(_verifiedMomentPrefix);
}

/// Default copy for a new verified-moment Nexus post.
String verifiedMomentDraft(String achievementTitle) =>
    'Just verified: $achievementTitle. Proud to add this to my honour wall.\n$verifiedMomentHashtag';

bool isNexusFeedWorld(String worldId) =>
    WorldService.localOnlyWorldIds.contains(worldId);
