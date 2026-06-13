import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/world_navigation.dart';
import '../models/world.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_access_service.dart';
import '../services/subscription_service.dart';
import 'package:vertiege/ui/ui.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../state/world_provider.dart';
import '../state/resident_provider.dart';
import '../state/achievement_provider.dart';
import '../widgets/worlds/dominion_type_picker.dart';
import '../config/world_charter_templates.dart';

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
  String? _charterTemplateId;
  DominionType? _selectedDominionType;
  final Map<String, bool> _channelToggles = {
    for (final c in _defaultChannels) c.key: true,
  };
  bool _isCreating = false;
  bool _tierLoaded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _nameController.addListener(_onFormChanged);
    _descController.addListener(_onFormChanged);
    _loadSubscriptionTier();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSubscriptionTier() async {
    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      await SubscriptionService.getTier(resident.id);
      if (mounted) {
        setState(() {
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

  bool get _isFormReady {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    return name.length >= 3 &&
        desc.length >= 10 &&
        _selectedDominionType != null;
  }

  Future<void> _submit() async {
    if (_selectedDominionType == null) {
      VFeedback.showMessage(
        context,
        'Choose a dominion type before creating your world.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      VFeedback.showMessage(
        context,
        'Check world name and description — fix any errors above.',
      );
      return;
    }

    final resident = ref.read(residentProvider).resident;
    if (resident == null) {
      VFeedback.showMessage(
        context,
        'No resident profile found. Please create one first.',
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final worldId = await ref
          .read(worldProvider.notifier)
          .createWorld(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            sovereignId: resident.id,
            sovereignName: resident.name,
            icon: _selectedIcon,
            dominionType: _selectedDominionType?.name,
            worldCurrencyName: _selectedDominionType?.defaultCurrencyName,
            tags: _selectedDominionType?.defaultTags,
          );

      await ref.read(residentProvider.notifier).joinWorld(worldId);

      if (mounted) {
        _nameController.clear();
        _descController.clear();
        setState(() {
          _selectedIcon = 'public';
          _selectedDominionType = null;
          for (final key in _channelToggles.keys) {
            _channelToggles[key] = true;
          }
          _isCreating = false;
        });
        context.go(exploreWorldPath(worldId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        final message = e is PostgrestException
            ? 'Failed: ${e.message} (${e.code})'
            : 'Failed to create world: $e';
        VFeedback.showError(
          context,
          message,
          duration: const Duration(seconds: 8),
        );
      }
    }
  }

  static const _requiredXp = 500;
  bool get _isSuperuser => AdminAccessService.isCurrentSessionSuperuser();

  bool get _canCreateWorld {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return false;
    return AdminAccessService.canCreateWorld(tierValue: resident.tier.value);
  }

  bool get _isAtWorldCreationLimit {
    if (_isSuperuser) return false;
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return false;
    final worldState = ref.read(worldProvider);
    final ownedWorlds = worldState.worlds.values
        .where((w) => w.sovereignId == resident.id)
        .length;
    return ownedWorlds >= resident.worldCreationLimit;
  }

  /// Builds the world limit reached view when user has used all creation slots.
  Widget _buildWorldLimitReachedView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resident = ref.read(residentProvider).resident;
    final limit = resident?.worldCreationLimit ?? 1;

    final nextTierLimit = switch (resident?.tier.value) {
      null => 2,
      1 => 2,
      2 => 3,
      3 => 4,
      4 => 5,
      _ => null,
    };

    return VHubPage(
      title: 'Create Dominion World',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.md),
        children: [
          VSurfaceCard(
            padding: const EdgeInsets.all(VSpacing.xl),
            child: Column(
              children: [
                Icon(Icons.diamond_outlined, size: 64, color: VColors.tertiary),
                const SizedBox(height: VSpacing.md),
                Text(
                  'World Limit Reached',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: VColors.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: VSpacing.sm),
                Text(
                  'You have created $limit world(s). Upgrade your tier to unlock more.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VSpacing.xl),
                if (nextTierLimit != null) ...[
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/achievements'),
                      icon: const Icon(VIcons.trophy),
                      label: const Text('Go to Achievements'),
                      style: FilledButton.styleFrom(
                        backgroundColor: VColors.tertiary,
                        foregroundColor: VColors.onTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Text(
                    'Reach the next tier to create up to $nextTierLimit worlds.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalXp = ref.watch(achievementProvider).totalXp;
    final progress = (totalXp / _requiredXp).clamp(0.0, 1.0);
    final remaining = _requiredXp - totalXp;

    return VHubPage(
      title: 'Create Dominion World',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.md),
        children: [
          VSurfaceCard(
            padding: const EdgeInsets.all(VSpacing.xl),
            child: Column(
              children: [
                Icon(Icons.lock_outline, size: 64, color: VColors.tertiary),
                const SizedBox(height: VSpacing.md),
                Text(
                  'High Roller Required',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: VColors.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: VSpacing.sm),
                Text(
                  'Only residents who have reached High Roller tier (500+ XP) can create custom dominion worlds.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VSpacing.lg),
                // ── Progress bar ──────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(VRadius.md),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 16,
                    backgroundColor: isDark
                        ? VColors.glassBackgroundDark
                        : VColors.glassBackground,
                    valueColor: const AlwaysStoppedAnimation(VColors.tertiary),
                  ),
                ),
                const SizedBox(height: VSpacing.sm),
                Text(
                  '$totalXp / $_requiredXp XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: VColors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (remaining > 0) ...[
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    '$remaining XP to go',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: VSpacing.xl),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/achievements'),
                    icon: const Icon(VIcons.trophy),
                    label: const Text('Go to Achievements'),
                    style: FilledButton.styleFrom(
                      backgroundColor: VColors.tertiary,
                      foregroundColor: VColors.onTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: VSpacing.sm),
                Text(
                  'Submit achievements and earn XP to unlock world creation.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Level gate: must be High Roller (tier >= 2) ─────────────
    if (!_canCreateWorld) {
      return _buildLockedView(context);
    }

    // ── World creation limit gate ────────────────────────────────
    if (_tierLoaded && _isAtWorldCreationLimit) {
      return _buildWorldLimitReachedView(context);
    }

    return VHubPage(
      title: 'Create Dominion World',
      showBack: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(VSpacing.md),
          children: [
            // ── World Details ──────────────────────────────────────
            VSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('World details', style: theme.textTheme.titleMedium),
                  const SizedBox(height: VSpacing.md),
                  VTextFormField(
                    controller: _nameController,
                    label: const Text('World name'),
                    hint: 'At least 3 characters',
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
                  const SizedBox(height: VSpacing.md),
                  Text('Charter template', style: theme.textTheme.labelLarge),
                  const SizedBox(height: VSpacing.sm),
                  Wrap(
                    spacing: VSpacing.xs,
                    runSpacing: VSpacing.xs,
                    children: worldCharterTemplates.map((t) {
                      final selected = _charterTemplateId == t.id;
                      return FilterChip(
                        label: Text(t.label),
                        selected: selected,
                        onSelected: (on) {
                          setState(() {
                            if (!on) {
                              _charterTemplateId = null;
                              return;
                            }
                            _charterTemplateId = t.id;
                            _descController.text = t.descriptionSeed;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: VSpacing.md),
                  VTextFormField(
                    controller: _descController,
                    label: const Text('Description'),
                    hint: 'What is your world about?',
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
                  const SizedBox(height: VSpacing.md),
                  Text('Icon', style: theme.textTheme.labelLarge),
                  const SizedBox(height: VSpacing.sm),
                  Wrap(
                    spacing: VSpacing.xs,
                    runSpacing: VSpacing.xs,
                    children: _iconChoices.map((choice) {
                      final isSelected = _selectedIcon == choice.id;
                      return VIconButton(
                        semanticsLabel: 'World icon ${choice.id}',
                        selected: isSelected,
                        onPressed: () =>
                            setState(() => _selectedIcon = choice.id),
                        child: Icon(choice.icon, size: VIconSize.lgMd),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: VSpacing.md),

            VSurfaceCard(
              child: DominionTypePicker(
                selected: _selectedDominionType,
                onSelected: (type) =>
                    setState(() => _selectedDominionType = type),
              ),
            ),

            const SizedBox(height: VSpacing.md),

            VSurfaceCard(
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Starting channels',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${_channelToggles.values.where((v) => v).length} selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                  initiallyExpanded: false,
                  children: _defaultChannels
                      .map(
                        (channel) => Padding(
                          padding: const EdgeInsets.only(bottom: VSpacing.xs),
                          child: Row(
                            children: [
                              Expanded(child: Text(channel.label)),
                              VSwitch(
                                value: _channelToggles[channel.key]!,
                                onChanged: (v) => setState(
                                  () => _channelToggles[channel.key] = v,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            const SizedBox(height: VSpacing.xl),

            // ── Submit — gold CTA ──────────────────────────────────
            VButton(
              label: 'Create World',
              isFullWidth: true,
              isLoading: _isCreating,
              icon: Icon(VIcons.plus, size: VIconSize.md),
              onPressed: _isFormReady ? _submit : null,
            ),

            const SizedBox(height: VSpacing.xl),
          ],
        ),
      ),
    );
  }
}
