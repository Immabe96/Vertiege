import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/v_tokens.dart';
import '../spike_backend.dart';
import '../spike_section_widgets.dart';
import '../spike_settings_model.dart';

/// Candidate B — Material 3 only, no shadcn package.
class Material3SpikePage extends StatelessWidget {
  final SpikeSettingsModel model;
  final ValueChanged<SpikeBackend> onBackendChanged;
  final SpikeBackend backend;

  const Material3SpikePage({
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
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.pop()),
            title: const Text('UI Spike'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(VSpacing.md),
            children: [
              _backendPicker(context),
              const SizedBox(height: VSpacing.md),
              const SpikeSectionHeader(title: 'About'),
              SpikeSectionGroup(
                children: [
                  ListTile(
                    title: const Text('Wave 0 Material 3'),
                    subtitle: Text(
                      'Plan C — no third-party UI package',
                      style: Theme.of(context).textTheme.bodySmall,
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
                    subtitle: const Text('Opens AlertDialog'),
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
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    value: model.notificationsEnabled,
                    onChanged: model.setNotifications,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration),
                    title: const Text('Haptics'),
                    value: model.hapticsEnabled,
                    onChanged: model.setHaptics,
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.md),
              const SpikeSectionHeader(title: 'Actions'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Material 3 SnackBar')),
                    );
                  },
                  child: const Text('Show snackbar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _backendPicker(BuildContext context) {
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
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => onBackendChanged(candidate),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _showDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spike dialog'),
        content: const Text(
          'Candidate B uses Material AlertDialog with theme ColorScheme.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: VSpacing.sm),
            const Text('Material showModalBottomSheet with drag handle.'),
            const SizedBox(height: VSpacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
