import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../state/theme_provider.dart';
import '../../theme/v_tokens.dart';

/// Compact theme picker (replaces Material [SegmentedButton] in settings).
class VThemeSchemePicker extends StatelessWidget {
  final ThemeScheme scheme;
  final ValueChanged<ThemeScheme> onChanged;

  const VThemeSchemePicker({
    super.key,
    required this.scheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Full-width row — safe inside Card/ListView; avoids unbounded-width
    // RenderFlex failures when a parent (e.g. FTile.raw) shrink-wraps.
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          for (final entry in _entries)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: entry.$1 != ThemeScheme.dark ? VSpacing.xs : 0,
                ),
                child: FButton(
                  variant: scheme == entry.$1 ? .primary : .outline,
                  onPress: () => onChanged(entry.$1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.$2, size: VIconSize.sm),
                      const SizedBox(width: VSpacing.xs),
                      Flexible(
                        child: Text(
                          entry.$3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: VFontSize.labelSm),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _entries = [
    (ThemeScheme.system, Icons.brightness_auto, 'Auto'),
    (ThemeScheme.light, Icons.light_mode, 'Light'),
    (ThemeScheme.dark, Icons.dark_mode, 'Dark'),
  ];
}
