import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase.dart';
import '../../state/resident_provider.dart';
import '../../models/resident.dart';
import '../../widgets/core/tactile_button.dart';
import '../../widgets/core/glass_panel.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../utils/id_generator.dart';

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
  final _picker = ImagePicker();

  File? _avatarFile;
  String _selectedProfession = '';
  bool _submitting = false;

  static const _professions = [
    '',
    'Aviation',
    'Medical',
    'Finance',
    'Legal',
    'Technology',
    'Engineering',
    'Arts',
  ];

  bool get _isValid => _nameController.text.trim().length >= 2;

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

  void _complete() {
    if (!_isValid) {
      HapticFeedback.heavyImpact();
      _nameFocus.requestFocus();
      return;
    }

    setState(() => _submitting = true);

    final userId = maybeSupabase()?.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in again to finish setting up your profile.',
          ),
        ),
      );
      context.go('/login');
      return;
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
            joinedWorldIds: const ['neon-district'],
            onboardingCompleted: true,
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            const _HeroHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Spacing.lg),

                  // ── Profile section — glass panel ────────
                  GlassPanel(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile picture
                        _buildSectionLabel('Profile picture', theme),
                        const SizedBox(height: Spacing.sm + 4),
                        _buildAvatarSection(theme),
                        const SizedBox(height: Spacing.lg),

                        // Name field
                        _buildSectionLabel('Display name', theme),
                        const SizedBox(height: Spacing.sm),
                        TextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: AppColors.ink),
                          onSubmitted: (_) => _bioFocus.requestFocus(),
                          decoration: const InputDecoration(
                            hintText: 'How should we call you?',
                            hintStyle: TextStyle(color: AppColors.inkMuted),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.glassBorder,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.glassBorder,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              size: IconSizes.md,
                            ),
                            filled: true,
                            fillColor: AppColors.glassBackground,
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
                          style: const TextStyle(color: AppColors.ink),
                          decoration: InputDecoration(
                            hintText: 'A few words about yourself...',
                            hintStyle: const TextStyle(
                              color: AppColors.inkMuted,
                            ),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.glassBorder,
                              ),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.glassBorder,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                            prefixIcon: const Icon(
                              Icons.edit_note,
                              size: IconSizes.md,
                            ),
                            filled: true,
                            fillColor: AppColors.glassBackground,
                            counterStyle: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: FontSizes.caption,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.lg),

                  // ── Profession — glass panel ─────────────
                  GlassPanel(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionLabel('Profession', theme),
                        const SizedBox(height: Spacing.sm),
                        _buildProfessionSelector(theme),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          'Self-declared — verification coming in a future update.\nAll users start at the bottom and rank up through activity.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.inkMuted,
                            height: LineHeight.body,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.xl),

                  // ── CTA — gold ───────────────────────────
                  TactileButton(
                    label: _submitting ? 'Entering...' : 'Enter the Worlds',
                    icon: _submitting ? null : Icons.arrow_forward,
                    fullWidth: true,
                    color: AppColors.tertiary,
                    textColor: AppColors.onTertiary,
                    onPressed: _submitting ? null : _complete,
                  ),
                  const SizedBox(height: Spacing.md),

                  Text(
                    'You will start in Neon District.\nMore worlds unlock as you level up.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.inkMuted,
                      height: LineHeight.body,
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
        fontWeight: FontWeights.bold,
        color: AppColors.inkSecondary,
      ),
    );
  }

  Widget _buildAvatarSection(ThemeData theme) {
    if (_avatarFile != null) {
      return Center(
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.tertiary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tertiary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
                image: DecorationImage(
                  image: FileImage(_avatarFile!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => setState(() => _avatarFile = null),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOverlay,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder, width: 2),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildPickButton(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            onTap: () => _pickAvatar(ImageSource.camera),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _buildPickButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onTap: () => _pickAvatar(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildPickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.glassBackground,
      borderRadius: BorderRadius.circular(RadiusTokens.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadiusTokens.card),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.tertiary, size: 28),
              const SizedBox(height: Spacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.inkSecondary,
                  fontSize: FontSizes.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _professions.map((p) {
        final selected = _selectedProfession == p;
        final label = p.isEmpty ? 'None' : p;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => setState(() => _selectedProfession = p),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? AppColors.onPrimary : AppColors.inkSecondary,
            fontSize: FontSizes.body,
          ),
          backgroundColor: AppColors.glassBackground,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.glassBorder,
          ),
        );
      }).toList(),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: Spacing.xxl + Spacing.lg,
        bottom: Spacing.xl + Spacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.canvas],
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
                color: AppColors.tertiary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
              ),
              child: const Icon(
                Icons.public,
                size: 40,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Welcome to\nVertiege',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeights.bold,
                letterSpacing: LetterSpacing.display,
                height: LineHeight.display,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: Spacing.sm + 4),
            Text(
              'Your tier-gated social universe.\nSet your identity and enter the worlds.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.7),
                height: LineHeight.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
