import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/invite_service.dart';
import '../../state/resident_provider.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/auth/auth_error_card.dart';
import '../../widgets/auth/auth_fields.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/brand_assets.dart';
import '../../ui/icons/v_icons.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  bool get _isValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) &&
        password.length >= 8 &&
        confirm == password;
  }

  String? _passwordError() {
    final password = _passwordController.text;
    if (password.isNotEmpty && password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _confirmPasswordError() {
    final confirm = _confirmPasswordController.text;
    if (confirm.isNotEmpty && confirm != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_isValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      await ref.read(residentProvider.notifier).loadResident();
      if (!mounted) return;

      final resident = ref.read(residentProvider).resident;
      if (resident != null && resident.gateCompleted) {
        final invitePath = await InviteService.takePendingInvitePath();
        if (!mounted) return;
        context.go(invitePath ?? '/');
      } else {
        context.go('/onboarding');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: 80),

              FadeIn(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? VColors.glassBackgroundDark
                        : VColors.glassBackground,
                    borderRadius: BorderRadius.circular(VRadius.xl),
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
              ),
              const SizedBox(height: VSpacing.lg),
              FadeIn(
                delayMs: 100,
                child: Text(
                  'Vertiege',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: VFontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              FadeIn(
                delayMs: 150,
                child: Text(
                  'Create your account',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: VSpacing.xxl),

              Container(
                padding: const EdgeInsets.all(VSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? VColors.surfaceContainerDark
                      : VColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(VRadius.xl),
                  border: Border.all(
                    color: isDark
                        ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                        : VColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      AuthErrorCard(message: _errorMessage!),
                      const SizedBox(height: VSpacing.lg),
                    ],

                    FadeIn(
                      delayMs: 200,
                      child: AuthEmailField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        enabled: !_isLoading,
                        onChanged: () => setState(() => _errorMessage = null),
                        onSubmit: (_) => _passwordFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(height: VSpacing.md),

                    FadeIn(
                      delayMs: 250,
                      child: AuthPasswordField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        hint: 'At least 8 characters',
                        error: _passwordError(),
                        onChanged: () => setState(() => _errorMessage = null),
                        onSubmit: (_) => _confirmPasswordFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(height: VSpacing.md),

                    FadeIn(
                      delayMs: 300,
                      child: AuthPasswordField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        enabled: !_isLoading,
                        error: _confirmPasswordError(),
                        onChanged: () => setState(() => _errorMessage = null),
                        onSubmit: _isValid ? (_) => _handleSignUp() : null,
                      ),
                    ),
                    const SizedBox(height: VSpacing.xl),

                    FadeIn(
                      delayMs: 350,
                      child: FilledButton.icon(
                        onPressed: _isLoading || !_isValid
                            ? null
                            : _handleSignUp,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(VIcons.arrowLeft),
                        label: Text(
                          _isLoading ? 'Creating account...' : 'Create Account',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VSpacing.lg),

              FadeIn(
                delayMs: 400,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign In',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: VColors.tertiary,
                          fontWeight: VFontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
