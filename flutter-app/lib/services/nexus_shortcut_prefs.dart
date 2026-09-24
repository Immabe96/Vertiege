import 'storage_service.dart';

/// Tracks last-opened Nexus shortcut for compact-row ordering (Wave 14).
class NexusShortcutPrefs {
  NexusShortcutPrefs._();

  static const _keyPrefix = 'nexus_shortcut_last_';
  static const _todayExpandedKey = 'nexus_today_expanded';

  static String _key(String shortcutId) => '$_keyPrefix$shortcutId';

  /// Today strip starts collapsed so the feed owns the first viewport.
  static Future<bool> isTodayExpanded() async {
    final raw = await StorageService.getString(_todayExpandedKey);
    return raw == 'true';
  }

  static Future<void> setTodayExpanded(bool expanded) async {
    await StorageService.setString(
      _todayExpandedKey,
      expanded ? 'true' : 'false',
    );
  }

  static Future<void> recordVisit(String shortcutId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await StorageService.setString(_key(shortcutId), now.toString());
  }

  /// Returns [ids] sorted by most recently visited first; unknown ids keep stable tail order.
  static Future<List<String>> orderByRecency(List<String> ids) async {
    final stamps = <String, int>{};
    for (final id in ids) {
      final raw = await StorageService.getString(_key(id));
      stamps[id] = int.tryParse(raw ?? '') ?? 0;
    }
    final sorted = List<String>.from(ids)
      ..sort((a, b) => stamps[b]!.compareTo(stamps[a]!));
    return sorted;
  }
}
