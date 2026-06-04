import 'package:flutter/material.dart';

import '../v_section_list.dart';

/// Locked feature row: one-line reason on the tile, no extra chrome.
class QuietGateTile {
  QuietGateTile._();

  static VSectionTile section({
    required IconData icon,
    required String label,
    String? gate,
    VoidCallback? onOpen,
  }) {
    final locked = gate != null && onOpen == null;
    return VSectionTile(
      icon: icon,
      label: label,
      detail: locked ? gate : null,
      enabled: onOpen != null || locked,
      onTap: onOpen,
    );
  }
}
