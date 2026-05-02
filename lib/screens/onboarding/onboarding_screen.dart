import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/resident_provider.dart';
import '../../models/resident.dart';
import '../../widgets/core/tactile_button.dart';
import '../../theme/colors.dart';

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
    context.go('/');
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.08),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Brand ──────────────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.seed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.public, size: 40, color: AppColors.seed),
                ),
                const SizedBox(height: 20),
                Text('Vertiege',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.02,
                  )),
                const SizedBox(height: 4),
                Text('Your tier-gated social universe',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
                const SizedBox(height: 36),

                // ── Avatar Picker ──────────────────────────────
                Text('Choose your avatar',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  )),
                const SizedBox(height: 12),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: _avatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final a = _avatars[index];
                      final selected = _selectedAvatar == a;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = a),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? AppColors.seed : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: AppColors.seed.withValues(alpha: 0.3), blurRadius: 12)]
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/generated/$a.png', fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // ── Name ───────────────────────────────────────
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _bioFocus.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'Display name',
                    hintText: 'How should we call you?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Bio ────────────────────────────────────────
                TextField(
                  controller: _bioController,
                  focusNode: _bioFocus,
                  maxLines: 2,
                  maxLength: 160,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    hintText: 'A few words about yourself...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.edit_note),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Profession ─────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _selectedProfession,
                  decoration: InputDecoration(
                    labelText: 'Profession (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.work_outline),
                    filled: true,
                  ),
                  items: _professions.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.isEmpty ? 'None' : p),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedProfession = v ?? ''),
                ),
                const SizedBox(height: 28),

                // ── CTA ────────────────────────────────────────
                TactileButton(
                  label: _submitting ? 'Entering...' : 'Enter the Worlds',
                  icon: _submitting ? null : Icons.arrow_forward,
                  fullWidth: true,
                  color: AppColors.seed,
                  onPressed: _submitting ? null : _complete,
                ),
                const SizedBox(height: 8),

                // ── Footer ─────────────────────────────────────
                Text(
                  'You will start in Neon District.\nMore worlds unlock as you level up.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
