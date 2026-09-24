import 'package:flutter/material.dart';

import 'prestige_noir.dart';
import 'v_colors.dart';

/// Theme-aware palette accessors — Prestige Noir dark-only.
extension VContextColors on BuildContext {
  bool get vIsDark => true;

  Color get vSurface => VColors.surfaceDark;
  Color get vSurfaceContainer => VColors.surfaceContainerDark;
  Color get vOnSurface => VColors.onSurfaceDark;
  Color get vOnSurfaceVariant => VColors.onSurfaceVariantDark;
  Color get vOutline => VColors.outlineDark;
  Color get vOutlineVariant => VColors.outlineVariantDark;
  Color get vPrimary => VColors.brand;
  Color get vError => VColors.error;

  Color get vSurfaceRaised => PrestigeNoir.surfaceRaised;
  Color get vChrome => PrestigeNoir.chrome;

  TextStyle? get vBodyTextStyle =>
      Theme.of(this).textTheme.bodyMedium?.copyWith(color: vOnSurface);

  TextStyle? get vHintTextStyle =>
      Theme.of(this).textTheme.bodyMedium?.copyWith(color: vOnSurfaceVariant);
}
