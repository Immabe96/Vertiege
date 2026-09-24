import 'package:flutter/material.dart';
import '../../config/progression_glossary.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import 'glass_sheet.dart';

/// Bottom sheet explaining XP, tier, rep, world prestige, and world level.
class ProgressionHelpSheet extends StatelessWidget {
  final ProgressionFocus focus;

  const ProgressionHelpSheet({
    super.key,
    this.focus = ProgressionFocus.overview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final shown = ProgressionGlossary.entriesFor(focus);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.md,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ProgressionGlossary.sheetTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            ProgressionGlossary.accountIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          ...shown.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.md),
              child: _EntryCard(
                entry: entry,
                highlighted: focus != ProgressionFocus.overview &&
                    entry.focus == focus,
              ),
            ),
          ),
          if (focus != ProgressionFocus.overview) ...[
            VButton(
              variant: ButtonVariant.text,
              label: 'See all topics',
              onPressed: () {
                Navigator.of(context).pop();
                showProgressionHelp(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final ProgressionEntry entry;
  final bool highlighted;

  const _EntryCard({
    required this.entry,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = highlighted
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLowDark,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: border.withValues(alpha: highlighted ? 0.6 : 0.35),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xxs),
          Text(
            entry.oneLiner,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.medium,
              height: 1.35,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            entry.detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

void showProgressionHelp(
  BuildContext context, {
  ProgressionFocus focus = ProgressionFocus.overview,
}) {
  showAppSheet(
    context,
    ProgressionHelpSheet(focus: focus),
    initialSize: focus == ProgressionFocus.overview ? 0.85 : 0.55,
    maxSize: 0.92,
  );
}
