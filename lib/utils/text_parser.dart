class TextParser {
  static final _mentionRegex = RegExp(r'@(\w+)');
  static final _hashtagRegex = RegExp(r'#(\w+)');

  static List<String> extractMentions(String text) =>
      _mentionRegex.allMatches(text).map((m) => m.group(1)!).toList();

  static List<String> extractHashtags(String text) => _hashtagRegex
      .allMatches(text)
      .map((m) => m.group(1)!.toLowerCase())
      .toList();

  static bool containsAllResidents(String text) => _mentionRegex
      .allMatches(text)
      .any((m) => m.group(1)!.toLowerCase() == 'allresidents');
}
