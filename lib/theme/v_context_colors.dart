import 'package:flutter/material.dart';

import 'v_colors.dart';

/// Theme-aware palette accessors — prefer over `isDark ? VColors.x : VColors.y`.
extension VContextColors on BuildContext {
  bool get vIsDark => Theme.of(this).brightness == Brightness.dark;

  Color get vSurface => vIsDark ? VColors.surfaceDark : VColors.surface;
  Color get vSurfaceContainer =>
      vIsDark ? VColors.surfaceContainerDark : VColors.surfaceContainer;
  Color get vOnSurface => vIsDark ? VColors.onSurfaceDark : VColors.onSurface;
  Color get vOnSurfaceVariant =>
      vIsDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;
  Color get vOutline => vIsDark ? VColors.outlineDark : VColors.outline;
  Color get vOutlineVariant =>
      vIsDark ? VColors.outlineVariantDark : VColors.outlineVariant;
  Color get vPrimary => vIsDark ? VColors.primaryLight : VColors.primary;
  Color get vError => VColors.error;

  /// Input text style aligned with Material theme + Vertiege palette.
  TextStyle? get vBodyTextStyle =>
      Theme.of(this).textTheme.bodyMedium?.copyWith(color: vOnSurface);

  /// Muted hint / variant text for fields and captions.
  TextStyle? get vHintTextStyle =>
      Theme.of(this).textTheme.bodyMedium?.copyWith(color: vOnSurfaceVariant);
}
