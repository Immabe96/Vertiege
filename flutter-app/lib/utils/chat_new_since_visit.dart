import '../models/message.dart';
import '../widgets/chat/chat_message_grouper.dart';

/// Index in [buildChatDisplayItems] output for the first message after [lastVisitAt].
int? newSinceVisitDividerDisplayIndex({
  required List<ChannelMessage> messages,
  required DateTime? lastVisitAt,
}) {
  if (lastVisitAt == null || messages.isEmpty) return null;

  ChannelMessage? firstNew;
  for (final msg in messages) {
    final msgTime = DateTime.fromMillisecondsSinceEpoch(msg.createdAt);
    if (msgTime.isAfter(lastVisitAt)) {
      firstNew = msg;
      break;
    }
  }
  if (firstNew == null) return null;

  final displayItems = buildChatDisplayItems(messages);
  for (var i = 0; i < displayItems.length; i++) {
    if (displayItems[i].message?.id == firstNew.id) return i;
  }
  return null;
}
