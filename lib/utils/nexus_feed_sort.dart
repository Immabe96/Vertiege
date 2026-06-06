import 'dart:math' as math;

import '../models/post.dart';
import '../widgets/nexus/feed_sort_dropdown.dart';
import 'verified_moment.dart';

/// Shared Nexus feed ordering (decree → pinned → announcements → sorted body).
List<Post> sortNexusFeedPosts(List<Post> source, FeedSort sort) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final decreeExpiry = const Duration(hours: 24).inMilliseconds;

  final posts = List<Post>.from(source);

  int priority(Post p) {
    if (p.isDecree && (now - p.timestamp) < decreeExpiry) return 0;
    if (p.isPinned && !p.isDecree) return 1;
    if (p.isAnnouncement && !p.isPinned && !p.isDecree) return 2;
    return 3;
  }

  int compareByReactions(Post a, Post b) {
    final aTotal = a.reactions.values.fold<int>(0, (s, c) => s + c);
    final bTotal = b.reactions.values.fold<int>(0, (s, c) => s + c);
    return bTotal.compareTo(aTotal);
  }

  double hotScore(Post post) {
    final totalReactions =
        post.reactions.values.fold<int>(0, (s, c) => s + c) + post.comments.length;
    final ageMs = now - post.timestamp;
    final ageHours = ageMs / (1000 * 60 * 60);
    return totalReactions / math.pow(ageHours + 2, 1.5);
  }

  int compareByHot(Post a, Post b) => hotScore(b).compareTo(hotScore(a));

  int compareByLatest(Post a, Post b) {
    final byTime = b.timestamp.compareTo(a.timestamp);
    if (byTime != 0) return byTime;
    final aMoment = isVerifiedMomentPost(a) ? 1 : 0;
    final bMoment = isVerifiedMomentPost(b) ? 1 : 0;
    return bMoment.compareTo(aMoment);
  }

  posts.sort((a, b) {
    final pa = priority(a);
    final pb = priority(b);
    if (pa != pb) return pa.compareTo(pb);
    if (pa == 3) {
      return switch (sort) {
        FeedSort.latest => compareByLatest(a, b),
        FeedSort.top => compareByReactions(a, b),
        FeedSort.hot => compareByHot(a, b),
      };
    }
    return b.timestamp.compareTo(a.timestamp);
  });

  return posts;
}
