import 'package:shared_preferences/shared_preferences.dart';

import '../state/theme_provider.dart';

/// Cached theme prefs loaded before [runApp] to avoid splash / first-frame flashes.
class ThemePrefs {
  ThemePrefs._();

  static ThemeState? cached;

  static const _themeKey = '@theme_preference';
  static const _textSizeKey = 'settings_text_size';
  static const _darkPresetKey = 'settings_dark_preset';
  static const _saturationKey = 'settings_theme_saturation';
  static const _contrastKey = 'settings_theme_contrast';
  static const _highContrastKey = 'settings_high_contrast';

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
    var darkPreset = DarkPreset.commune;
    final presetValue = prefs.getString(_darkPresetKey);
    if (presetValue != null) {
      darkPreset = DarkPreset.values.firstWhere(
        (p) => p.name == presetValue,
        orElse: () => DarkPreset.commune,
      );
    }
    final saturation = prefs.getDouble(_saturationKey) ?? 1.0;
    final contrast = prefs.getDouble(_contrastKey) ?? 1.0;
    final highContrast = prefs.getBool(_highContrastKey) ?? false;
    cached = ThemeState(
      scheme: scheme,
      textSize: textSize,
      darkPreset: darkPreset,
      saturation: saturation,
      contrast: contrast,
      highContrast: highContrast,
    );
  }
}
