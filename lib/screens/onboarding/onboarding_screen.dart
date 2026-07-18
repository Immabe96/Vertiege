import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/onboarding_funnel.dart';
import '../../config/professions.dart';
import '../../config/tiers.dart';
import '../../models/resident.dart';
import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/supabase.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/id_generator.dart';
import '../../widgets/auth/auth_prestige_shell.dart';
import 'the_gate_screen.dart';
import 'package:vertiege/ui/ui.dart';
import '../../services/onboarding_funnel_prefs.dart';
import '../../services/world_service.dart';

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

  Future<void> _enterApp([String? path]) async {
    await OnboardingFunnelPrefs.markJustFinishedOnboarding();
    unawaited(AnalyticsService.logEvent(AnalyticsEvents.onboardingCompleted));
    unawaited(AnalyticsService.logEvent(AnalyticsEvents.gateCompleted));
    if (!mounted) return;
    final resident = ref.read(residentProvider).resident;
    final hasWorld =
        resident != null && OnboardingFunnel.hasJoinedWorld(resident);
    // Forced path: worlds → chat → proof. Nexus is not the first landing.
    final dest = path ?? (hasWorld ? '/chat' : '/worlds');
    if (mounted) context.go(dest);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: PrestigeNoir.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, VSpacing.md, 28, 0),
              child: _ProgressDots(currentStep: _currentStep),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, VSpacing.lg, 28, 0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _prevStep,
                      color: PrestigeNoir.foreground,
                    ),
                  Expanded(
                    child: Text(
                      _currentStep == 0
                          ? 'Create your identity'
                          : _currentStep == 1
                          ? 'Find your path'
                          : 'Welcome in',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: VFontWeight.bold,
                        color: PrestigeNoir.foreground,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (_currentStep > 0)
                    const SizedBox(width: 48),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? VColors.brand
                    : isDone
                    ? PrestigeNoir.accentSoft
                    : PrestigeNoir.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '🎭',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 56),
          ),
          const SizedBox(height: VSpacing.lg),
          Text(
            'Who are you?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: VFontWeight.bold,
              color: PrestigeNoir.foreground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            'Choose your avatar and handle. You can change these later.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: PrestigeNoir.muted,
              height: 1.55,
            ),
          ),
          const SizedBox(height: VSpacing.xl),
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
                      border: Border.all(
                        color: isValid ? VColors.brand : PrestigeNoir.borderLight,
                        width: 2,
                      ),
                      color: avatarFile == null
                          ? PrestigeNoir.surfaceRaised
                          : null,
                      image: avatarFile != null
                          ? DecorationImage(
                              image: FileImage(avatarFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarFile == null
                        ? const Icon(
                            Icons.person_outline,
                            size: 40,
                            color: PrestigeNoir.muted,
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
                        color: PrestigeNoir.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: PrestigeNoir.borderLight),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: VIconSize.sm,
                        color: VColors.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpacing.xl),
          const PrestigeOnboardingFieldLabel(label: 'Display name'),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: PrestigeNoir.foreground),
            decoration: _prestigeInputDecoration(hint: 'Choose your handle'),
          ),
          const SizedBox(height: VSpacing.lg),
          const PrestigeOnboardingFieldLabel(label: 'Bio'),
          TextField(
            controller: bioController,
            maxLines: 2,
            maxLength: 160,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: PrestigeNoir.foreground),
            decoration: _prestigeInputDecoration(
              hint: 'A few words about yourself...',
            ),
          ),
          const SizedBox(height: VSpacing.xl),
          Text(
            'Profession (optional)',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: VFontWeight.semiBold,
              color: PrestigeNoir.muted,
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
                selectedColor: PrestigeNoir.accentSoft,
                labelStyle: TextStyle(
                  color: selected ? VColors.brand : PrestigeNoir.foreground,
                  fontWeight: selected ? VFontWeight.semiBold : null,
                ),
                backgroundColor: PrestigeNoir.surfaceRaised,
                side: BorderSide(
                  color: selected ? VColors.brand : PrestigeNoir.border,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: VSpacing.xxl),
          AuthPrestigePrimaryButton(
            label: 'Continue to The Gate',
            isLoading: false,
            onPressed: isValid ? onNext : null,
          ),
          const SizedBox(height: VSpacing.lg),
          Text(
            'Self-declared — verification coming later.\nAll users start at the bottom and rank up.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: PrestigeNoir.mutedDim,
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onPickAvatar(ImageSource.camera);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: VSpacing.lg,
                    vertical: VSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt),
                      SizedBox(width: VSpacing.md),
                      Expanded(child: Text('Camera')),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onPickAvatar(ImageSource.gallery);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: VSpacing.lg,
                    vertical: VSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.photo_library),
                      SizedBox(width: VSpacing.md),
                      Expanded(child: Text('Gallery')),
                    ],
                  ),
                ),
              ),
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
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: PrestigeNoir.border,
              valueColor: const AlwaysStoppedAnimation(VColors.brand),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: VSpacing.xl),
          Text(
            'Question ${_currentIndex + 1} of ${_questions.length}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: PrestigeNoir.muted,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: VFontWeight.bold,
              color: PrestigeNoir.foreground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: VSpacing.xl),
          ...question.options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.md),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectOption(option.$2),
                  borderRadius: BorderRadius.circular(VRadius.bento),
                  child: Container(
                    padding: const EdgeInsets.all(VSpacing.lg),
                    decoration: BoxDecoration(
                      color: PrestigeNoir.surfaceRaised,
                      borderRadius: BorderRadius.circular(VRadius.bento),
                      border: Border.all(color: PrestigeNoir.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: PrestigeNoir.accentSoft,
                            borderRadius: BorderRadius.circular(VRadius.md),
                          ),
                          child: Icon(
                            _iconForInterest(option.$2),
                            color: VColors.brand,
                            size: VIconSize.lg,
                          ),
                        ),
                        const SizedBox(width: VSpacing.md),
                        Expanded(
                          child: Text(
                            option.$1,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: VFontWeight.medium,
                              color: PrestigeNoir.foreground,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: VIconSize.sm,
                          color: PrestigeNoir.mutedDim,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: VSpacing.xl),
          if (_currentIndex == _questions.length - 1)
            AuthPrestigePrimaryButton(
              label: 'Reveal Your World',
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
  final void Function([String? path]) onEnter;

  const _WorldTab({required this.onEnter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;
    final hasWorld =
        resident != null && OnboardingFunnel.hasJoinedWorld(resident);

    final interestLabel = resident?.gateInterest != null
        ? _interestLabel(resident!.gateInterest!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: VSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: VSpacing.xl),
          Icon(
            hasWorld ? Icons.chat_bubble_outline : Icons.public,
            size: 56,
            color: VColors.brand,
          ),
          const SizedBox(height: VSpacing.lg),
          Text(
            interestLabel != null
                ? 'Your path: $interestLabel'
                : 'Welcome to Vertiege',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: VFontWeight.bold,
              color: PrestigeNoir.foreground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            _starterWorldsCopy(ref),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: PrestigeNoir.muted,
              height: 1.55,
            ),
          ),
          const SizedBox(height: VSpacing.xl),
          AuthPrestigePrimaryButton(
            label: hasWorld ? 'Open Chat' : 'Browse worlds',
            isLoading: false,
            onPressed: onEnter,
          ),
          const SizedBox(height: VSpacing.sm),
          if (hasWorld)
            VButton(
              label: 'Visit your world',
              variant: ButtonVariant.outlined,
              isFullWidth: true,
              icon: const Icon(Icons.public),
              onPressed: () {
                final id = resident.joinedWorldIds
                    .where(WorldService.isRemoteWorldId)
                    .firstOrNull;
                if (id != null) {
                  onEnter(exploreWorldPath(id));
                } else {
                  onEnter('/worlds');
                }
              },
            )
          else
            VButton(
              label: 'Open Chat later',
              variant: ButtonVariant.outlined,
              isFullWidth: true,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => onEnter('/chat'),
            ),
          const SizedBox(height: VSpacing.sm),
          VButton(
            label: 'Submit proof',
            variant: ButtonVariant.outlined,
            isFullWidth: true,
            icon: const Icon(Icons.verified_outlined),
            onPressed: () => context.push('/achievements/submit'),
          ),
          const SizedBox(height: VSpacing.md),
          VButton(
            label: 'Skip to Nexus',
            variant: ButtonVariant.text,
            isFullWidth: true,
            onPressed: () => onEnter('/'),
          ),
          const SizedBox(height: VSpacing.lg),
          Text(
            'Next: join a world → open Chat → submit proof.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: PrestigeNoir.mutedDim,
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
      return 'Browse Worlds, join one, then open Chat. '
          'Submit achievement proof when you\'re ready to rise.';
    }
    if (names.length == 1) {
      return 'You start in ${names.first}. Open Chat to meet the room, '
          'then submit proof to earn XP.';
    }
    final head = names.take(2).join(' and ');
    final extra = names.length > 2 ? ' (+${names.length - 2} more)' : '';
    return 'You start in $head$extra. Open Chat, then submit proof — '
        'Nexus fills as you share standing.';
  }
}

InputDecoration _prestigeInputDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: PrestigeNoir.surfaceRaised,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: VSpacing.lg,
      vertical: 14,
    ),
    hintStyle: const TextStyle(color: PrestigeNoir.mutedDim),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(color: PrestigeNoir.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(color: PrestigeNoir.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(color: VColors.brand, width: 1.5),
    ),
  );
}

class PrestigeOnboardingFieldLabel extends StatelessWidget {
  const PrestigeOnboardingFieldLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: VFontSize.labelMd,
          fontWeight: VFontWeight.medium,
          color: PrestigeNoir.muted,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
