import '../../models/post.dart';

const postVoteKeys = {'upvote', 'downvote'};

/// Applies a reaction count delta to one post in [posts] (pure — no state mutation).
List<Post> applyPostReactionDelta(
  List<Post> posts,
  String postId,
  String reactionKey,
  int delta,
) {
  return posts.map((p) {
    if (p.id != postId) return p;
    final reactions = Map<String, int>.from(p.reactions);
    final next = (reactions[reactionKey] ?? 0) + delta;
    if (next <= 0) {
      reactions.remove(reactionKey);
    } else {
      reactions[reactionKey] = next;
    }
    return p.copyWith(reactions: reactions);
  }).toList();
}

/// Vote keys that must be cleared when activating [reactionKey] (upvote/downvote exclusivity).
Iterable<String> exclusiveVoteKeysToClear(
  Set<String> activeReactions,
  String reactionKey,
) sync* {
  for (final other in postVoteKeys) {
    if (other != reactionKey && activeReactions.contains(other)) {
      yield other;
    }
  }
}
