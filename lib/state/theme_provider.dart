import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_prefs.dart';

part 'theme_provider.g.dart';

/// Legacy — app is dark-only; kept for persisted prefs migration.
enum ThemeScheme { dark }

/// Legacy — Prestige Noir is the only dark style.
enum DarkPreset { prestige }

enum TextSize { small, medium, large, xlarge }

class ThemeState {
  final TextSize textSize;
  final double saturation;
  final double contrast;
  final bool highContrast;

  const ThemeState({
    this.textSize = TextSize.medium,
    this.saturation = 1.0,
    this.contrast = 1.0,
    this.highContrast = false,
  });

  /// Always dark — light/system modes removed (Prestige Noir only).
  ThemeMode get themeMode => ThemeMode.dark;

  bool get isDark => true;
  bool get isLight => false;
  bool get useCommunePreset => false;

  /// Kept for call-site compatibility.
  ThemeScheme get scheme => ThemeScheme.dark;
  DarkPreset get darkPreset => DarkPreset.prestige;

  bool resolveIsDark(Brightness platformBrightness) => true;

  double get textScale => switch (textSize) {
    TextSize.small => 0.85,
    TextSize.medium => 1.0,
    TextSize.large => 1.15,
    TextSize.xlarge => 1.3,
  };

  double get effectiveContrast =>
      highContrast ? contrast.clamp(1.0, 1.5) : contrast;

  ThemeState copyWith({
    TextSize? textSize,
    double? saturation,
    double? contrast,
    bool? highContrast,
  }) => ThemeState(
    textSize: textSize ?? this.textSize,
    saturation: saturation ?? this.saturation,
    contrast: contrast ?? this.contrast,
    highContrast: highContrast ?? this.highContrast,
  );
}

@Riverpod(name: 'themeProvider', keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  static const _textSizeKey = 'settings_text_size';
  static const _saturationKey = 'settings_theme_saturation';
  static const _contrastKey = 'settings_theme_contrast';
  static const _highContrastKey = 'settings_high_contrast';

  @override
  ThemeState build() => ThemePrefs.cached ?? const ThemeState();

  Future<void> loadFromPrefs() async {
    await ThemePrefs.warmCache();
    final cached = ThemePrefs.cached;
    if (cached != null) state = cached;
  }

  /// No-op — dark-only app.
  Future<void> setScheme(ThemeScheme scheme) async {}

  /// No-op — Prestige Noir only.
  Future<void> setDarkPreset(DarkPreset preset) async {}

  Future<void> setTextSize(TextSize size) async {
    state = state.copyWith(textSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textSizeKey, size.name);
  }

  Future<void> setSaturation(double value) async {
    final clamped = value.clamp(0.5, 1.5);
    state = state.copyWith(saturation: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_saturationKey, clamped);
  }

  Future<void> setContrast(double value) async {
    final clamped = value.clamp(0.5, 1.5);
    state = state.copyWith(contrast: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_contrastKey, clamped);
  }

  Future<void> setHighContrast(bool enabled) async {
    state = state.copyWith(
      highContrast: enabled,
      contrast: enabled ? state.contrast.clamp(1.15, 1.5) : state.contrast,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, enabled);
  }
}
