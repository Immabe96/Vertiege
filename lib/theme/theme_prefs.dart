import 'package:shared_preferences/shared_preferences.dart';

import '../state/theme_provider.dart';

/// Cached theme prefs loaded before [runApp] to avoid splash / first-frame flashes.
class ThemePrefs {
  ThemePrefs._();

  static ThemeState? cached;

  static const _textSizeKey = 'settings_text_size';
  static const _saturationKey = 'settings_theme_saturation';
  static const _contrastKey = 'settings_theme_contrast';
  static const _highContrastKey = 'settings_high_contrast';

  static Future<void> warmCache() async {
    final prefs = await SharedPreferences.getInstance();

    var textSize = TextSize.medium;
    final textSizeValue = prefs.getString(_textSizeKey);
    if (textSizeValue != null) {
      textSize = TextSize.values.firstWhere(
        (s) => s.name == textSizeValue,
        orElse: () => TextSize.medium,
      );
    }

    final saturation = prefs.getDouble(_saturationKey) ?? 1.0;
    final contrast = prefs.getDouble(_contrastKey) ?? 1.0;
    final highContrast = prefs.getBool(_highContrastKey) ?? false;

    cached = ThemeState(
      textSize: textSize,
      saturation: saturation,
      contrast: contrast,
      highContrast: highContrast,
    );
  }
}
