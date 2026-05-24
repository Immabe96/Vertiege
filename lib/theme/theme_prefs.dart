import 'package:shared_preferences/shared_preferences.dart';

import '../state/theme_provider.dart';

/// Cached theme prefs loaded before [runApp] to avoid splash / first-frame flashes.
class ThemePrefs {
  ThemePrefs._();

  static ThemeState? cached;

  static const _themeKey = '@theme_preference';
  static const _textSizeKey = 'settings_text_size';

  static Future<void> warmCache() async {
    final prefs = await SharedPreferences.getInstance();
    var scheme = ThemeScheme.system;
    final themeValue = prefs.getString(_themeKey);
    if (themeValue != null) {
      scheme = ThemeScheme.values.firstWhere(
        (s) => s.name == themeValue,
        orElse: () => ThemeScheme.system,
      );
    }
    var textSize = TextSize.medium;
    final textSizeValue = prefs.getString(_textSizeKey);
    if (textSizeValue != null) {
      textSize = TextSize.values.firstWhere(
        (s) => s.name == textSizeValue,
        orElse: () => TextSize.medium,
      );
    }
    cached = ThemeState(scheme: scheme, textSize: textSize);
  }
}
