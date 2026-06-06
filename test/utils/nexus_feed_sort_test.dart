import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/post.dart';
import 'package:vertiege/utils/nexus_feed_sort.dart';
import 'package:vertiege/widgets/nexus/feed_sort_dropdown.dart';

void main() {
  test('pinned posts sort above regular posts', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    final posts = <Post>[
      Post(
        id: 'a',
        worldId: 'w1',
        residentId: 'r1',
        residentName: 'A',
        residentAvatar: '',
        content: 'regular',
        timestamp: now,
      ),
      Post(
        id: 'b',
        worldId: 'w1',
        residentId: 'r1',
        residentName: 'B',
        residentAvatar: '',
        content: 'pinned',
        timestamp: now - 1000,
        isPinned: true,
      ),
    ];

    final sorted = sortNexusFeedPosts(posts, FeedSort.latest);
    expect(sorted.first.id, 'b');
  });

  test('latest sort prefers newer timestamps', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    final posts = <Post>[
      Post(
        id: 'old',
        worldId: 'w1',
        residentId: 'r1',
        residentName: 'A',
        residentAvatar: '',
        content: 'old',
        timestamp: now - 5000,
      ),
      Post(
        id: 'new',
        worldId: 'w1',
        residentId: 'r1',
        residentName: 'B',
        residentAvatar: '',
        content: 'new',
        timestamp: now,
      ),
    ];

    final sorted = sortNexusFeedPosts(posts, FeedSort.latest);
    expect(sorted.first.id, 'new');
  });
}
