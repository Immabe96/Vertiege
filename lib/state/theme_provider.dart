import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_prefs.dart';

enum ThemeScheme { system, light, dark }

enum TextSize { small, medium, large, xlarge }

/// Dark visual preset — Commune ladder (default) vs Prestige Noir (DCX-035).
enum DarkPreset { commune, prestige }

class ThemeState {
  final ThemeScheme scheme;
  final TextSize textSize;
  final DarkPreset darkPreset;
  final double saturation;
  final double contrast;
  final bool highContrast;

  const ThemeState({
    this.scheme = ThemeScheme.system,
    this.textSize = TextSize.medium,
    this.darkPreset = DarkPreset.prestige,
    this.saturation = 1.0,
    this.contrast = 1.0,
    this.highContrast = false,
  });

  ThemeMode get themeMode {
    switch (scheme) {
      case ThemeScheme.light:
        return ThemeMode.light;
      case ThemeScheme.dark:
        return ThemeMode.dark;
      case ThemeScheme.system:
        return ThemeMode.system;
    }
  }

  bool get isDark => scheme == ThemeScheme.dark;
  bool get isLight => scheme == ThemeScheme.light;
  bool get useCommunePreset => darkPreset == DarkPreset.commune;

  bool resolveIsDark(Brightness platformBrightness) => switch (scheme) {
        ThemeScheme.light => false,
        ThemeScheme.dark => true,
        ThemeScheme.system => platformBrightness == Brightness.dark,
      };

  double get textScale => switch (textSize) {
    TextSize.small => 0.85,
    TextSize.medium => 1.0,
    TextSize.large => 1.15,
    TextSize.xlarge => 1.3,
  };

  /// Effective contrast multiplier (high-contrast toggle boosts text legibility).
  double get effectiveContrast => highContrast ? contrast.clamp(1.0, 1.5) : contrast;

  ThemeState copyWith({
    ThemeScheme? scheme,
    TextSize? textSize,
    DarkPreset? darkPreset,
    double? saturation,
    double? contrast,
    bool? highContrast,
  }) => ThemeState(
    scheme: scheme ?? this.scheme,
    textSize: textSize ?? this.textSize,
    darkPreset: darkPreset ?? this.darkPreset,
    saturation: saturation ?? this.saturation,
    contrast: contrast ?? this.contrast,
    highContrast: highContrast ?? this.highContrast,
  );
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _themeKey = '@theme_preference';
  static const _textSizeKey = 'settings_text_size';
  static const _darkPresetKey = 'settings_dark_preset';
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

  Future<void> setScheme(ThemeScheme scheme) async {
    state = state.copyWith(scheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, scheme.name);
  }

  Future<void> setTextSize(TextSize size) async {
    state = state.copyWith(textSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textSizeKey, size.name);
  }

  Future<void> setDarkPreset(DarkPreset preset) async {
    state = state.copyWith(darkPreset: preset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_darkPresetKey, preset.name);
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

  Future<void> toggle() async {
    final next = state.isDark ? ThemeScheme.light : ThemeScheme.dark;
    await setScheme(next);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);
