import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_system.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';

import '../services/invite_service.dart';
import '../services/permission_service.dart';
import '../services/world_service.dart';
import '../config/tiers.dart';
import '../models/invite.dart';
import '../models/channel.dart';
import '../state/channel_provider.dart';
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

  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    final world = ref.read(worldProvider).worlds[widget.worldId];

    _nameController = TextEditingController(text: world?.name ?? '');
    _descController = TextEditingController(text: world?.description ?? '');
    _selectedIcon = world?.icon ?? 'public';

    _loadInvites();
    _loadMembers();
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

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    try {
      final members = await WorldService.getMembers(widget.worldId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _muteMember(String residentId, String name, int hours) async {
    ref.read(residentProvider.notifier).muteResident(widget.worldId, residentId, hours);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name muted for $hours hour(s)')),
      );
    }
  }

  Future<void> _banMember(String residentId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ban $name?'),
        content: const Text('They will be removed from the world and cannot rejoin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(residentProvider.notifier).banResident(widget.worldId, residentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name banned')));
        _loadMembers();
      }
    }
  }

  void _deleteChannel(String channelId, String name) {
    ref.read(channelProvider.notifier).deleteChannel(widget.worldId, channelId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Channel "$name" deleted')),
    );
  }

  void _renameChannel(String channelId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Channel'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'New channel name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(channelProvider.notifier).renameChannel(widget.worldId, channelId, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showCreateChannel(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Channel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Channel name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(channelProvider.notifier).createChannel(
                  worldId: widget.worldId,
                  name: name,
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Channel "$name" created')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
    final resident = ref.watch(residentProvider).resident;

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

                  // ── Channels ──────────────────────────────────────
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
                              Text('Channels', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text('Manage channels for this world.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: Spacing.md),
                          Consumer(
                            builder: (context, ref, _) {
                              final channels = ref.watch(channelProvider).channelsByWorld[widget.worldId] ?? [];
                              return Column(
                                children: [
                                  ...channels.map((ch) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      ch.channelType == ChannelType.announcement
                                          ? Icons.campaign
                                          : ch.channelType == ChannelType.feed
                                              ? Icons.dynamic_feed
                                              : Icons.tag,
                                      size: 20,
                                    ),
                                    title: Text('# ${ch.name}'),
                                    subtitle: Text(ch.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: ch.isDefault
                                        ? Text('Default', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline))
                                        : IconButton(
                                            icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                                            onPressed: () => _deleteChannel(ch.id, ch.name),
                                          ),
                                    onTap: ch.isDefault ? null : () => _renameChannel(ch.id, ch.name),
                                  )),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showCreateChannel(context),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add Channel'),
                                    ),
                                  ),
                                ],
                              );
                            },
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

                  // ── Member Management ────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.group, color: colorScheme.primary, size: 20),
                              const SizedBox(width: Spacing.sm),
                              Text('Members', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text('Manage residents and their standing in this world.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: Spacing.md),
                          if (_isLoadingMembers)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ))
                          else if (_members.isEmpty)
                            Text('No members found', style: theme.textTheme.bodyMedium)
                          else
                            ..._members.map((m) {
                              final residentId = m['resident_id'] as String? ?? '';
                              final name = m['resident_name'] as String? ?? 'Member';
                              final rep = m['rep'] as int? ?? 0;
                              final standing = getStanding(rep);
                              final isSovereign = residentId == world.sovereignId;
                              final isCurrentUser = residentId == resident?.id;
                              final canMod = resident != null && WorldPermissions.canModerate(resident, widget.worldId, world.sovereignId);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Text(name.substring(0, 1).toUpperCase()),
                                ),
                                title: Row(
                                  children: [
                                    Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
                                    if (isSovereign) ...[
                                      const SizedBox(width: 4),
                                      Icon(Icons.auto_awesome, size: 12, color: colorScheme.primary),
                                    ],
                                  ],
                                ),
                                subtitle: Text('${standing.title} · Rep $rep'),
                                trailing: isCurrentUser || !canMod
                                    ? null
                                    : PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, size: 18, color: colorScheme.outline),
                                        onSelected: (action) {
                                          switch (action) {
                                            case 'mute1':
                                              _muteMember(residentId, name, 1);
                                            case 'mute24':
                                              _muteMember(residentId, name, 24);
                                            case 'ban':
                                              _banMember(residentId, name);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(value: 'mute1', child: Text('Mute 1 hour')),
                                          const PopupMenuItem(value: 'mute24', child: Text('Mute 24 hours')),
                                          const PopupMenuItem(value: 'ban', child: Text('Ban')),
                                        ],
                                      ),
                              );
                            }),
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
