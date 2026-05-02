import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeScheme { system, light, dark }

class ThemeState {
  final ThemeScheme scheme;
  const ThemeState({this.scheme = ThemeScheme.system});

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

  ThemeState copyWith({ThemeScheme? scheme}) =>
      ThemeState(scheme: scheme ?? this.scheme);
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const _key = '@theme_preference';

  ThemeNotifier() : super(const ThemeState());

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      final scheme = ThemeScheme.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ThemeScheme.system,
      );
      state = state.copyWith(scheme: scheme);
    }
  }

  Future<void> setScheme(ThemeScheme scheme) async {
    state = state.copyWith(scheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, scheme.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);
