import 'package:flutter/material.dart';

import '../state/theme_provider.dart';
import 'v_theme.dart';

/// AppTheme — delegates to [VTheme] with Commune vs Prestige presets.
class AppTheme {
  AppTheme._();

  static ThemeData get light => VTheme.light;
  static ThemeData get dark => VTheme.dark;
  static ThemeData get lightCommune => VTheme.lightCommune;
  static ThemeData get darkCommune => VTheme.darkCommune;
  static ThemeData get theme => light;

  static ThemeData lightFor(ThemeState state) =>
      state.useCommunePreset ? lightCommune : light;

  static ThemeData darkFor(ThemeState state) =>
      state.useCommunePreset ? darkCommune : dark;
}
