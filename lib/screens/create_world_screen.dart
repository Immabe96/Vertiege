import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/subscription_service.dart';
import '../theme/design_system.dart';
import '../theme/colors.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../state/achievement_provider.dart';
import '../widgets/core/glass_panel.dart';

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
  SubscriptionTier _subscriptionTier = SubscriptionTier.resident;
  bool _tierLoaded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _loadSubscriptionTier();
  }

  Future<void> _loadSubscriptionTier() async {
    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      final tier = await SubscriptionService.getTier(resident.id);
      if (mounted) {
        setState(() {
          _subscriptionTier = tier;
          _tierLoaded = true;
        });
      }
    } else {
      if (mounted) {
        setState(() => _tierLoaded = true);
      }
    }
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

  static const _requiredTierLevel = 2; // High Roller or above (500+ XP)
  static const _requiredXp = 500;

  bool get _canCreateWorld {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return false;
    return resident.tier.value >= _requiredTierLevel;
  }

  bool get _isAtSubscriptionLimit {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return false;
    final benefits = SubscriptionService.getBenefits(_subscriptionTier);
    final worldLimit = benefits['worldLimit'] as int;
    return resident.joinedWorldIds.length >= worldLimit;
  }

  /// Builds the subscription upgrade prompt when world limit is reached.
  Widget _buildSubscriptionLockedView(BuildContext context) {
    final theme = Theme.of(context);
    final benefits = SubscriptionService.getBenefits(_subscriptionTier);
    final tierLabel = benefits['label'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Dominion World'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          GlassPanel(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              children: [
                Icon(
                  Icons.diamond_outlined,
                  size: 64,
                  color: AppColors.tertiary,
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'World Limit Reached',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Your $tierLabel subscription allows you to create up to ${benefits['worldLimit']} worlds. Upgrade to unlock more.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/subscription'),
                    icon: const Icon(Icons.star),
                    label: const Text('UPGRADE SUBSCRIPTION'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      foregroundColor: AppColors.onTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Patrician: up to 10 worlds. Sovereign Elite: unlimited.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedView(BuildContext context) {
    final theme = Theme.of(context);
    final totalXp = ref.watch(achievementProvider).totalXp;
    final progress = (totalXp / _requiredXp).clamp(0.0, 1.0);
    final remaining = _requiredXp - totalXp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Dominion World'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          GlassPanel(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.tertiary,
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'High Roller Required',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Only residents who have reached High Roller tier (500+ XP) can create custom dominion worlds.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                // ── Progress bar ──────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 16,
                    backgroundColor: AppColors.glassBackground,
                    valueColor: const AlwaysStoppedAnimation(AppColors.tertiary),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  '$totalXp / $_requiredXp XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (remaining > 0) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '$remaining XP to go',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.xl),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/achievements'),
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('Go to Achievements'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      foregroundColor: AppColors.onTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Submit achievements and earn XP to unlock world creation.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Level gate: must be High Roller (tier >= 2) ─────────────
    if (!_canCreateWorld) {
      return _buildLockedView(context);
    }

    // ── Subscription gate: world limit ──────────────────────────
    if (_tierLoaded && _isAtSubscriptionLimit) {
      return _buildSubscriptionLockedView(context);
    }

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
            GlassPanel(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.public, color: AppColors.primary, size: 20),
                      const SizedBox(width: Spacing.sm),
                      Text('World Details', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.ink),
                    decoration: const InputDecoration(
                      labelText: 'World Name',
                      hintText: 'Enter a name for your world',
                      hintStyle: TextStyle(color: AppColors.inkMuted),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.edit_note),
                      filled: true,
                      fillColor: AppColors.glassBackground,
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
                    style: const TextStyle(color: AppColors.ink),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What is your world about?',
                      hintStyle: TextStyle(color: AppColors.inkMuted),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.description),
                      filled: true,
                      fillColor: AppColors.glassBackground,
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
                              ? AppColors.onPrimaryContainer
                              : AppColors.inkMuted,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedIcon = choice.id);
                          }
                        },
                        avatar: isSelected
                            ? Icon(Icons.check_circle, size: 16, color: AppColors.onPrimaryContainer)
                            : null,
                        selectedColor: AppColors.primaryContainer,
                        backgroundColor: AppColors.glassBackground,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.glassBorder,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(Spacing.sm),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.md),

            // ── Channels ───────────────────────────────────────────
            GlassPanel(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tag, color: AppColors.primary, size: 20),
                      const SizedBox(width: Spacing.sm),
                      Text('Default Channels', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'These channels will be created for your world.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
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
                      activeTrackColor: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // ── Submit — gold CTA ──────────────────────────────────
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
                          color: AppColors.ink,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(_isCreating ? 'Creating...' : 'Create World'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  foregroundColor: AppColors.onTertiary,
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
