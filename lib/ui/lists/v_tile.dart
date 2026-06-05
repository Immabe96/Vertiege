import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Generic Forui list row. Prefer [VSectionTile] for settings-style navigation.
class VTile extends FTile {
  VTile({
    super.key,
    super.onPress,
    super.prefix,
    required super.title,
    super.subtitle,
    super.suffix,
    super.enabled = true,
  });
}
