import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../theme/v_tokens.dart';
import 'package:vertiege/ui/ui.dart';
import '../../widgets/core/v_feedback.dart';

/// Forui 0.21 baseline — production wrapper reference (Wave 0 chosen).
class BaselineSpikePage extends StatefulWidget {
  const BaselineSpikePage({super.key});

  @override
  State<BaselineSpikePage> createState() => _BaselineSpikePageState();
}

class _BaselineSpikePageState extends State<BaselineSpikePage> {
  bool _notifications = true;
  bool _haptics = false;

  @override
  Widget build(BuildContext context) {
    return VPage(
      title: 'UI reference',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.md),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          VSectionList(
            title: 'About',
            children: [
              FTile(
                title: const Text('Forui 0.21 baseline'),
                details: const Text('VPage + VSectionList + showVDialog'),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          VSectionList(
            title: 'Account',
            children: [
              VSectionTile(
                icon: Icons.person_outline,
                label: 'Profile preview',
                detail: 'Opens confirm dialog',
                onTap: _showDialog,
              ),
              VSectionTile(
                icon: Icons.palette_outlined,
                label: 'Appearance sheet',
                onTap: _showSheet,
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          VSectionList(
            title: 'Preferences',
            children: [
              VSectionSwitchTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              VSectionSwitchTile(
                icon: Icons.vibration,
                label: 'Haptics',
                value: _haptics,
                onChanged: (v) => setState(() => _haptics = v),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          VButton(
            label: 'Show toast',
            isFullWidth: true,
            onPressed: () => VFeedback.showMessage(
              context,
              'Forui baseline toast via VFeedback',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDialog() {
    return showVDialog<void>(
      context: context,
      title: 'Reference dialog',
      content: const Text('showVDialog → FDialog.raw'),
      actions: [
        vDialogActionsRow([
          VButton(
            label: 'Close',
            variant: ButtonVariant.outlined,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ]),
      ],
    );
  }

  Future<void> _showSheet() {
    return showFSheet(
      context: context,
      side: FLayout.btt,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sheet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: VSpacing.sm),
            const Text('Bottom sheet via FSheet.'),
            const SizedBox(height: VSpacing.md),
            VButton(
              label: 'Done',
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
