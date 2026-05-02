import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';
import '../widgets/core/fade_in.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          FadeIn(
            delayMs: 0,
            child: ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme'),
              subtitle: Text(themeState.scheme.name),
              trailing: SegmentedButton<ThemeScheme>(
                segments: const [
                  ButtonSegment(value: ThemeScheme.system, label: Text('Auto')),
                  ButtonSegment(value: ThemeScheme.light, label: Text('Light')),
                  ButtonSegment(value: ThemeScheme.dark, label: Text('Dark')),
                ],
                selected: {themeState.scheme},
                onSelectionChanged: (scheme) {
                  ref.read(themeProvider.notifier).setScheme(scheme.first);
                },
              ),
            ),
          ),
          const Divider(),
          FadeIn(
            delayMs: 60,
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Create Backup'),
              subtitle: const Text('Export all app data'),
              onTap: () async {
                await BackupService.createBackup();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup created successfully')),
                  );
                }
              },
            ),
          ),
          FadeIn(
            delayMs: 90,
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore Backup'),
              subtitle: const Text('Import previously saved data'),
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paste backup JSON to restore')),
                );
              },
            ),
          ),
          const Divider(),
          FadeIn(
            delayMs: 120,
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              title: Text('Reset All Data', style: TextStyle(color: theme.colorScheme.error)),
              subtitle: const Text('Clear all local data and start fresh'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset all data?'),
                    content: const Text('This will clear all local data and cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await StorageService.clearAll();
                  ref.read(themeProvider.notifier).setScheme(ThemeScheme.system);
                  if (context.mounted) context.go('/onboarding');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
