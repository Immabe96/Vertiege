import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeScheme { system, light, dark }

enum TextSize { small, medium, large, xlarge }

class ThemeState {
  final ThemeScheme scheme;
  final TextSize textSize;
  const ThemeState({
    this.scheme = ThemeScheme.light,
    this.textSize = TextSize.medium,
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

  double get textScale => switch (textSize) {
    TextSize.small => 0.85,
    TextSize.medium => 1.0,
    TextSize.large => 1.15,
    TextSize.xlarge => 1.3,
  };

  ThemeState copyWith({ThemeScheme? scheme, TextSize? textSize}) => ThemeState(
    scheme: scheme ?? this.scheme,
    textSize: textSize ?? this.textSize,
  );
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _themeKey = '@theme_preference';
  static const _textSizeKey = 'settings_text_size';

  @override
  ThemeState build() {
    loadFromPrefs();
    return const ThemeState();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getString(_themeKey);
    if (themeValue != null) {
      final scheme = ThemeScheme.values.firstWhere(
        (s) => s.name == themeValue,
        orElse: () => ThemeScheme.light,
      );
      state = state.copyWith(scheme: scheme);
    }
    final textSizeValue = prefs.getString(_textSizeKey);
    if (textSizeValue != null) {
      final textSize = TextSize.values.firstWhere(
        (s) => s.name == textSizeValue,
        orElse: () => TextSize.medium,
      );
      state = state.copyWith(textSize: textSize);
    }
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

  Future<void> toggle() async {
    final next = state.isDark ? ThemeScheme.light : ThemeScheme.dark;
    await setScheme(next);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);
