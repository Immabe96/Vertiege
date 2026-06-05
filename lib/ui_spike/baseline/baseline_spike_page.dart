import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../forui/v_hub_page.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import '../../widgets/core/v_dialog.dart';
import '../../widgets/core/v_feedback.dart';
import '../../widgets/v_section_list.dart';
import '../spike_backend.dart';
import '../spike_settings_model.dart';

/// Forui 0.21 baseline — current production wrappers.
class BaselineSpikePage extends StatelessWidget {
  final SpikeSettingsModel model;
  final ValueChanged<SpikeBackend> onBackendChanged;
  final SpikeBackend backend;

  const BaselineSpikePage({
    super.key,
    required this.model,
    required this.onBackendChanged,
    required this.backend,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return VHubPage(
          title: 'UI Spike',
          showBack: true,
          body: ListView(
            padding: const EdgeInsets.all(VSpacing.md),
            children: [
              _backendPicker(context),
              const SizedBox(height: VSpacing.md),
              VSectionList(
                title: 'About',
                children: [
                  FTile(
                    title: const Text('Wave 0 baseline'),
                    details: const Text('Forui 0.21 + VHubPage / VSectionList'),
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
                    onTap: () => _showDialog(context),
                  ),
                  VSectionTile(
                    icon: Icons.palette_outlined,
                    label: 'Appearance sheet',
                    onTap: () => _showSheet(context),
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
                    value: model.notificationsEnabled,
                    onChanged: model.setNotifications,
                  ),
                  VSectionSwitchTile(
                    icon: Icons.vibration,
                    label: 'Haptics',
                    value: model.hapticsEnabled,
                    onChanged: model.setHaptics,
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.md),
              VButton(
                label: 'Show toast',
                isFullWidth: true,
                onPressed: () => VFeedback.showMessage(
                  context,
                  'Baseline toast via VFeedback',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _backendPicker(BuildContext context) {
    return VSectionList(
      title: 'Backend',
      children: [
        for (final candidate in SpikeBackend.values)
          VSectionTile(
            icon: Icons.layers_outlined,
            label: candidate.label,
            trailing: backend == candidate
                ? Icon(Icons.check, color: context.theme.colors.primary)
                : null,
            onTap: () => onBackendChanged(candidate),
          ),
      ],
    );
  }

  Future<void> _showDialog(BuildContext context) {
    return showVDialog<void>(
      context: context,
      title: 'Spike dialog',
      content: const Text(
        'Baseline uses showVDialog → FDialog.raw with Vertiege padding.',
      ),
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

  Future<void> _showSheet(BuildContext context) {
    return showFSheet(
      context: context,
      side: FLayout.btt,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: VSpacing.sm),
            const Text('Baseline bottom sheet via FSheet.'),
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
