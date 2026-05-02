import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_system.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';

final _iconChoices = const [
  (icon: Icons.public, id: 'public'),
  (icon: Icons.landscape, id: 'landscape'),
  (icon: Icons.science, id: 'science'),
  (icon: Icons.account_balance, id: 'account_balance'),
  (icon: Icons.rocket, id: 'rocket'),
  (icon: Icons.palette, id: 'palette'),
  (icon: Icons.music_note, id: 'music_note'),
  (icon: Icons.code, id: 'code'),
];

final _defaultChannels = const [
  (label: '#general', key: 'general'),
  (label: '#lounge', key: 'lounge'),
  (label: '#introductions', key: 'introductions'),
];

class CreateWorldScreen extends ConsumerStatefulWidget {
  const CreateWorldScreen({super.key});

  @override
  ConsumerState<CreateWorldScreen> createState() => _CreateWorldScreenState();
}

class _CreateWorldScreenState extends ConsumerState<CreateWorldScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  String _selectedIcon = 'public';
  final Map<String, bool> _channelToggles = {
    for (final c in _defaultChannels) c.key: true,
  };
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resident profile found. Please create one first.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final worldId = await ref.read(worldProvider.notifier).createWorld(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            sovereignId: resident.id,
            sovereignName: resident.name,
            icon: _selectedIcon,
          );

      ref.read(residentProvider.notifier).joinWorld(worldId);

      if (mounted) {
        _nameController.clear();
        _descController.clear();
        setState(() {
          _selectedIcon = 'public';
          for (final key in _channelToggles.keys) {
            _channelToggles[key] = true;
          }
          _isCreating = false;
        });
        context.go('/explore/$worldId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create world: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Dominion World'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            // ── World Details ──────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.public, color: colorScheme.primary, size: 20),
                        const SizedBox(width: Spacing.sm),
                        Text('World Details', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'World Name',
                        hintText: 'Enter a name for your world',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                      textCapitalization: TextCapitalization.words,
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'World name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is your world about?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      maxLength: 500,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        if (value.trim().length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.md),
                    Text('Choose an Icon', style: theme.textTheme.labelLarge),
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: _iconChoices.map((choice) {
                        final isSelected = _selectedIcon == choice.id;
                        return ChoiceChip(
                          label: Icon(
                            choice.icon,
                            size: 24,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedIcon = choice.id);
                            }
                          },
                          avatar: isSelected
                              ? Icon(Icons.check_circle, size: 16, color: colorScheme.onPrimaryContainer)
                              : null,
                          selectedColor: colorScheme.primaryContainer,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(Spacing.sm),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Spacing.md),

            // ── Channels ───────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tag, color: colorScheme.primary, size: 20),
                        const SizedBox(width: Spacing.sm),
                        Text('Default Channels', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'These channels will be created for your world.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    ..._defaultChannels.map(
                      (channel) => SwitchListTile(
                        title: Text(channel.label),
                        value: _channelToggles[channel.key]!,
                        onChanged: (value) {
                          setState(() => _channelToggles[channel.key] = value);
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: colorScheme.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // ── Submit ─────────────────────────────────────────────
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _isCreating ? null : _submit,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(_isCreating ? 'Creating...' : 'Create World'),
              ),
            ),

            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }
}
