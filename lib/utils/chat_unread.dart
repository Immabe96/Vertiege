import '../models/message.dart';

const unreadUnknownCount = 1;

DateTime? latestMessageTime(List<ChannelMessage> messages) {
  DateTime? latest;
  for (final message in messages) {
    if (message.createdAt <= 0) continue;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(message.createdAt);
    if (latest == null || createdAt.isAfter(latest)) {
      latest = createdAt;
    }
  }
  return latest;
}

int countUnreadMessages({
  required List<ChannelMessage> loadedMessages,
  required DateTime? lastReadAt,
  required DateTime? latestMessageAt,
}) {
  if (loadedMessages.isNotEmpty) {
    if (lastReadAt == null) return loadedMessages.length;
    return loadedMessages.where((message) {
      if (message.createdAt <= 0) return false;
      return DateTime.fromMillisecondsSinceEpoch(
        message.createdAt,
      ).isAfter(lastReadAt);
    }).length;
  }

  if (latestMessageAt == null) return 0;
  if (lastReadAt == null || latestMessageAt.isAfter(lastReadAt)) {
    return unreadUnknownCount;
  }
  return 0;
}

bool hasUnreadMessages({
  required List<ChannelMessage> loadedMessages,
  required DateTime? lastReadAt,
  required DateTime? latestMessageAt,
}) {
  return countUnreadMessages(
        loadedMessages: loadedMessages,
        lastReadAt: lastReadAt,
        latestMessageAt: latestMessageAt,
      ) >
      0;
}
