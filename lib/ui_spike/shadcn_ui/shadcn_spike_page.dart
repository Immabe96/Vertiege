import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../theme/v_tokens.dart';
import '../spike_backend.dart';
import '../spike_section_widgets.dart';
import '../spike_settings_model.dart';
import 'vertiege_shad_theme.dart';

/// Candidate A — shadcn_ui leaf widgets + Material hub shell.
class ShadcnSpikePage extends StatelessWidget {
  final SpikeSettingsModel model;
  final ValueChanged<SpikeBackend> onBackendChanged;
  final SpikeBackend backend;

  const ShadcnSpikePage({
    super.key,
    required this.model,
    required this.onBackendChanged,
    required this.backend,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ShadTheme(
      data: VertiegeShadTheme.forBrightness(brightness),
      child: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final shad = ShadTheme.of(context);
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.pop()),
              title: const Text('UI Spike'),
            ),
            body: ListView(
              padding: const EdgeInsets.all(VSpacing.md),
              children: [
                _backendPicker(context, shad),
                const SizedBox(height: VSpacing.md),
                const SpikeSectionHeader(title: 'About'),
                SpikeSectionGroup(
                  children: [
                    ListTile(
                      title: Text('Wave 0 shadcn_ui', style: shad.textTheme.p),
                      subtitle: Text(
                        'ShadTheme + Material scaffold',
                        style: shad.textTheme.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.md),
                const SpikeSectionHeader(title: 'Account'),
                SpikeSectionGroup(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profile preview'),
                      subtitle: const Text('Opens ShadDialog'),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => _showDialog(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Appearance sheet'),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => _showSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.md),
                const SpikeSectionHeader(title: 'Preferences'),
                SpikeSectionGroup(
                  children: [
                    _switchRow(
                      context,
                      label: 'Notifications',
                      icon: Icons.notifications_outlined,
                      value: model.notificationsEnabled,
                      onChanged: model.setNotifications,
                    ),
                    _switchRow(
                      context,
                      label: 'Haptics',
                      icon: Icons.vibration,
                      value: model.hapticsEnabled,
                      onChanged: model.setHaptics,
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.md),
                const SpikeSectionHeader(title: 'Actions'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
                  child: ShadButton(
                    width: double.infinity,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'shadcn spike — use ShadToast in Wave A',
                          ),
                        ),
                      );
                    },
                    child: const Text('Show feedback'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _backendPicker(BuildContext context, ShadThemeData shad) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SpikeSectionHeader(title: 'Backend'),
        SpikeSectionGroup(
          children: [
            for (final candidate in SpikeBackend.values)
              ListTile(
                leading: const Icon(Icons.layers_outlined),
                title: Text(candidate.label),
                trailing: backend == candidate
                    ? Icon(Icons.check, color: shad.colorScheme.primary)
                    : null,
                onTap: () => onBackendChanged(candidate),
              ),
          ],
        ),
      ],
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: ShadSwitch(value: value, onChanged: onChanged),
    );
  }

  Future<void> _showDialog(BuildContext context) {
    return showShadDialog<void>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Spike dialog'),
        description: const Text(
          'Candidate A uses showShadDialog + ShadDialog with VertiegeShadTheme.',
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showSheet(BuildContext context) {
    return showShadSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Appearance', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: VSpacing.sm),
            Text(
              'Bottom sheet via showShadSheet.',
              style: ShadTheme.of(context).textTheme.muted,
            ),
            const SizedBox(height: VSpacing.md),
            ShadButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
