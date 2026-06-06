import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/chat_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/overlays/v_sheet.dart';
import '../../widgets/core/v_feedback.dart';

/// Ephemeral DM defaults for a room (SOC-S10).
Future<void> showDmRoomSettingsSheet(
  BuildContext context, {
  required String roomId,
}) {
  return showVSheet(
    context,
    DmRoomSettingsSheet(roomId: roomId),
    maxSize: 0.55,
  );
}

class DmRoomSettingsSheet extends ConsumerStatefulWidget {
  final String roomId;

  const DmRoomSettingsSheet({super.key, required this.roomId});

  @override
  ConsumerState<DmRoomSettingsSheet> createState() =>
      _DmRoomSettingsSheetState();
}

class _DmRoomSettingsSheetState extends ConsumerState<DmRoomSettingsSheet> {
  int? _selectedSeconds;
  bool _loading = true;

  static const _options = <({String label, int? seconds})>[
    (label: 'Keep forever', seconds: null),
    (label: '24 hours', seconds: 86400),
    (label: '7 days', seconds: 604800),
    (label: '30 days', seconds: 2592000),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seconds = await ref
        .read(chatProvider.notifier)
        .getAutoDeleteForRoom(widget.roomId);
    if (!mounted) return;
    setState(() {
      _selectedSeconds = seconds;
      _loading = false;
    });
  }

  Future<void> _select(int? seconds) async {
    await ref
        .read(chatProvider.notifier)
        .setAutoDeleteForRoom(widget.roomId, seconds);
    if (!mounted) return;
    setState(() => _selectedSeconds = seconds);
    VFeedback.showMessage(
      context,
      seconds == null ? 'Messages will not auto-delete' : 'Auto-delete updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.sm,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Message lifetime',
            style: TextStyle(
              fontSize: VFontSize.headlineSm,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimaryOf(brightness),
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'New messages you send in this chat will disappear after the chosen time.',
            style: TextStyle(
              fontSize: VFontSize.bodySm,
              color: VCommuneColors.textMutedOf(brightness),
            ),
          ),
          const SizedBox(height: VSpacing.md),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ..._options.map(
              (option) => RadioListTile<int?>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: option.seconds,
                groupValue: _selectedSeconds,
                title: Text(option.label),
                onChanged: (value) => _select(value),
              ),
            ),
        ],
      ),
    );
  }
}
