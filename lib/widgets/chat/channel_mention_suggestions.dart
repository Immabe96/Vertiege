import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/text_parser.dart';

/// @mention autocomplete for world channel composers (Wave S5).
class ChannelMentionSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  const ChannelMentionSuggestions({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final brightness = Theme.of(context).brightness;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(VRadius.md),
      color: VCommuneColors.surfaceSecondaryOf(brightness),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180, maxWidth: 280),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: VSpacing.xs),
          itemCount: suggestions.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: VCommuneColors.dividerOf(brightness),
          ),
          itemBuilder: (_, index) {
            final name = suggestions[index];
            final handle = TextParser.mentionHandleForName(name);
            return ListTile(
              dense: true,
              title: Text(name),
              subtitle: handle.isNotEmpty ? Text('@$handle') : null,
              onTap: () => onSelect(name),
            );
          },
        ),
      ),
    );
  }
}

/// Tracks @mention trigger state for a channel composer.
class ChannelMentionController {
  List<({String name, String handle})> _residents = const [];
  int? _triggerStart;
  String _query = '';

  List<String> get suggestions {
    if (_triggerStart == null) return const [];
    final q = _query.toLowerCase();
    final names = <String>{'AllResidents'};
    for (final resident in _residents) {
      if (q.isEmpty ||
          resident.name.toLowerCase().contains(q) ||
          resident.handle.toLowerCase().contains(q)) {
        names.add(resident.name);
      }
    }
    return names.toList()..sort();
  }

  void setResidents(List<Map<String, dynamic>> members) {
    _residents = members
        .map((m) {
          final name = m['resident_name'] as String? ?? '';
          final handle = TextParser.mentionHandleForName(name);
          if (name.isEmpty || handle.isEmpty) return null;
          return (name: name, handle: handle);
        })
        .whereType<({String name, String handle})>()
        .toList();
  }

  void onTextChanged(String text, int cursor) {
    if (cursor < 0 || cursor > text.length) {
      _clear();
      return;
    }
    final before = text.substring(0, cursor);
    final match = RegExp(r'@(\w*)$').firstMatch(before);
    if (match == null) {
      _clear();
      return;
    }
    _triggerStart = match.start;
    _query = match.group(1) ?? '';
  }

  ({String text, int cursor})? applySuggestion(
    String text,
    String selectedName,
    int cursor,
  ) {
    final start = _triggerStart;
    if (start == null || cursor < 0) return null;
    final handle = selectedName == 'AllResidents'
        ? 'AllResidents'
        : TextParser.mentionHandleForName(selectedName);
    final before = text.substring(0, start);
    final after = text.substring(cursor);
    final replacement = '@$handle ';
    _clear();
    return (text: '$before$replacement$after', cursor: before.length + replacement.length);
  }

  void _clear() {
    _triggerStart = null;
    _query = '';
  }
}
