import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import '../core/status_dot.dart';
import '../core/tab_aware_sheet.dart';

/// Chat-native presence + custom status picker (DCX-105).
enum ResidentPresence { online, idle, dnd, invisible }

class ResidentStatus {
  final ResidentPresence presence;
  final String? customStatus;

  const ResidentStatus({
    this.presence = ResidentPresence.online,
    this.customStatus,
  });
}

Presence _mapPresence(ResidentPresence p) => switch (p) {
  ResidentPresence.online => Presence.online,
  ResidentPresence.idle => Presence.idle,
  ResidentPresence.dnd => Presence.dnd,
  ResidentPresence.invisible => Presence.offline,
};

Future<ResidentStatus?> showStatusPicker(
  BuildContext context, {
  required ResidentStatus current,
}) {
  return showTabAwareModalBottomSheet<ResidentStatus>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _StatusPickerSheet(initial: current),
  );
}

class _StatusPickerSheet extends StatefulWidget {
  final ResidentStatus initial;

  const _StatusPickerSheet({required this.initial});

  @override
  State<_StatusPickerSheet> createState() => _StatusPickerSheetState();
}

class _StatusPickerSheetState extends State<_StatusPickerSheet> {
  late ResidentPresence _presence;
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _presence = widget.initial.presence;
    _customController = TextEditingController(
      text: widget.initial.customStatus ?? '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      ResidentStatus(
        presence: _presence,
        customStatus: _customController.text.trim().isEmpty
            ? null
            : _customController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: VCommuneColors.surfaceFloating,
        borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.lg)),
      ),
      padding: EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.md,
        VSpacing.lg,
        VSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          for (final option in ResidentPresence.values)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _presence = option),
                borderRadius: BorderRadius.circular(VRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.sm,
                    vertical: VSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      StatusDot(presence: _mapPresence(option), size: 10),
                      const SizedBox(width: VSpacing.md),
                      Expanded(child: Text(_labelFor(option))),
                      if (_presence == option)
                        const Icon(Icons.check, color: VCommuneColors.textLink),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: VSpacing.sm),
          TextField(
            controller: _customController,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Custom status',
              hintText: 'What are you up to?',
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          VButton(label: 'Save', onPressed: _save, isFullWidth: true),
        ],
      ),
    );
  }

  String _labelFor(ResidentPresence p) => switch (p) {
    ResidentPresence.online => 'Online',
    ResidentPresence.idle => 'Idle',
    ResidentPresence.dnd => 'Do not disturb',
    ResidentPresence.invisible => 'Invisible',
  };
}
