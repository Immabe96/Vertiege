import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

class SlashCommand {
  final String name;
  final String description;
  final void Function() onSelect;

  const SlashCommand({
    required this.name,
    required this.description,
    required this.onSelect,
  });
}

/// Hint bar when composer starts with `/`.
class VSlashCommandBar extends StatelessWidget {
  final List<SlashCommand> commands;
  final String filter;

  const VSlashCommandBar({
    super.key,
    required this.commands,
    required this.filter,
  });

  static List<SlashCommand> channelCommands({
    required void Function() onPin,
    required void Function() onThread,
    required void Function() onTier,
  }) {
    return [
      SlashCommand(
        name: 'pin',
        description: 'Pin the last message you sent',
        onSelect: onPin,
      ),
      SlashCommand(
        name: 'thread',
        description: 'Start a thread from your last message',
        onSelect: onThread,
      ),
      SlashCommand(
        name: 'tier',
        description: 'Show your standing in this world',
        onSelect: onTier,
      ),
    ];
  }

  static bool shouldShow(String text) => text.startsWith('/');

  static String commandFilter(String text) {
    if (!text.startsWith('/')) return '';
    final body = text.substring(1);
    final space = body.indexOf(' ');
    return space < 0 ? body.toLowerCase() : body.substring(0, space).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final needle = filter.toLowerCase();
    final visible = commands
        .where((c) => needle.isEmpty || c.name.startsWith(needle))
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: VSpacing.xs),
      decoration: BoxDecoration(
        color: VCommuneColors.surfaceTertiary,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: VCommuneColors.dividerSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: visible
            .map(
              (cmd) => InkWell(
                onTap: cmd.onSelect,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '/${cmd.name}',
                        style: const TextStyle(
                          fontSize: VFontSize.bodyMd,
                          fontWeight: VFontWeight.semiBold,
                          color: VCommuneColors.textLink,
                        ),
                      ),
                      const SizedBox(width: VSpacing.sm),
                      Expanded(
                        child: Text(
                          cmd.description,
                          style: const TextStyle(
                            fontSize: VFontSize.labelSm,
                            color: VCommuneColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
