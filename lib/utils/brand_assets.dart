import 'package:flutter/material.dart';

/// Brand mark PNGs rasterized from [veritiege-dark-mode.svg] /
/// [veritiege-light-mode.svg] (same paths as adaptive launcher foreground).
String brandMarkAsset(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? 'assets/images/splash-icon.png'
      : 'assets/images/splash-icon-light.png';
}
