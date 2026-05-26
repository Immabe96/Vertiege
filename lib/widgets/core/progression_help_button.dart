import 'package:flutter/material.dart';

import '../../config/progression_glossary.dart';
import '../../theme/v_tokens.dart';
import 'progression_help_sheet.dart';

/// Opens [ProgressionHelpSheet] for the given topic.
class ProgressionHelpButton extends StatelessWidget {
  final ProgressionFocus focus;
  final String? tooltip;
  final double iconSize;

  const ProgressionHelpButton({
    super.key,
    this.focus = ProgressionFocus.overview,
    this.tooltip,
    this.iconSize = VIconSize.md,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, size: iconSize),
      tooltip: tooltip ?? ProgressionGlossary.sheetTitle,
      onPressed: () => showProgressionHelp(context, focus: focus),
    );
  }
}

/// Text link variant for cards and tabs.
class ProgressionHelpLink extends StatelessWidget {
  final ProgressionFocus focus;
  final String label;

  const ProgressionHelpLink({
    super.key,
    this.focus = ProgressionFocus.overview,
    this.label = 'How progression works',
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: () => showProgressionHelp(context, focus: focus),
        icon: const Icon(Icons.help_outline, size: VIconSize.sm),
        label: Text(label),
      ),
    );
  }
}
