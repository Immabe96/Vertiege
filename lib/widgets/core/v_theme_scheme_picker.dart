import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../state/theme_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Theme picker with Commune default dark preset (DCX-035).
class VThemeSchemePicker extends StatelessWidget {
  final ThemeScheme scheme;
  final DarkPreset darkPreset;
  final ValueChanged<ThemeScheme> onSchemeChanged;
  final ValueChanged<DarkPreset>? onDarkPresetChanged;

  const VThemeSchemePicker({
    super.key,
    required this.scheme,
    this.darkPreset = DarkPreset.prestige,
    required this.onSchemeChanged,
    this.onDarkPresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              for (final entry in _schemeEntries)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: entry.$1 != ThemeScheme.dark ? VSpacing.xs : 0,
                    ),
                    child: FButton(
                      variant: scheme == entry.$1 ? .primary : .outline,
                      onPress: () => onSchemeChanged(entry.$1),
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
        ),
        if (onDarkPresetChanged != null &&
            (scheme == ThemeScheme.dark || scheme == ThemeScheme.system)) ...[
          const SizedBox(height: VSpacing.sm),
          Text(
            'Dark style',
            style: TextStyle(
              fontSize: VFontSize.labelMd,
              color: VCommuneColors.textMutedOf(
                Theme.of(context).brightness,
              ),
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Row(
            children: [
              for (final entry in _presetEntries)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: entry.$1 != DarkPreset.prestige ? VSpacing.xs : 0,
                    ),
                    child: FButton(
                      variant:
                          darkPreset == entry.$1 ? .primary : .outline,
                      onPress: () => onDarkPresetChanged!(entry.$1),
                      child: Text(
                        entry.$2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: VFontSize.labelSm),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static const _schemeEntries = [
    (ThemeScheme.system, Icons.brightness_auto, 'Auto'),
    (ThemeScheme.light, Icons.light_mode, 'Light'),
    (ThemeScheme.dark, Icons.dark_mode, 'Dark'),
  ];

  static const _presetEntries = [
    (DarkPreset.commune, 'Commune'),
    (DarkPreset.prestige, 'Prestige'),
  ];
}
