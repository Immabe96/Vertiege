class TextParser {
  static final _mentionRegex = RegExp(r'@(\w+)');
  static final _hashtagRegex = RegExp(r'#(\w+)');

  static const _broadcastMentionHandles = {
    'allresidents',
    'everyone',
    'here',
  };

  static List<String> extractMentions(String text) =>
      _mentionRegex.allMatches(text).map((m) => m.group(1)!).toList();

  /// Resident @handles for server fan-out (excludes broadcast keywords).
  static List<String> extractResidentMentionHandles(String text) =>
      extractMentions(text)
          .where(
            (handle) => !_broadcastMentionHandles.contains(handle.toLowerCase()),
          )
          .toList();

  static List<String> extractHashtags(String text) => _hashtagRegex
      .allMatches(text)
      .map((m) => m.group(1)!.toLowerCase())
      .toList();

  static bool containsAllResidents(String text) => _mentionRegex
      .allMatches(text)
      .any((m) => _broadcastMentionHandles.contains(m.group(1)!.toLowerCase()));

  /// Alphanumeric handle used in @mentions for a display name.
  static String mentionHandleForName(String name) =>
      name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  static bool messageMentionsHandle(String text, String handle) {
    final normalized = handle.trim();
    if (normalized.isEmpty) return false;
    return extractResidentMentionHandles(text).any(
      (m) => m.toLowerCase() == normalized.toLowerCase(),
    );
  }
}
