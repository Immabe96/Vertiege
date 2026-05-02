import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_system.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';

import '../services/invite_service.dart';
import '../models/invite.dart';
import '../utils/date_format.dart';

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

class WorldSettingsScreen extends ConsumerStatefulWidget {
  final String worldId;

  const WorldSettingsScreen({super.key, required this.worldId});

  @override
  ConsumerState<WorldSettingsScreen> createState() =>
      _WorldSettingsScreenState();
}

class _WorldSettingsScreenState extends ConsumerState<WorldSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  String _selectedIcon = 'public';
  bool _isSaving = false;
  bool _isGeneratingInvite = false;
  String? _generatedInviteCode;

  List<WorldInvite> _invites = [];
  bool _isLoadingInvites = false;

  @override
  void initState() {
    super.initState();
    final world = ref.read(worldProvider).worlds[widget.worldId];

    _nameController = TextEditingController(text: world?.name ?? '');
    _descController = TextEditingController(text: world?.description ?? '');
    _selectedIcon = world?.icon ?? 'public';

    _loadInvites();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadInvites() async {
    setState(() => _isLoadingInvites = true);
    try {
      final invites =
          await InviteService.getInvitesForWorld(widget.worldId);
      if (mounted) {
        setState(() {
          _invites = invites;
          _isLoadingInvites = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingInvites = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      ref.read(worldProvider.notifier).updateWorldSettings(
            worldId: widget.worldId,
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            icon: _selectedIcon,
          );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('World settings updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    }
  }

  Future<void> _generateInvite() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No resident profile found.')),
      );
      return;
    }

    setState(() => _isGeneratingInvite = true);

    try {
      final invite = await InviteService.createInvite(
        worldId: widget.worldId,
        createdBy: resident.id,
      );

      if (mounted && invite != null) {
        setState(() {
          _generatedInviteCode = invite.code;
          _isGeneratingInvite = false;
        });
        await _loadInvites();
      } else if (mounted) {
        setState(() => _isGeneratingInvite = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingInvite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invite: $e')),
        );
      }
    }
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied to clipboard.')),
    );
  }

  Future<void> _deleteWorld() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete World?'),
        content: const Text(
          'This action is irreversible. All channels, messages, and '
          'data associated with this world will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        ref
            .read(residentProvider.notifier)
            .leaveWorld(widget.worldId);
      }

      context.go('/explore');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('World has been deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final world = ref.watch(worldProvider).worlds[widget.worldId];

    return Scaffold(
      appBar: AppBar(
        title: const Text('World Settings'),
      ),
      body: world == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  // ── Overview ─────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: colorScheme.primary, size: 20),
                              const SizedBox(width: Spacing.sm),
                              Text('Overview',
                                  style: theme.textTheme.titleMedium),
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
                            textCapitalization:
                                TextCapitalization.sentences,
                            maxLines: 3,
                            maxLength: 500,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Description is required';
                              }
                              if (value.trim().length < 10) {
                                return 'Description must be at least '
                                    '10 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: Spacing.md),
                          Text('Choose an Icon',
                              style: theme.textTheme.labelLarge),
                          const SizedBox(height: Spacing.sm),
                          Wrap(
                            spacing: Spacing.sm,
                            runSpacing: Spacing.sm,
                            children: _iconChoices.map((choice) {
                              final isSelected =
                                  _selectedIcon == choice.id;
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
                                    setState(
                                        () => _selectedIcon = choice.id);
                                  }
                                },
                                avatar: isSelected
                                    ? Icon(Icons.check_circle,
                                        size: 16,
                                        color:
                                            colorScheme.onPrimaryContainer)
                                    : null,
                                selectedColor: colorScheme.primaryContainer,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(Spacing.sm),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: Spacing.lg),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _saveSettings,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                  _isSaving ? 'Saving...' : 'Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  // ── Invites ──────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_add,
                                  color: colorScheme.primary, size: 20),
                              const SizedBox(width: Spacing.sm),
                              Text('Invites',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            'Create and manage invitation codes '
                            'for this world.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: Spacing.md),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isGeneratingInvite ? null : _generateInvite,
                              icon: _isGeneratingInvite
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.link),
                              label: Text(_isGeneratingInvite
                                  ? 'Generating...'
                                  : 'Generate Invite'),
                            ),
                          ),
                          if (_generatedInviteCode != null) ...[
                            const SizedBox(height: Spacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                        text: _generatedInviteCode),
                                    decoration: const InputDecoration(
                                      labelText: 'Invite Code',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.vpn_key),
                                    ),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      letterSpacing: 2,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Spacing.sm),
                                IconButton.filled(
                                  onPressed: () =>
                                      _copyInviteCode(_generatedInviteCode!),
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Copy code',
                                ),
                              ],
                            ),
                          ],
                          if (_isLoadingInvites) ...[
                            const SizedBox(height: Spacing.md),
                            const Center(
                                child: CircularProgressIndicator()),
                          ] else if (_invites.isNotEmpty) ...[
                            const SizedBox(height: Spacing.md),
                            const Divider(),
                            const SizedBox(height: Spacing.sm),
                            Text('Existing Invites',
                                style: theme.textTheme.labelLarge),
                            const SizedBox(height: Spacing.sm),
                            ..._invites.map((invite) {
                              final expired = invite.isExpired;
                              final exhausted = invite.isExhausted;
                              final valid = invite.isValid;
                              final displayDate =
                                  invite.createdAt > 0
                                      ? formatTimestamp(invite.createdAt)
                                      : 'Unknown date';
                              final usesLabel = invite.maxUses > 0
                                  ? '${invite.uses}/${invite.maxUses} uses'
                                  : '${invite.uses} uses (unlimited)';

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  valid
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  color: valid
                                      ? colorScheme.primary
                                      : colorScheme.error,
                                ),
                                title: Text(
                                  invite.code,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    letterSpacing: 1,
                                  ),
                                ),
                                subtitle: Text(
                                  '$usesLabel  ·  $displayDate'
                                  '${expired ? '  ·  Expired' : ''}'
                                  '${exhausted ? '  ·  Exhausted' : ''}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () =>
                                      _copyInviteCode(invite.code),
                                  tooltip: 'Copy code',
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  // ── Danger Zone ──────────────────────────────────
                  Card(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(RadiusTokens.md),
                      side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: colorScheme.error, size: 20),
                              const SizedBox(width: Spacing.sm),
                              Text('Danger Zone',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                          color: colorScheme.error)),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            'Permanently delete this world and all '
                            'associated data. This action cannot be undone.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: Spacing.md),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                side: BorderSide(
                                    color: colorScheme.error),
                              ),
                              onPressed: _deleteWorld,
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('Delete World'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
    );
  }
}
