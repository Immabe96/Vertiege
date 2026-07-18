import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/post.dart';
import 'package:vertiege/models/resident.dart';
import 'package:vertiege/state/post/post_reaction_logic.dart';

Post _post({Map<String, int> reactions = const {}}) => Post(
      id: 'p1',
      worldId: 'w1',
      residentId: 'r1',
      residentName: 'Ada',
      residentAvatar: '',
      content: 'hi',
      timestamp: 1,
      tierAtPosting: ResidentTier.hustlers,
      reactions: reactions,
    );

void main() {
  group('applyPostReactionDelta', () {
    test('increments and removes at zero', () {
      final posts = [_post(reactions: {'upvote': 1})];
      final up = applyPostReactionDelta(posts, 'p1', 'upvote', 1);
      expect(up.single.reactions['upvote'], 2);

      final down = applyPostReactionDelta(up, 'p1', 'upvote', -2);
      expect(down.single.reactions.containsKey('upvote'), isFalse);
    });
  });

  group('exclusiveVoteKeysToClear', () {
    test('clears opposing vote keys when activating a vote', () {
      expect(
        exclusiveVoteKeysToClear({'downvote', 'fire'}, 'upvote').toSet(),
        {'downvote'},
      );
    });

    test('clears all vote keys when activating a non-vote reaction', () {
      // Matches prior provider behavior: any new reaction clears upvote/downvote.
      expect(
        exclusiveVoteKeysToClear({'upvote', 'downvote'}, 'fire').toSet(),
        {'upvote', 'downvote'},
      );
    });
  });
}
