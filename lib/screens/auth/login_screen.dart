import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../legal/app_legal.dart';
import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/invite_navigation.dart';
import '../../services/admin_access_service.dart';
import '../../services/supabase.dart';
import '../../state/resident_provider.dart';
import '../../services/supabase_bootstrap.dart';
import '../../widgets/auth/auth_error_card.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import 'package:vertiege/ui/ui.dart';
import '../../widgets/auth/auth_fields.dart';
import '../../widgets/auth/auth_prestige_shell.dart';
import '../../widgets/auth/auth_social_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    ref.listenManual<ResidentState>(residentProvider, (previous, next) {
      if (!mounted) return;
      if (next.isLoading || next.resident == null) return;
      if (maybeSupabase()?.auth.currentSession == null) return;
      unawaited(_onOAuthResidentReady());
    });
    if (maybeSupabase() == null &&
        SupabaseBootstrap.lastResult == SupabaseBootstrapResult.missingConfig) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Cloud sign-in is not configured in this build (.env missing).';
        });
      });
    }
  }

  Future<void> _onOAuthResidentReady() async {
    _setLoading(false);
    if (!mounted) return;
    await _routeAfterSignIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _isValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) &&
        _passwordController.text.length >= 8;
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  Future<void> _finishSignInAfterAuth() async {
    await ref
        .read(residentProvider.notifier)
        .loadResident()
        .timeout(const Duration(seconds: 12));
    if (!mounted) return;

    final residentState = ref.read(residentProvider);
    if (residentState.loadError != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = residentState.loadError;
      });
      return;
    }

    final resident = residentState.resident;
    if (resident != null) {
      _setLoading(false);
      unawaited(AnalyticsService.logEvent(AnalyticsEvents.signIn));
      await _routeAfterSignIn();
    } else {
      _setLoading(false);
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  Future<void> _routeAfterSignIn() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null || !resident.gateCompleted) {
      if (mounted) context.go('/onboarding');
      return;
    }

    final route = await routeAfterAuth(ref, feedbackContext: context);
    if (!mounted) return;
    context.go(route);
  }

  Future<void> _handleLogin() async {
    if (!_isValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!await SupabaseBootstrap.ensureReady()) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              SupabaseBootstrap.messageFor(SupabaseBootstrap.lastResult) ??
              'Cloud sign-in is unavailable.';
        });
        return;
      }

      await AuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      await _finishSignInAfterAuth();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Sign-in timed out. Check your connection and try again.';
      });
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
              'Cloud sign-in is unavailable.';
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
              'Cloud sign-in is unavailable.';
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

  Future<void> _showForgotPassword() async {
    final email = await showVDialog<String>(
      context: context,
      title: 'Reset password',
      content: _ForgotPasswordDialogContent(
        initialEmail: _emailController.text.trim(),
      ),
    );

    if (email == null || email.isEmpty) return;

    try {
      final client = maybeSupabase();
      if (client != null) {
        await client.auth.resetPasswordForEmail(email);
        if (mounted) {
          VFeedback.showMessage(
            context,
            'Password reset link sent. Check your email.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        VFeedback.showMessage(
          context,
          'Failed to send reset link. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    activeMode: AuthPrestigeMode.signIn,
                    isLoading: _isLoading,
                    onSignIn: () {},
                    onSignUp: () => context.go('/signup'),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    AuthErrorCard(message: _errorMessage!),
                    const SizedBox(height: VSpacing.md),
                  ],
                  const PrestigeAuthFieldLabel(label: 'Email or Username'),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    style: const TextStyle(color: PrestigeNoir.foreground),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() => _errorMessage = null),
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    decoration: prestigeAuthFieldDecoration(
                      hint: 'raven@voidwalker.io',
                    ),
                  ),
                  const SizedBox(height: VSpacing.lg),
                  const PrestigeAuthFieldLabel(label: 'Password'),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    style: const TextStyle(color: PrestigeNoir.foreground),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _errorMessage = null),
                    onSubmitted: _isValid ? (_) => _handleLogin() : null,
                    decoration: prestigeAuthFieldDecoration(
                      hint: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: PrestigeNoir.muted,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: VButton(
                      label: 'Forgot password?',
                      variant: ButtonVariant.text,
                      size: ButtonSize.small,
                      onPressed: _isLoading ? null : _showForgotPassword,
                    ),
                  ),
                  const SizedBox(height: VSpacing.sm),
                  AuthPrestigePrimaryButton(
                    label: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _isValid ? _handleLogin : null,
                  ),
                  const SizedBox(height: VSpacing.lg),
                  AuthSocialButtons(
                    isLoading: _isLoading,
                    onGoogle: _handleGoogleSignIn,
                    onApple: _handleAppleSignIn,
                  ),
                  const SizedBox(height: VSpacing.md),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'By continuing, you agree to our ',
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
                  VButton(
                    label: AdminAccessService.isCurrentSessionVerifier()
                        ? 'Open staff review'
                        : 'Staff sign-in',
                    variant: ButtonVariant.text,
                    size: ButtonSize.small,
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (AdminAccessService.isCurrentSessionVerifier()) {
                              context.push('/verifier/review');
                            } else {
                              context.go('/verifier/login');
                            }
                          },
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

/// Owns the email field so the controller lives until the dialog route disposes.
class _ForgotPasswordDialogContent extends StatefulWidget {
  const _ForgotPasswordDialogContent({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialogContent> createState() =>
      _ForgotPasswordDialogContentState();
}

class _ForgotPasswordDialogContentState
    extends State<_ForgotPasswordDialogContent> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    Navigator.pop(context, email);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter your email address. We will send you a password reset link.',
          style: TextStyle(color: PrestigeNoir.muted),
        ),
        const SizedBox(height: VSpacing.md),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: PrestigeNoir.foreground),
          decoration: prestigeAuthFieldDecoration(hint: 'you@example.com'),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: VSpacing.lg),
        vDialogActionsRow([
          VButton(
            label: 'Cancel',
            variant: ButtonVariant.text,
            onPressed: () => Navigator.pop(context),
          ),
          VButton(label: 'Send reset link', onPressed: _submit),
        ]),
      ],
    );
  }
}
