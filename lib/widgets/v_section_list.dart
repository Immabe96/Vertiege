import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Grouped settings-style sections using Forui [FTileGroup] (shadcn-like).
class VSectionList extends StatelessWidget {
  final String title;
  final List<FTileMixin> children;

  const VSectionList({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FTileGroup(
      label: Text(
        title.toUpperCase(),
        style: theme.typography.sm.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colors.mutedForeground,
          letterSpacing: 0.5,
        ),
      ),
      children: children,
    );
  }
}

/// Navigation row — [FTile] with chevron.
class VSectionTile extends FTile {
  VSectionTile({
    required IconData icon,
    required String label,
    super.key,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
    bool enabled = true,
  }) : super(
         enabled: enabled,
         prefix: Builder(
           builder: (context) => Icon(
             icon,
             color: iconColor ?? context.theme.colors.mutedForeground,
           ),
         ),
         title: Builder(
           builder: (context) => Text(
             label,
             style: TextStyle(
               color: titleColor ?? context.theme.colors.foreground,
             ),
           ),
         ),
         suffix:
             trailing ??
             Builder(
               builder: (context) => Icon(
                 FIcons.chevronRight,
                 color: context.theme.colors.mutedForeground,
                 size: 18,
               ),
             ),
         onPress: enabled ? onTap : null,
       );
}

/// Toggle row — icon + label + [FSwitch] in the tile suffix.
class VSectionSwitchTile extends FTile {
  VSectionSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    super.key,
    ValueChanged<bool>? onChanged,
  }) : super(
         prefix: Builder(
           builder: (context) => Icon(
             icon,
             color: context.theme.colors.mutedForeground,
           ),
         ),
         title: Builder(
           builder: (context) => Text(
             label,
             style: TextStyle(color: context.theme.colors.foreground),
           ),
         ),
         suffix: FSwitch(
           value: value,
           onChange: onChanged,
           enabled: onChanged != null,
         ),
       );
}
