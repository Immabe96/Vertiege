import 'package:flutter/material.dart';
import 'v_theme.dart';

/// AppTheme — delegates to new VTheme system
/// The old 592-line duplicated theme config has been replaced
/// with a clean M3-compatible builder in v_theme.dart
class AppTheme {
  AppTheme._();

  static ThemeData get light => VTheme.light;
  static ThemeData get dark => VTheme.dark;
  static ThemeData get theme => light;
}
