import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/state/post/post_mapper.dart';

void main() {
  group('postFromJson', () {
    test('maps snake_case feed row', () {
      final post = postFromJson({
        'id': 'p1',
        'world_id': 'w1',
        'resident_id': 'r1',
        'resident_name': 'Ada',
        'content': 'Hello Nexus',
        'created_at': '2026-07-18T00:00:00.000Z',
        'tier_at_posting': 2,
        'reactions': {'upvote': 3},
        'status': 'published',
      });

      expect(post.id, 'p1');
      expect(post.worldId, 'w1');
      expect(post.residentId, 'r1');
      expect(post.residentName, 'Ada');
      expect(post.content, 'Hello Nexus');
      expect(post.reactions['upvote'], 3);
      expect(post.status, 'published');
      expect(post.timestamp, greaterThan(0));
    });

    test('maps poll payload', () {
      final post = postFromJson({
        'id': 'p2',
        'world_id': 'w1',
        'resident_id': 'r1',
        'resident_name': 'Ada',
        'content': 'Vote',
        'created_at': 0,
        'poll': {
          'question': 'Tea or coffee?',
          'options': [
            {'id': 'a', 'text': 'Tea', 'voteCount': 1},
            {'id': 'b', 'text': 'Coffee', 'voteCount': 0},
          ],
          'isMultiChoice': false,
          'votedResidentIds': ['r1'],
        },
      });

      expect(post.poll, isNotNull);
      expect(post.poll!.question, 'Tea or coffee?');
      expect(post.poll!.options, hasLength(2));
      expect(post.poll!.votedResidentIds, ['r1']);
    });
  });
}
