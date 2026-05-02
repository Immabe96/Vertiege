import 'package:flutter/material.dart';
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

  void _complete() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    ref.read(residentProvider.notifier).setResident(
          Resident(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            bio: _bioController.text.trim(),
            tier: ResidentTier.hustlers,
          ),
        );
    // Let state propagate before navigating
    Future.microtask(() {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.public, size: 72, color: AppColors.seed),
              const SizedBox(height: 20),
              Text('Welcome to Vertiege', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Choose your name. Step into the worlds.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bioController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Bio (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit_note)),
              ),
              const SizedBox(height: 24),
              TactileButton(
                label: 'Enter the Worlds',
                icon: Icons.arrow_forward,
                fullWidth: true,
                color: AppColors.seed,
                onPressed: _complete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
