import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../theme/v_colors.dart';

/// Settings perk row — icon, title, value (subscription tier display).
class VPerkTile extends FTile {
  VPerkTile({
    required IconData icon,
    required String title,
    required String value,
    super.key,
  }) : super(
         prefix: Builder(
           builder: (context) =>
               Icon(icon, color: context.theme.colors.mutedForeground),
         ),
         title: Builder(
           builder: (context) => Text(
             title,
             style: TextStyle(color: context.theme.colors.foreground),
           ),
         ),
         details: Builder(
           builder: (context) {
             final valueColor = value.contains('Locked')
                 ? context.theme.colors.mutedForeground
                 : VColors.tertiary;
             return Text(
               value,
               style: TextStyle(color: valueColor, fontWeight: FontWeight.w600),
             );
           },
         ),
       );
}
