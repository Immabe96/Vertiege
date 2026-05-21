import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_system.dart';
import '../theme/v_colors.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../models/quiet_hours.dart';
import '../services/quiet_hours_service.dart';

import '../services/invite_service.dart';
import '../services/permission_service.dart';
import '../services/world_service.dart';
import '../ui/buttons/v_button.dart';
import '../services/store_service.dart';
import '../models/world.dart';
import '../config/tiers.dart';
import '../models/invite.dart';
import '../ui/icons/v_icons.dart';
import '../state/channel_provider.dart';
import '../utils/tier_utils.dart';
import '../widgets/core/loading_state.dart';
import '../services/rank_service.dart';
import '../models/rank.dart';
import '../widgets/worlds/banner_generator.dart';
import '../widgets/worlds/world_settings_channels.dart';
import '../widgets/worlds/world_settings_invites.dart';

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

  QuietHours _quietHours = const QuietHours(worldId: '');
  bool _isLoadingQuietHours = false;

  @override
  void initState() {
    super.initState();
    final world = ref.read(worldProvider).worlds[widget.worldId];

    _nameController = TextEditingController(text: world?.name ?? '');
    _descController = TextEditingController(text: world?.description ?? '');
    _selectedIcon = world?.icon ?? 'public';

    _loadInvites();
    _loadMembers();
    _loadQuietHours();
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
      final invites = await InviteService.getInvitesForWorld(widget.worldId);
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
      ref
          .read(worldProvider.notifier)
          .updateWorldSettings(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
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

  Future<void> _loadQuietHours() async {
    setState(() => _isLoadingQuietHours = true);
    try {
      final qh = await QuietHoursService.getQuietHours(widget.worldId);
      if (mounted) {
        setState(() {
          _quietHours = qh;
          _isLoadingQuietHours = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingQuietHours = false);
    }
  }

  Future<void> _saveQuietHours({
    int? startHour,
    int? endHour,
    bool? enabled,
  }) async {
    final updated = _quietHours.copyWith(
      startHour: startHour,
      endHour: endHour,
      enabled: enabled,
    );
    await QuietHoursService.setQuietHours(
      widget.worldId,
      startHour: updated.startHour,
      endHour: updated.endHour,
      enabled: updated.enabled,
    );
    setState(() => _quietHours = updated);
  }

  Future<void> _muteMember(String residentId, String name, int hours) async {
    ref
        .read(residentProvider.notifier)
        .muteResident(widget.worldId, residentId, durationHours: hours);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name muted for $hours hour(s)')));
    }
  }

  Future<void> _banMember(String residentId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ban $name?'),
        content: const Text(
          'They will be removed from the world and cannot rejoin.',
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx, false),
            variant: ButtonVariant.text,
          ),
          VButton(
            onPressed: () => Navigator.pop(ctx, true),
            label: 'Ban',
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(residentProvider.notifier)
          .banResident(widget.worldId, residentId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name banned')));
        _loadMembers();
      }
    }
  }

  void _deleteChannel(String channelId, String name) {
    ref.read(channelProvider.notifier).deleteChannel(widget.worldId, channelId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Channel "$name" deleted')));
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
          decoration: _ghostInputDecoration(hintText: 'New channel name'),
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Rename',
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(channelProvider.notifier)
                    .renameChannel(widget.worldId, channelId, name);
                Navigator.pop(ctx);
              }
            },
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
              decoration: _ghostInputDecoration(hintText: 'Channel name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: _ghostInputDecoration(
                hintText: 'Description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Create',
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(channelProvider.notifier)
                    .createChannel(
                      worldId: widget.worldId,
                      name: name,
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Channel "$name" created')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateInvite() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resident profile found.')),
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
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx, false),
            variant: ButtonVariant.text,
          ),
          VButton(
            onPressed: () => Navigator.pop(ctx, true),
            label: 'Delete',
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        ref.read(residentProvider.notifier).leaveWorld(widget.worldId);
      }

      context.go('/explore');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('World has been deleted.')));
    }
  }

  void _showBannerGenerator() {
    final world = ref.read(worldProvider).worlds[widget.worldId];
    if (world == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(Spacing.md),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark ? VColors.surfaceDark : VColors.surface,
            borderRadius: BorderRadius.circular(RadiusTokens.xl),
            border: Border.all(
              color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Row(
                  children: [
                    const Icon(VIcons.sparkles, color: VColors.tertiary),
                    const SizedBox(width: Spacing.sm),
                    const Expanded(
                      child: Text(
                        'The Herald — Banner Generator',
                        style: TextStyle(
                          fontSize: FontSizes.headlineMd,
                          fontWeight: FontWeights.semiBold,
                          color: VColors.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  child: BannerGenerator(
                    worldId: world.id,
                    worldName: world.name,
                    worldType: world.type,
                    prestige: world.prestige,
                    description: world.description,
                    onSelect: (variant) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Banner Variant ${variant + 1} selected!',
                          ),
                          backgroundColor: VColors.success,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Section header builder --------------------------------------

  Widget _sectionHeader(IconData icon, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: VColors.tertiary, size: IconSizes.md),
        const SizedBox(width: Spacing.sm),
        Text(
          title,
          style: TextStyle(
            fontSize: FontSizes.bodyMd,
            fontWeight: FontWeights.bold,
            color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
          ),
        ),
      ],
    );
  }

  // -- Label above field -------------------------------------------

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: VColors.tertiary),
    );
  }

  // -- Ghost/underline input decoration ----------------------------

  InputDecoration _ghostInputDecoration({
    String? hintText,
    Widget? prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: false,
      border: UnderlineInputBorder(
        borderSide: BorderSide(
          color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
        ),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: VColors.tertiary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final world = ref.watch(worldProvider).worlds[widget.worldId];
    final resident = ref.watch(residentProvider).resident;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(title: const Text('World Settings')),
      body: world == null
          ? const VLoadingList()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  // -- Overview ----------------------------------
                  _Card(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(Icons.info_outline, 'Overview'),
                        const SizedBox(height: Spacing.lg),

                        // World Name
                        _fieldLabel('WORLD NAME'),
                        const SizedBox(height: Spacing.xs),
                        TextFormField(
                          controller: _nameController,
                          decoration: _ghostInputDecoration(
                            hintText: 'Enter a name for your world',
                            prefixIcon: const Icon(VIcons.edit),
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
                        const SizedBox(height: Spacing.lg),

                        // Description
                        _fieldLabel('DESCRIPTION'),
                        const SizedBox(height: Spacing.xs),
                        TextFormField(
                          controller: _descController,
                          decoration: _ghostInputDecoration(
                            hintText: 'What is your world about?',
                            prefixIcon: const Icon(Icons.description),
                          ),
                          textCapitalization: TextCapitalization.sentences,
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
                        const SizedBox(height: Spacing.lg),

                        // Choose an Icon
                        _fieldLabel('CHOOSE AN ICON'),
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
                                  ? Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                              selectedColor: colorScheme.primaryContainer,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(Spacing.sm),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: Spacing.xl),

                        // Publish button
                        SizedBox(
                          width: double.infinity,
                          height: TouchTargets.minimum,
                            child: FilledButton.icon(
                            onPressed: _isSaving ? null : _saveSettings,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: VColors.onTertiary,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _isSaving ? 'SAVING...' : 'PUBLISH CHANGES',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  // -- Banner Generator ----------------------
                  _Card(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(Icons.auto_awesome, 'The Herald'),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Generate AI-assisted banner variants for your world.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                        SizedBox(
                          width: double.infinity,
                          height: TouchTargets.minimum,
                          child: OutlinedButton.icon(
                            onPressed: () => _showBannerGenerator(),
                            icon: const Icon(VIcons.sparkles),
                            label: const Text('Regenerate Banner'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: VColors.tertiary,
                              side: const BorderSide(color: VColors.tertiary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  // -- Channels -----------------------------------
                  _Card(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: WorldSettingsChannels(
                      worldId: widget.worldId,
                      sovereignId: world.sovereignId,
                      residentId: resident?.id,
                      onRename: (id, name) => _renameChannel(id, name),
                      onDelete: (id, name) => _deleteChannel(id, name),
                      onCreate: (ctx) => _showCreateChannel(ctx),
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  // -- Lounge Settings (tier-gated) -------------
                  if (ref.watch(residentProvider.select(
                        (s) => s.resident != null && s.resident!.tier.value >= 3,
                      )))
                    _Card(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(Icons.local_bar, 'Lounge'),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            'Configure lounge access and settings for this world.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: Spacing.md),
                          Text(
                            'Lounge settings coming soon.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (ref.watch(residentProvider.select(
                        (s) => s.resident != null && s.resident!.tier.value >= 3,
                      )))
                    const SizedBox(height: Spacing.md),

                  // -- Governance (tier-gated) -----------------
                  if (ref.watch(residentProvider.select(
                        (s) => s.resident != null && s.resident!.tier.value >= 4,
                      )))
                    _Card(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(Icons.how_to_vote, 'Governance'),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            'Participate in world governance and voting.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: Spacing.md),
                          Text(
                            'Governance voting coming soon.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (ref.watch(residentProvider.select(
                        (s) => s.resident != null && s.resident!.tier.value >= 4,
                      )))
                    const SizedBox(height: Spacing.md),

                  const SizedBox(height: Spacing.md),

                  // -- Invites ------------------------------------
                  _Card(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: WorldSettingsInvites(
                      sovereignId: world.sovereignId,
                      residentId: resident?.id,
                      isGenerating: _isGeneratingInvite,
                      generatedCode: _generatedInviteCode,
                      invites: _invites,
                      isLoadingInvites: _isLoadingInvites,
                      onGenerate: _generateInvite,
                      onCopy: _copyInviteCode,
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  // -- Member Management --------------------------
                  _Card(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(Icons.group, 'Members'),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Manage residents and their standing in this world.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                        if (_isLoadingMembers)
                          const Center(child: VLoadingCard())
                        else if (_members.isEmpty)
                          Text(
                            'No members found',
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          ..._members.map((m) {
                            final residentId =
                                m['resident_id'] as String? ?? '';
                            final name =
                                m['resident_name'] as String? ?? 'Member';
                            final rep = m['rep'] as int? ?? 0;
                            final standing = getStanding(rep);
                            final isSovereign = residentId == world.sovereignId;
                            final isCurrentUser = residentId == resident?.id;
                            final canMod =
                                resident != null &&
                                WorldPermissions.canModerate(
                                  resident,
                                  widget.worldId,
                                  world.sovereignId,
                                );
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: Spacing.sm,
                              ),
                              child: _Card(
                                padding: const EdgeInsets.all(Spacing.md),
                                borderRadius: BorderRadius.circular(
                                  RadiusTokens.xl,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text(
                                        name.substring(0, 1).toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight: FontWeights
                                                            .semiBold,
                                                        color: isDark
                                                            ? VColors.onSurfaceDark
                                                            : VColors.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                if (isSovereign) ...[
                                                  const SizedBox(
                                                    width: Spacing.sm,
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: Spacing.sm,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: VColors.tertiary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          RadiusTokens.pill,
                                                        ),
                                                  ),
                                                    child: Text(
                                                      'SOVEREIGN',
                                                      style: theme
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: VColors
                                                                .onTertiary,
                                                          ),
                                                    ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: Spacing.xs),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: Spacing.sm,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: tierStandingColor(
                                                    standing.level,
                                                  ).withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        RadiusTokens.pill,
                                                      ),
                                                ),
                                                child: Text(
                                                  standing.title,
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color:
                                                            tierStandingColor(
                                                              standing.level,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: Spacing.sm),
                                            Text(
                                              'Rep $rep',
                                              style: theme
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: VColors.tertiary,
                                                  ),
                                            ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isCurrentUser && canMod)
                                      PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: isDark
                                            ? VColors.outlineVariantDark
                                            : VColors.outlineVariant,
                                      ),
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
                                          const PopupMenuItem(
                                            value: 'mute1',
                                            child: Text('Mute 1 hour'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'mute24',
                                            child: Text('Mute 24 hours'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'ban',
                                            child: Text('Ban'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  // -- Quiet Hours ----------------------------------
                  _Card(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(Icons.do_not_disturb, 'Quiet Hours'),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Mute notifications during specific hours.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                        if (_isLoadingQuietHours)
                          const Center(child: VLoadingCard())
                        else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Enable Quiet Hours',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? VColors.onSurfaceDark
                                      : VColors.onSurface,
                                ),
                              ),
                              Switch(
                                value: _quietHours.enabled,
                                onChanged: (v) =>
                                    _saveQuietHours(enabled: v),
                                activeThumbColor: VColors.tertiary,
                              ),
                            ],
                          ),
                          if (_quietHours.enabled) ...[
                            const SizedBox(height: Spacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: VColors.tertiary,
                                        ),
                                      ),
                                      const SizedBox(height: Spacing.xs),
                                      FSelect<int>.rich(
                                        format: (value) => '${value.toString().padLeft(2, '0')}:00',
                                        control: FSelectControl.lifted(
                                          value: _quietHours.startHour,
                                          onChange: (v) { if (v != null) _saveQuietHours(startHour: v); },
                                        ),
                                        children: List.generate(24, (i) => FSelectItem<int>(
                                          value: i,
                                          title: Text('${i.toString().padLeft(2, '0')}:00'),
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: VColors.tertiary,
                                        ),
                                      ),
                                      const SizedBox(height: Spacing.xs),
                                      FSelect<int>.rich(
                                        format: (value) => '${value.toString().padLeft(2, '0')}:00',
                                        control: FSelectControl.lifted(
                                          value: _quietHours.endHour,
                                          onChange: (v) { if (v != null) _saveQuietHours(endHour: v); },
                                        ),
                                        children: List.generate(24, (i) => FSelectItem<int>(
                                          value: i,
                                          title: Text('${i.toString().padLeft(2, '0')}:00'),
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  // -- Boost World (dominion only) -----------------
                  if (world.type == WorldType.dominion) ...[
                    _BoostWorldCard(worldId: widget.worldId),
                    const SizedBox(height: Spacing.md),
                  ],

                  // -- Ranks ----------------------------------------
                  if (resident?.id == world.sovereignId)
                    _RanksSection(
                      worldId: widget.worldId,
                      worldWorldId: widget.worldId,
                    ),

                  const SizedBox(height: Spacing.md),

                  // -- Realm Audit ----------------------------------
                  if (resident?.id == world.sovereignId)
                    ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: VColors.tertiary,
                      ),
                      title: const Text('Realm Audit'),
                      subtitle: const Text(
                        'View moderation history and action logs',
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? VColors.outlineVariantDark
                            : VColors.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.xl),
                      ),
                      onTap: () => context.push(
                        '/audit-log/${widget.worldId}?name=${Uri.encodeComponent(world.name)}',
                      ),
                    ),

                  const SizedBox(height: Spacing.md),

                  // -- Danger Zone ----------------------------------
                  Container(
                    padding: const EdgeInsets.all(Spacing.lg),
                    decoration: BoxDecoration(
                      color: isDark
                          ? VColors.errorContainerDark
                          : VColors.errorContainer,
                      borderRadius: BorderRadius.circular(RadiusTokens.xl),
                      border: Border.all(
                        color: VColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: VColors.error,
                              size: IconSizes.md,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              'Danger Zone',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: VColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Permanently delete this world and all '
                          'associated data. This action cannot be undone.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                        SizedBox(
                          width: double.infinity,
                          height: TouchTargets.minimum,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: VColors.error,
                              side: const BorderSide(color: VColors.error),
                            ),
                            onPressed: resident?.id == world.sovereignId
                                ? _deleteWorld
                                : null,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Delete World'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
    );
  }
}

// ----------------------------------------------------------
// Boost World Card — dominion world level progression via IAP
// ----------------------------------------------------------

class _BoostWorldCard extends ConsumerWidget {
  final String worldId;

  const _BoostWorldCard({required this.worldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldProvider).worlds[worldId];
    if (world == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final currentLevel = getWorldLevel(world.activityScore);
    final nextLevel = (currentLevel + 1).clamp(1, 10);
    final nextThreshold = worldLevelThresholds[nextLevel] ?? 10000;
    final currentThreshold = worldLevelThresholds[currentLevel] ?? 0;
    final progress = world.activityScore - currentThreshold;
    final range = nextThreshold - currentThreshold;
    final progressFraction = range > 0
        ? (progress / range).clamp(0.0, 1.0)
        : 1.0;
    final isMaxLevel = currentLevel >= 10;

    final enabled = StoreService.isEnabled;
    final canBoost = enabled && world.boostsRemaining > 0 && !isMaxLevel;

    return _Card(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rocket_launch,
                color: VColors.tertiary,
                size: IconSizes.md,
              ),
              const SizedBox(width: Spacing.sm),
              Text('Boost World', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Accelerate your world\'s progression with a one-time boost.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Level display
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm + 4,
                  vertical: Spacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                ),
                child: Text(
                  'Level $currentLevel',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeights.bold,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              if (isMaxLevel)
                Text(
                  'Max level reached',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: VColors.tertiary,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    '$progress / $range to Level $nextLevel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? VColors.outlineVariantDark
                          : VColors.outlineVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),

          // Progress bar
          if (!isMaxLevel)
            ClipRRect(
              borderRadius: BorderRadius.circular(RadiusTokens.input),
              child: LinearProgressIndicator(
                value: progressFraction,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),

          const SizedBox(height: Spacing.md),

          // Boost info row
          Row(
            children: [
              Icon(Icons.bolt, size: 16, color: VColors.tertiary),
              const SizedBox(width: 4),
              Text(
                '+${World.boostActivityPoints} activity pts per boost',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                enabled
                    ? '${world.boostsRemaining} of ${World.maxBoostsPerMonth} remaining'
                    : 'Store disabled in this build',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: enabled
                      ? (isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant)
                      : VColors.error,
                  fontWeight: FontWeights.regular,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Boost button
          SizedBox(
            width: double.infinity,
            height: TouchTargets.minimum,
            child: FilledButton.icon(
              onPressed: canBoost
                  ? () => _handleBoost(context, ref, world)
                  : null,
              icon: const Icon(VIcons.rocket, size: 20),
              label: Text(
                enabled ? 'Boost World - \$4.99' : 'Boost unavailable',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: canBoost ? VColors.tertiary : null,
                foregroundColor: canBoost
                    ? (isDark ? VColors.onSurfaceDark : VColors.onTertiary)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBoost(
    BuildContext context,
    WidgetRef ref,
    World world,
  ) async {
    final result = await ref.read(worldProvider.notifier).boostWorld(worldId);

    if (!context.mounted) return;

    switch (result) {
      case StorePurchaseState.purchased:
        final updated = ref.read(worldProvider).worlds[worldId];
        final newLevel = updated != null
            ? getWorldLevel(updated.activityScore)
            : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newLevel != null && newLevel > getWorldLevel(world.activityScore)
                  ? 'Boost applied! World advanced to Level $newLevel!'
                  : 'Boost applied! +${World.boostActivityPoints} activity points.',
            ),
          ),
        );
      case StorePurchaseState.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Boost purchase failed. Please try again.'),
          ),
        );
      case StorePurchaseState.disabled:
        break;
      default:
        break;
    }
  }
}

class _RanksSection extends ConsumerStatefulWidget {
  final String worldId;
  const _RanksSection({required this.worldId, required String worldWorldId});

  @override
  ConsumerState<_RanksSection> createState() => _RanksSectionState();
}

class _RanksSectionState extends ConsumerState<_RanksSection> {
  List<Rank> _ranks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ranks = await RankService.fetchWorldRanks(widget.worldId);
    if (mounted)
      setState(() {
        _ranks = ranks;
        _loading = false;
      });
  }

  void _showCreateDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? VColors.surfaceContainerHighDark
            : VColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.full),
        ),
        title: const Text('Create Rank'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Rank name'),
          autofocus: true,
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Create',
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await RankService.createRank(worldId: widget.worldId, name: name);
              Navigator.pop(ctx);
              _load();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _Card(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.military_tech,
                color: VColors.tertiary,
                size: IconSizes.md,
              ),
              const SizedBox(width: Spacing.sm),
              const Expanded(
                child: Text(
                  'Ranks',
                  style: TextStyle(
                    fontSize: FontSizes.headlineMd,
                    fontWeight: FontWeights.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(VIcons.plus, size: IconSizes.sm),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          if (_loading)
            const Center(child: VLoadingCard())
          else if (_ranks.isEmpty)
            Text(
              'No ranks yet. Create one to assign privileges.',
              style: TextStyle(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            )
          else
            ..._ranks.map(
              (r) => ListTile(
                dense: true,
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _parseHex(r.colorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(r.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: IconSizes.sm),
                  onPressed: () async {
                    await RankService.deleteRank(r.id);
                    _load();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _parseHex(String hex) =>
    Color(int.parse('FF${hex.substring(1)}', radix: 16));

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;

  const _Card({required this.child, this.padding, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: borderRadius ?? BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}
