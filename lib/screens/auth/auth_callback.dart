import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class AuthCallbackScreen extends StatelessWidget {
  const AuthCallbackScreen({super.key});

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
                    borderRadius: BorderRadius.circular(RadiusTokens.xl),
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
                    fontWeight: FontWeight.w800,
                    letterSpacing: LetterSpacing.heading,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                const SizedBox(
                  width: IconSizes.lg,
                  height: IconSizes.lg,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Signing you in...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
