import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/resident_provider.dart';
import '../../models/resident.dart';
import '../../widgets/core/tactile_button.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _scrollController = ScrollController();
  final _nameFocus = FocusNode();
  final _bioFocus = FocusNode();

  String _selectedAvatar = 'avatar-1';
  String _selectedProfession = '';
  bool _submitting = false;

  static const _avatars = [
    'avatar-1', 'avatar-2', 'avatar-3',
    'avatar-4', 'avatar-5', 'avatar-6',
  ];

  static const _professions = [
    '', 'Aviation', 'Medical', 'Finance', 'Legal',
    'Technology', 'Engineering', 'Arts',
  ];

  bool get _isValid => _nameController.text.trim().length >= 2;

  void _complete() {
    if (!_isValid) {
      HapticFeedback.heavyImpact();
      _nameFocus.requestFocus();
      return;
    }

    setState(() => _submitting = true);

    ref.read(residentProvider.notifier).setResident(
          Resident(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text.trim(),
            bio: _bioController.text.trim(),
            avatarUrl: 'assets/generated/$_selectedAvatar.png',
            profession: _selectedProfession.isEmpty ? null : _selectedProfession,
            tier: ResidentTier.hustlers,
            joinedWorldIds: const ['neon-district'],
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _scrollController.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // ── Hero header ────────────────────────────────
            _HeroHeader(theme: theme),

            // ── Form card ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar picker
                  _buildSectionLabel('Choose your avatar', theme),
                  const SizedBox(height: Spacing.sm + 4),
                  _buildAvatarPicker(cs),
                  const SizedBox(height: Spacing.lg),

                  // Name field
                  _buildSectionLabel('Display name', theme),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _bioFocus.requestFocus(),
                    decoration: InputDecoration(
                      hintText: 'How should we call you?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      prefixIcon: const Icon(Icons.person_outline, size: IconSizes.md),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Bio field
                  _buildSectionLabel('Bio', theme),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: _bioController,
                    focusNode: _bioFocus,
                    maxLines: 2,
                    maxLength: 160,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'A few words about yourself...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      prefixIcon: const Icon(Icons.edit_note, size: IconSizes.md),
                      filled: true,
                      counterStyle: TextStyle(color: cs.outline, fontSize: FontSizes.caption),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Profession dropdown
                  _buildSectionLabel('Profession', theme),
                  const SizedBox(height: Spacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProfession,
                    decoration: InputDecoration(
                      hintText: 'Select a profession',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      prefixIcon: const Icon(Icons.work_outline, size: IconSizes.md),
                      filled: true,
                    ),
                    items: _professions.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.isEmpty ? 'None' : p),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedProfession = v ?? ''),
                  ),
                  const SizedBox(height: Spacing.xl),

                  // CTA
                  TactileButton(
                    label: _submitting ? 'Entering...' : 'Enter the Worlds',
                    icon: _submitting ? null : Icons.arrow_forward,
                    fullWidth: true,
                    color: AppColors.seed,
                    onPressed: _submitting ? null : _complete,
                  ),
                  const SizedBox(height: Spacing.md),

                  // Footer
                  Text(
                    'You will start in Neon District.\nMore worlds unlock as you level up.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                      height: LineHeight.relaxed,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildAvatarPicker(ColorScheme cs) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: _avatars.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final a = _avatars[index];
          final selected = _selectedAvatar == a;
          return GestureDetector(
            onTap: () => setState(() => _selectedAvatar = a),
            child: AnimatedContainer(
              duration: AnimDurations.fast,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.seed : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selected
                    ? [BoxShadow(
                        color: AppColors.seed.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                      )]
                    : null,
              ),
              child: ClipOval(
                child: Image.asset('assets/generated/$a.png', fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Hero Header — adapted from Travel App landing page pattern
// ──────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final ThemeData theme;

  const _HeroHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: Spacing.xxl + Spacing.lg,
        bottom: Spacing.xl + Spacing.lg,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/generated/bg-onboarding.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkSurfaceBase.withValues(alpha: 0.55),
              AppColors.darkSurfaceBase.withValues(alpha: 0.7),
              AppColors.darkSurfaceBase.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.seed.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(RadiusTokens.xl),
                ),
                child: const Icon(
                  Icons.public,
                  size: 40,
                  color: AppColors.seed,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Welcome to\nVertiege',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: LetterSpacing.heading,
                  height: LineHeight.tight,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: Spacing.sm + 4),
              Text(
                'Your tier-gated social universe.\nChoose your identity and enter the worlds.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  height: LineHeight.relaxed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
