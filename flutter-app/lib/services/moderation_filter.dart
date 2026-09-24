import 'feature_flags.dart';
import 'supabase.dart';

/// Pre-publish content filtering for posts and channel messages.
///
/// Pipeline:
///   1. Local profanity / pattern / spam heuristics (always)
///   2. Optional remote edge function (`moderate-content`) when
///      [FeatureFlags.contentModerationRemote] is true
///
/// Remote checks are not bypassable for callers that use [checkContentAsync].
/// Wire OpenAI (or similar) via `OPENAI_API_KEY` on the edge function.
class ModerationFilter {
  // ── Stage 1: Profanity word list ──────────────────────────

  static const _profanityList = {
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
    if (RegExp(r'(.)\1{5,}').hasMatch(text)) {
      return 'Content appears to be spam';
    }
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    for (final word in {...words}) {
      if (word.length > 4 && words.where((w) => w == word).length > 3) {
        return 'Content appears to be spam';
      }
    }
    return null;
  }

  // ── Public API ────────────────────────────────────────────

  /// Synchronous local-only check (UI preview / offline).
  ///
  /// Prefer [checkContentAsync] before publish so remote moderation runs.
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

  /// Local check, then optional `moderate-content` edge function.
  static Future<String?> checkContentAsync(
    String text, {
    String surface = 'post',
  }) async {
    final local = checkContent(text);
    if (local != null) return local;
    if (!FeatureFlags.contentModerationRemote) return null;
    if (!isSupabaseConfigured()) return null;

    try {
      final client = getSupabase();
      final response = await client.functions.invoke(
        'moderate-content',
        body: {'text': text, 'surface': surface},
      );
      if (response.status == 503) {
        return 'Moderation is temporarily unavailable. Try again shortly.';
      }
      final data = response.data;
      if (data is Map && data['allowed'] == false) {
        return data['error'] as String? ??
            'Content may violate community guidelines';
      }
    } catch (_) {
      // Fail open on transport errors so offline compose still works after
      // local checks; edge + RLS remain the hard gates when online publish runs.
    }
    return null;
  }
}
