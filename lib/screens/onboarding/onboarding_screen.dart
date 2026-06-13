import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/professions.dart';
import '../../config/tiers.dart';
import '../../models/resident.dart';
import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/invite_navigation.dart';
import '../../services/supabase.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/id_generator.dart';
import 'the_gate_screen.dart';
import 'package:vertiege/ui/ui.dart';
import '../../services/onboarding_funnel_prefs.dart';
import '../../services/world_service.dart';
import '../../ui/overlays/v_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  File? _avatarFile;
  String _selectedProfession = '';

  static final _professions = professionPickerOptions();

  // Gate state
  final Map<_GateInterest, int> _gateScores = {};
  bool _gateSubmitting = false;

  bool get _isProfileValid => _nameController.text.trim().length >= 2;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep = _currentStep + 1);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep = _currentStep - 1);
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final file = File(picked.path);
    final saved = await _saveToLocal(file);
    setState(() => _avatarFile = saved);
  }

  Future<File> _saveToLocal(File source) async {
    final dir = Directory('${Directory.systemTemp.path}/vertiege');
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = File('${dir.path}/avatar_${generateId()}.jpg');
    await source.copy(dest.path);
    return dest;
  }

  Future<void> _completeProfile() async {
    if (!_isProfileValid) {
      HapticFeedback.heavyImpact();
      return;
    }
    _nextStep();
  }

  Future<void> _submitGate() async {
    if (_gateScores.isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _gateSubmitting = true);

    final topInterest = _gateScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Get user ID from Supabase auth directly (resident may not exist yet for new users)
    final userId =
        ref.read(residentProvider).resident?.id ??
        maybeSupabase()?.auth.currentUser?.id ??
        '';
    if (userId.isEmpty) {
      setState(() => _gateSubmitting = false);
      if (mounted) {
        VFeedback.showMessage(
          context,
          'Session expired. Please sign in again.',
        );
      }
      return;
    }

    // Ensure worlds are loaded before finding default worlds
    final worldState = ref.read(worldProvider);
    if (worldState.worlds.isEmpty && worldState.isLoading) {
      try {
        await ref
            .read(worldProvider.notifier)
            .loadWorlds()
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Continue with whatever worlds are available
      }
    }

    // New users only get starter worlds — verification/tier gates unlock the rest
    final starterWorlds = ref
        .read(worldProvider)
        .worlds
        .values
        .where((w) => w.isDefault)
        .map((w) => w.id)
        .toList();

    // If no default worlds found in remote config, fall back to config defaults
    if (starterWorlds.isEmpty) {
      starterWorlds.addAll(
        worldsConfig.values.where((w) => w.isDefault).map((w) => w.id),
      );
    }

    ref
        .read(residentProvider.notifier)
        .setResident(
          Resident(
            id: userId,
            name: _nameController.text.trim(),
            bio: _bioController.text.trim(),
            avatarUrl: _avatarFile?.path ?? '',
            profession: _selectedProfession.isEmpty
                ? null
                : _selectedProfession,
            tier: ResidentTier.hustlers,
            joinedWorldIds: starterWorlds,
            onboardingCompleted: true,
            gateCompleted: true,
            gateInterest: topInterest.name,
          ),
        );

    await markGateCompleted();

    if (mounted) {
      _nextStep();
    }
  }

  Future<void> _enterApp() async {
    await OnboardingFunnelPrefs.markJustFinishedOnboarding();
    unawaited(AnalyticsService.logEvent(AnalyticsEvents.onboardingCompleted));
    unawaited(AnalyticsService.logEvent(AnalyticsEvents.gateCompleted));
    final route = await routeAfterAuth(ref, feedbackContext: context);
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? VCommuneColors.surfaceTertiary
          : VCommuneColors.surfaceSecondaryLight,
      body: SafeArea(
        child: Column(
          children: [
            // Progress header
            Padding(
              padding: const EdgeInsets.all(VSpacing.lg),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _prevStep,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStep == 0
                              ? 'Create your identity'
                              : _currentStep == 1
                              ? 'Find your path'
                              : 'Welcome in',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: VFontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: VSpacing.sm),
                        _ProgressDots(currentStep: _currentStep),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _ProfileTab(
                    nameController: _nameController,
                    bioController: _bioController,
                    avatarFile: _avatarFile,
                    selectedProfession: _selectedProfession,
                    professions: _professions,
                    onPickAvatar: _pickAvatar,
                    onProfessionChanged: (p) =>
                        setState(() => _selectedProfession = p),
                    onNext: _completeProfile,
                    isValid: _isProfileValid,
                  ),
                  _GateTab(
                    scores: _gateScores,
                    onScoreChanged: (interest, score) {
                      setState(() => _gateScores[interest] = score);
                    },
                    onSubmit: _submitGate,
                    isSubmitting: _gateSubmitting,
                  ),
                  _WorldTab(onEnter: _enterApp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int currentStep;

  const _ProgressDots({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= currentStep;
        return Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? VColors.primaryLight : VColors.primary)
                  : (isDark
                        ? VColors.surfaceContainerHighDark
                        : VColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(VRadius.xxs),
            ),
          ),
        );
      }),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController bioController;
  final File? avatarFile;
  final String selectedProfession;
  final List<String> professions;
  final Future<void> Function(ImageSource) onPickAvatar;
  final ValueChanged<String> onProfessionChanged;
  final VoidCallback onNext;
  final bool isValid;

  const _ProfileTab({
    required this.nameController,
    required this.bioController,
    required this.avatarFile,
    required this.selectedProfession,
    required this.professions,
    required this.onPickAvatar,
    required this.onProfessionChanged,
    required this.onNext,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar
          Center(
            child: GestureDetector(
              onTap: () => _showAvatarOptions(context),
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: VColors.tertiary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: VColors.tertiary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                      image: avatarFile != null
                          ? DecorationImage(
                              image: FileImage(avatarFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: avatarFile == null
                          ? (isDark
                                ? VColors.surfaceContainerDark
                                : VColors.surfaceContainer)
                          : null,
                    ),
                    child: avatarFile == null
                        ? Icon(
                            Icons.person_outline,
                            size: 40,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? VColors.surfaceContainerHighDark
                            : VColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: VIconSize.sm,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpacing.xl),

          // Name
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              labelText: 'Display name',
              hintText: 'How should we call you?',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: VSpacing.lg),

          // Bio
          TextField(
            controller: bioController,
            maxLines: 2,
            maxLength: 160,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText: 'A few words about yourself...',
              prefixIcon: const Icon(Icons.edit_note),
              filled: true,
              fillColor: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: VSpacing.xl),

          // Profession
          Text(
            'Profession (optional)',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: VFontWeight.semiBold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Wrap(
            spacing: VSpacing.sm,
            runSpacing: VSpacing.sm,
            children: professions.map((p) {
              final selected = selectedProfession == p;
              final label = p.isEmpty ? 'None' : p;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => onProfessionChanged(p),
                selectedColor: isDark
                    ? VColors.primaryContainerDark
                    : VColors.primaryContainer,
                labelStyle: TextStyle(
                  color: selected
                      ? (isDark ? VColors.primaryLight : VColors.primary)
                      : (Theme.of(context).colorScheme.onSurface),
                  fontWeight: selected ? VFontWeight.semiBold : null,
                ),
                backgroundColor: isDark
                    ? VColors.surfaceContainerDark
                    : VColors.surfaceContainerLow,
                side: BorderSide(
                  color: selected
                      ? (isDark
                            ? VColors.primaryLight.withValues(alpha: 0.4)
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.4))
                      : (isDark
                            ? VColors.outlineVariantDark
                            : Theme.of(context).colorScheme.outlineVariant),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: VSpacing.xxl),

          // Next button
          VButton(
            label: 'Continue to The Gate',
            isFullWidth: true,
            onPressed: isValid ? onNext : null,
          ),
          const SizedBox(height: VSpacing.lg),
          Text(
            'Self-declared — verification coming later.\nAll users start at the bottom and rank up.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showVSheet(
      context,
      Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                onPickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                onPickAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      maxSize: 0.35,
    );
  }
}

enum _GateInterest { execute, foundation, craft, capital, governance }

class _GateTab extends StatefulWidget {
  final Map<_GateInterest, int> scores;
  final void Function(_GateInterest, int) onScoreChanged;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const _GateTab({
    required this.scores,
    required this.onScoreChanged,
    required this.onSubmit,
    required this.isSubmitting,
  });

  @override
  State<_GateTab> createState() => _GateTabState();
}

class _GateTabState extends State<_GateTab> {
  int _currentIndex = 0;

  static const _questions = [
    (
      text: 'What excites you most?',
      options: [
        ('Move fast and ship', _GateInterest.execute),
        ('Build lasting habits', _GateInterest.foundation),
        ('Master your craft', _GateInterest.craft),
      ],
    ),
    (
      text: 'What would you study first?',
      options: [
        ('Markets & leverage', _GateInterest.capital),
        ('Leadership & rules', _GateInterest.governance),
        ('Tools & execution', _GateInterest.execute),
      ],
    ),
    (
      text: 'Pick your weekend project',
      options: [
        ('Build a side hustle', _GateInterest.execute),
        ('Design a system', _GateInterest.foundation),
        ('Create something beautiful', _GateInterest.craft),
      ],
    ),
    (
      text: 'What kind of world do you want?',
      options: [
        ('Fast-paced & competitive', _GateInterest.capital),
        ('Structured & fair', _GateInterest.governance),
        ('Creative & expressive', _GateInterest.craft),
      ],
    ),
    (
      text: 'Your superpower is...',
      options: [
        ('Getting things done', _GateInterest.execute),
        ('Staying consistent', _GateInterest.foundation),
        ('Deep expertise', _GateInterest.craft),
        ('Understanding money', _GateInterest.capital),
        ('Bringing people together', _GateInterest.governance),
      ],
    ),
  ];

  void _selectOption(_GateInterest interest) {
    final scores = Map<_GateInterest, int>.from(widget.scores);
    scores[interest] = (scores[interest] ?? 0) + 1;
    widget.onScoreChanged(interest, scores[interest]!);

    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark
                ? VColors.surfaceContainerHighDark
                : VColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation(
              isDark ? VColors.primaryLight : VColors.primary,
            ),
            minHeight: 4,
          ),
          const SizedBox(height: VSpacing.xl),

          // Question number
          Text(
            'Question ${_currentIndex + 1} of ${_questions.length}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.sm),

          // Question
          Text(
            question.text,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xl),

          // Options
          ...question.options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.md),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectOption(option.$2),
                  borderRadius: BorderRadius.circular(VRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.all(VSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark
                          ? VColors.surfaceContainerDark
                          : VColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(VRadius.lg),
                      border: Border.all(
                        color: isDark
                            ? VColors.outlineVariantDark
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? VColors.primaryContainerDark
                                        : VColors.primaryContainer)
                                    .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(VRadius.md),
                          ),
                          child: Icon(
                            _iconForInterest(option.$2),
                            color: isDark
                                ? VColors.primaryLight
                                : Theme.of(context).colorScheme.primary,
                            size: VIconSize.lg,
                          ),
                        ),
                        const SizedBox(width: VSpacing.md),
                        Expanded(
                          child: Text(
                            option.$1,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: VFontWeight.medium,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: VIconSize.sm),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: VSpacing.xl),

          // Submit button (shown on last question)
          if (_currentIndex == _questions.length - 1)
            VButton(
              label: 'Reveal Your World',
              isFullWidth: true,
              isLoading: widget.isSubmitting,
              onPressed: widget.isSubmitting ? null : widget.onSubmit,
            ),
        ],
      ),
    );
  }

  IconData _iconForInterest(_GateInterest interest) {
    switch (interest) {
      case _GateInterest.execute:
        return Icons.bolt;
      case _GateInterest.foundation:
        return Icons.spa;
      case _GateInterest.craft:
        return Icons.workspace_premium;
      case _GateInterest.capital:
        return Icons.diamond;
      case _GateInterest.governance:
        return Icons.shield;
    }
  }
}

class _WorldTab extends ConsumerWidget {
  final VoidCallback onEnter;

  const _WorldTab({required this.onEnter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;

    final interestLabel = resident?.gateInterest != null
        ? _interestLabel(resident!.gateInterest!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: VSpacing.xxl),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color:
                  (isDark
                          ? VColors.primaryContainerDark
                          : VColors.primaryContainer)
                      .withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.public,
              size: 40,
              color: isDark ? VColors.primaryLight : VColors.primary,
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          Text(
            interestLabel != null
                ? 'Your path: $interestLabel'
                : 'Welcome to Vertiege',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            _starterWorldsCopy(ref),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          VButton(
            label: 'Open Nexus',
            isFullWidth: true,
            icon: const Icon(Icons.home_outlined),
            onPressed: onEnter,
          ),
          const SizedBox(height: VSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {
              final id = resident?.joinedWorldIds
                  .where(WorldService.isRemoteWorldId)
                  .firstOrNull;
              if (id != null) {
                context.push(exploreWorldPath(id));
              } else {
                context.push('/explore');
              }
            },
            icon: const Icon(Icons.public),
            label: const Text('Visit your world'),
          ),
          const SizedBox(height: VSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.push('/achievements/submit'),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Submit proof'),
          ),
          const SizedBox(height: VSpacing.lg),
          Text(
            'Recommended path: profile → join worlds → Nexus feed → achievement proof.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _interestLabel(String interest) {
    return switch (interest) {
      'execute' => 'Execution',
      'foundation' => 'Foundation',
      'craft' => 'Craft',
      'capital' => 'Capital',
      'governance' => 'Governance',
      _ => 'Explorer',
    };
  }

  String _starterWorldsCopy(WidgetRef ref) {
    final resident = ref.read(residentProvider).resident;
    final worlds = ref.read(worldProvider).worlds;
    final names = <String>[];
    if (resident != null) {
      for (final id in resident.joinedWorldIds) {
        final w = worlds[id];
        if (w != null) names.add(w.name);
      }
    }
    if (names.isEmpty) {
      return 'You\'re set up with starter worlds. More unlock as you verify '
          'your profession or level up.';
    }
    if (names.length == 1) {
      return 'You start in ${names.first}. Submit proof and earn reputation '
          'there, then explore more worlds.';
    }
    final head = names.take(2).join(' and ');
    final extra = names.length > 2 ? ' (+${names.length - 2} more)' : '';
    return 'You start in $head$extra. Submit achievement proof in your worlds, '
        'then browse Nexus for updates.';
  }
}
