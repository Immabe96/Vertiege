import '../../models/message.dart';

enum ChatItemType { dateSeparator, firstInGroup, subsequent }

class ChatDisplayItem {
  final ChatItemType type;
  final ChannelMessage? message;
  final String dateLabel;

  const ChatDisplayItem({
    required this.type,
    required this.message,
    required this.dateLabel,
  });

  const ChatDisplayItem.date(this.dateLabel)
    : type = ChatItemType.dateSeparator,
      message = null;

  const ChatDisplayItem.first(this.message)
    : type = ChatItemType.firstInGroup,
      dateLabel = '';

  const ChatDisplayItem.subsequent(this.message)
    : type = ChatItemType.subsequent,
      dateLabel = '';
}

const chatGroupWindow = 5 * 60 * 1000;

List<ChatDisplayItem> buildChatDisplayItems(List<ChannelMessage> messages) {
  if (messages.isEmpty) return [];

  final items = <ChatDisplayItem>[];
  String? lastSenderId;
  int? lastSenderTimestamp;
  DateTime? lastDate;

  for (int i = 0; i < messages.length; i++) {
    final msg = messages[i];
    final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.createdAt);
    final msgDay = DateTime(msgDate.year, msgDate.month, msgDate.day);

    if (lastDate == null || msgDay != lastDate) {
      items.add(ChatDisplayItem.date(chatDateLabel(msg.createdAt)));
      lastDate = msgDay;
      lastSenderId = null;
      lastSenderTimestamp = null;
    }

    final sameSender = msg.senderId == lastSenderId;
    final withinWindow =
        lastSenderTimestamp != null &&
        (msg.createdAt - lastSenderTimestamp).abs() < chatGroupWindow;

    if (sameSender && withinWindow) {
      items.add(ChatDisplayItem.subsequent(msg));
    } else {
      items.add(ChatDisplayItem.first(msg));
    }

    lastSenderId = msg.senderId;
    lastSenderTimestamp = msg.createdAt;
  }

  return items;
}

String chatDateLabel(int ts) {
  if (ts <= 0) return '';
  final date = DateTime.fromMillisecondsSinceEpoch(ts);
  return _simpleDateLabel(date);
}

String _simpleDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';

  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  if (diff < 7) return weekdays[date.weekday - 1];
  return '${months[date.month - 1]} ${date.day}';
}
