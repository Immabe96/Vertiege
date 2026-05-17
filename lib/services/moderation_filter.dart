/// Pre-publish content filtering for posts and channel messages.
///
/// The Sentinel — checks content for policy violations before it goes
/// public using a multi-stage pipeline:
///   1. Profanity detection (basic word list)
///   2. Keyword/pattern heuristics
///   3. Spam detection
///
/// TODO: Replace pipeline stages with a real moderation API
/// (e.g. Perspective API, OpenAI Moderation, or a self-hosted model)
/// before production launch. The current implementation is a
/// placeholder that only catches the most obvious violations.
class ModerationFilter {
  // ── Stage 1: Profanity word list ──────────────────────────

  static const _profanityList = {
    // Common English profanities (abbreviated set)
    'fuck', 'shit', 'damn', 'ass', 'bitch', 'bastard', 'crap', 'dick',
    'piss', 'cunt', 'whore', 'slut', 'douche', 'moron', 'idiot',
  };

  static String? _checkProfanity(String lower) {
    for (final word in _profanityList) {
      if (RegExp('\\b$word\\b').hasMatch(lower)) {
        return 'Content contains inappropriate language';
      }
    }
    return null;
  }

  // ── Leetspeak normalization ────────────────────────────────

  static String _normalizeLeetspeak(String text) {
    return text
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll('@', 'a')
        .replaceAll('\$', 's')
        .replaceAll('!', 'i')
        .replaceAll('+', 't');
  }

  // ── Stage 2: Keyword / pattern filtering ──────────────────

  static final _blockedPatterns = [
    RegExp(r'\b(hate\s*speech|slur|violence|threat)\b', caseSensitive: false),
    RegExp(
      r'\b(kill|murder|attack)\s*(yourself|others|them|everyone)\b',
      caseSensitive: false,
    ),
    RegExp(r'\b(d[o0]x|x[s\$]s)\b', caseSensitive: false),
    RegExp(r'https?://\S*\.(onion|bit)\b', caseSensitive: false),
  ];

  static String? _checkPatterns(String lower) {
    for (final pattern in _blockedPatterns) {
      if (pattern.hasMatch(lower)) {
        return 'Content may violate community guidelines';
      }
    }
    return null;
  }

  // ── Stage 3: Spam detection ───────────────────────────────

  static String? _checkSpam(String text) {
    if (text.length > 50) {
      final capsCount = text.runes.where((r) => r >= 65 && r <= 90).length;
      if (capsCount / text.length > 0.5) return 'Content appears to be spam';
    }
    if (RegExp(r'(.)\1{5,}').hasMatch(text))
      return 'Content appears to be spam';
    // More than 3 repeated words
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    for (final word in {...words}) {
      if (word.length > 4 && words.where((w) => w == word).length > 3) {
        return 'Content appears to be spam';
      }
    }
    return null;
  }

  // ── Public API ────────────────────────────────────────────

  /// Runs content through all moderation stages.
  ///
  /// Returns `null` if clean, or a human-readable reason string if flagged.
  static String? checkContent(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Content cannot be empty';

    final lower = trimmed.toLowerCase();
    final leetNormalized = _normalizeLeetspeak(lower);

    final profanityResult = _checkProfanity(lower);
    if (profanityResult != null) return profanityResult;

    final leetProfanityResult = _checkProfanity(leetNormalized);
    if (leetProfanityResult != null) return leetProfanityResult;

    final patternResult = _checkPatterns(lower);
    if (patternResult != null) return patternResult;

    final leetPatternResult = _checkPatterns(leetNormalized);
    if (leetPatternResult != null) return leetPatternResult;

    final spamResult = _checkSpam(trimmed);
    if (spamResult != null) return spamResult;

    return null;
  }
}
