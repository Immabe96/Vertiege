import '../models/channel.dart';

/// Returns a new list of [WorldChannel]s with unread channels floated to the
/// top, then sorted by their original `position` (stable order preserved by
/// the secondary key). The input list is not mutated.
///
/// [unreadByChannelId] is a lookup of channel id → unread message count. Any
/// value > 0 treats the channel as having unread activity. Channels missing
/// from the map are treated as fully read.
List<WorldChannel> sortChatChannelsWithUnreadFirst({
  required List<WorldChannel> channels,
  required Map<String, int> unreadByChannelId,
}) {
  final copy = List<WorldChannel>.from(channels);
  copy.sort((a, b) {
    final aUnread = (unreadByChannelId[a.id] ?? 0) > 0;
    final bUnread = (unreadByChannelId[b.id] ?? 0) > 0;
    if (aUnread != bUnread) return aUnread ? -1 : 1;
    return a.position.compareTo(b.position);
  });
  return copy;
}
