import 'package:flutter/material.dart';

import 'package:vertiege/ui/ui.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_tokens.dart';

/// Prestige-styled settings section with label and card wrapper.
class SettingsPrestigeSection extends StatelessWidget {
  const SettingsPrestigeSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: VSpacing.xs, bottom: VSpacing.xs),
          child: VPrestigeSectionLabel(title: title),
        ),
        VPrestigeCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: PrestigeNoir.borderLight,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
