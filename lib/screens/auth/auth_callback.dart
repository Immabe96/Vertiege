import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../state/resident_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishSignIn());
  }

  Future<void> _finishSignIn() async {
    try {
      final session = await AuthService.getSession().timeout(
        const Duration(seconds: 8),
      );
      if (!mounted) return;

      if (session == null) {
        setState(() => _error = 'We could not finish signing you in.');
        return;
      }

      await ref
          .read(residentProvider.notifier)
          .loadResident()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;

      final resident = ref.read(residentProvider).resident;
      if (resident == null) {
        context.go('/onboarding');
      } else if (!resident.gateCompleted) {
        context.go('/the-gate');
      } else {
        context.go('/');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Sign-in timed out. Please try again.');
    }
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
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.seed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      RadiusTokens.cardFeatured,
                    ),
                  ),
                  child: const Icon(
                    Icons.public,
                    size: IconSizes.xl,
                    color: AppColors.seed,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Vertiege',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeights.bold,
                    letterSpacing: LetterSpacing.display,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                if (_error == null)
                  const SizedBox(
                    width: IconSizes.lg,
                    height: IconSizes.lg,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  Icon(
                    Icons.error_outline,
                    size: IconSizes.xl,
                    color: colorScheme.error,
                  ),
                const SizedBox(height: Spacing.lg),
                Text(
                  _error ?? 'Signing you in...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: Spacing.lg),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to Sign In'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
