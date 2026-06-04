import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/invite_navigation.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import 'package:forui/forui.dart';
import '../../theme/v_tokens.dart';
import '../../utils/brand_assets.dart';
import '../../ui/buttons/v_button.dart';

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
        context.go('/onboarding');
      } else {
        final route = await routeAfterAuth(ref, feedbackContext: context);
        if (!mounted) return;
        context.go(route);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    color: (isDark
                            ? VColors.glassBackgroundDark
                            : VColors.glassBackground)
                        .withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(
                      VRadius.md,
                    ),
                    border: Border.all(
                      color: isDark
                          ? VColors.glassBorderDark
                          : VColors.glassBorder,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.xs),
                    child: Image.asset(
                      brandMarkAsset(context),
                      fit: BoxFit.contain,
                      cacheWidth: 128,
                    ),
                  ),
                ),
                const SizedBox(height: VSpacing.lg),
                Text(
                  'Vertiege',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                    fontWeight: VFontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: VSpacing.xl),
                if (_error == null)
                  const SizedBox(
                    width: VIconSize.lg,
                    height: VIconSize.lg,
                    child: FCircularProgress(),
                  )
                else
                  Icon(
                    Icons.error_outline,
                    size: VIconSize.xl,
                    color: colorScheme.error,
                  ),
                const SizedBox(height: VSpacing.lg),
                Text(
                  _error ?? 'Signing you in...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: VSpacing.lg),
                  VButton(
                    label: 'Back to Sign In',
                    onPressed: () => context.go('/login'),
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
