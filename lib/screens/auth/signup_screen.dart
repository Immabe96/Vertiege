import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/invite_navigation.dart';
import '../../services/supabase_bootstrap.dart';
import '../../state/resident_provider.dart';
import '../../widgets/auth/auth_error_card.dart';
import '../../widgets/auth/auth_fields.dart';
import '../../widgets/auth/auth_social_buttons.dart';
import '../../legal/app_legal.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/brand_assets.dart';
import '../../ui/icons/v_icons.dart';
import 'package:vertiege/ui/ui.dart';

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
      if (!await SupabaseBootstrap.ensureReady()) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              SupabaseBootstrap.messageFor(SupabaseBootstrap.lastResult) ??
              'Cloud sign-up is unavailable.';
        });
        return;
      }

      await AuthService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      await ref.read(residentProvider.notifier).loadResident();
      if (!mounted) return;

      final resident = ref.read(residentProvider).resident;
      if (resident != null && resident.gateCompleted) {
        final route = await routeAfterAuth(ref, feedbackContext: context);
        if (!mounted) return;
        context.go(route);
      } else {
        context.go('/onboarding');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!await SupabaseBootstrap.ensureReady()) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              SupabaseBootstrap.messageFor(SupabaseBootstrap.lastResult) ??
              'Cloud sign-up is unavailable.';
        });
        return;
      }

      final launched = await AuthService.signInWithGoogle();
      if (!mounted) return;
      if (!launched) {
        setState(() {
          _errorMessage =
              'Could not open Google sign-in. Check that a browser is installed.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Google sign-in failed. Use email/password or try again later.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!await SupabaseBootstrap.ensureReady()) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              SupabaseBootstrap.messageFor(SupabaseBootstrap.lastResult) ??
              'Cloud sign-up is unavailable.';
        });
        return;
      }

      final launched = await AuthService.signInWithApple();
      if (!mounted) return;
      if (!launched) {
        setState(() => _errorMessage = 'Could not open Apple sign-in.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Apple sign-in failed. Try email/password instead.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: 80),

              Container(
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
              const SizedBox(height: VSpacing.lg),
              Text(
                'Vertiege',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                'Create your account',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
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

                    AuthEmailField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      enabled: !_isLoading,
                      onChanged: () => setState(() => _errorMessage = null),
                      onSubmit: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: VSpacing.md),
                    AuthPasswordField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.next,
                      hint: 'At least 8 characters',
                      error: _passwordError(),
                      onChanged: () => setState(() => _errorMessage = null),
                      onSubmit: (_) => _confirmPasswordFocus.requestFocus(),
                    ),
                    const SizedBox(height: VSpacing.md),
                    AuthPasswordField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      enabled: !_isLoading,
                      error: _confirmPasswordError(),
                      onChanged: () => setState(() => _errorMessage = null),
                      onSubmit: _isValid ? (_) => _handleSignUp() : null,
                    ),
                    const SizedBox(height: VSpacing.xl),
                    VButton(
                      label: 'Create Account',
                      isFullWidth: true,
                      isLoading: _isLoading,
                      icon: const Icon(VIcons.arrowLeft),
                      onPressed: _isValid ? _handleSignUp : null,
                    ),
                    const SizedBox(height: VSpacing.lg),
                    AuthSocialButtons(
                      isLoading: _isLoading,
                      isDark: isDark,
                      onGoogle: _handleGoogleSignIn,
                      onApple: _handleAppleSignIn,
                    ),
                    const SizedBox(height: VSpacing.lg),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'By signing up, you agree to our ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: VColors.tertiary,
                              fontWeight: VFontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  AppLegal.showTermsOfService(context),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: VColors.tertiary,
                              fontWeight: VFontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  AppLegal.showPrivacyPolicy(context),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VSpacing.lg),

              Row(
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
              const SizedBox(height: VSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
