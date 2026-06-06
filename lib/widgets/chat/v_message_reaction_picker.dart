import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

const kDefaultReactionEmojis = [
  '👍',
  '❤️',
  '😂',
  '😮',
  '😢',
  '🔥',
  '🎉',
  '👀',
  '💯',
  '🚀',
];

/// Quick emoji reaction row for message actions.
Future<void> showMessageReactionPicker(
  BuildContext context, {
  required void Function(String emoji) onPick,
  List<String> emojis = kDefaultReactionEmojis,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Wrap(
          spacing: VSpacing.sm,
          runSpacing: VSpacing.sm,
          children: emojis
              .map(
                (emoji) => GestureDetector(
                  onTap: () {
                    onPick(emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(VSpacing.sm),
                    decoration: BoxDecoration(
                      color: isDark
                          ? VColors.surfaceContainerDark
                          : VColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: VFontSize.headlineMd),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}
