import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import 'package:vertiege/l10n/app_localizations.dart';
import 'package:vertiege/ui/ui.dart';
import '../../widgets/auth/auth_prestige_shell.dart';

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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: PrestigeNoir.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: VSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthPrestigeBrandHeader(),
                  const SizedBox(height: 24),
                  AuthPrestigeModeSwitch(
                    activeMode: AuthPrestigeMode.signUp,
                    isLoading: _isLoading,
                    onSignIn: () => context.go('/login'),
                    onSignUp: () {},
                  ),
                  const SizedBox(height: 24),
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
                    hint: 'Min 8 characters',
                    error: _passwordError(),
                    onChanged: () => setState(() => _errorMessage = null),
                    onSubmit: (_) => _confirmPasswordFocus.requestFocus(),
                  ),
                  const SizedBox(height: VSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PrestigeAuthFieldLabel(label: 'Confirm password'),
                      TextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        enabled: !_isLoading,
                        obscureText: true,
                        style: const TextStyle(color: PrestigeNoir.foreground),
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() => _errorMessage = null),
                        onSubmitted: _isValid ? (_) => _handleSignUp() : null,
                        decoration: prestigeAuthFieldDecoration(
                          hint: '••••••••',
                          errorText: _confirmPasswordError(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.xl),
                  AuthPrestigePrimaryButton(
                    label: l10n.authCreateAccount,
                    isLoading: _isLoading,
                    onPressed: _isValid ? _handleSignUp : null,
                  ),
                  const SizedBox(height: VSpacing.lg),
                  AuthSocialButtons(
                    isLoading: _isLoading,
                    onGoogle: _handleGoogleSignIn,
                    onApple: _handleAppleSignIn,
                  ),
                  const SizedBox(height: VSpacing.lg),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: l10n.authContinueAgreePrefix,
                      style: const TextStyle(
                        fontSize: VFontSize.labelSm,
                        color: PrestigeNoir.mutedDim,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(color: VColors.brand),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                AppLegal.showTermsOfService(context),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(color: VColors.brand),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                AppLegal.showPrivacyPolicy(context),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: VFontSize.labelLg,
                          color: PrestigeNoir.muted,
                        ),
                      ),
                      VButton(
                        label: 'Sign In',
                        variant: ButtonVariant.text,
                        size: ButtonSize.small,
                        onPressed:
                            _isLoading ? null : () => context.go('/login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
