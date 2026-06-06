/// Label for channel list rows when others are typing.
String? channelTypingLabel(
  Set<String> typingUserIds, {
  String? currentUserId,
}) {
  final others = typingUserIds
      .where((id) => id.isNotEmpty && id != currentUserId)
      .toList();
  if (others.isEmpty) return null;
  if (others.length == 1) return 'Someone is typing…';
  return '${others.length} residents typing…';
}
