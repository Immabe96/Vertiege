import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../config/progression_glossary.dart';
import '../../services/contextual_help_prefs.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
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
    return FutureBuilder<bool>(
      future: ContextualHelpPrefs.shouldShowContextualHelp(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return IconButton(
          icon: Icon(FIcons.info, size: iconSize),
          tooltip: tooltip ?? ProgressionGlossary.sheetTitle,
          onPressed: () => showProgressionHelp(context, focus: focus),
        );
      },
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
    return FutureBuilder<bool>(
      future: ContextualHelpPrefs.shouldShowContextualHelp(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Align(
          child: VButton(
            variant: ButtonVariant.text,
            size: ButtonSize.small,
            onPressed: () => showProgressionHelp(context, focus: focus),
            icon: const Icon(FIcons.info, size: VIconSize.sm),
            label: label,
          ),
        );
      },
    );
  }
}
