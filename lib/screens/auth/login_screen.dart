import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/invite_navigation.dart';
import '../../services/admin_access_service.dart';
import '../../services/supabase.dart';
import '../../state/resident_provider.dart';
import '../../services/supabase_bootstrap.dart';
import '../../widgets/auth/auth_error_card.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import 'package:vertiege/ui/ui.dart';
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
        _passwordController.text.length >= 6;
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

  String? _bootstrapMessage(SupabaseBootstrapResult bootstrap) {
    return switch (bootstrap) {
      SupabaseBootstrapResult.ready => null,
      SupabaseBootstrapResult.missingConfig =>
        'Cloud sign-in is not configured in this build (.env missing in APK).',
      SupabaseBootstrapResult.failed =>
        'Could not connect to cloud. Check network and tap Retry on the banner above.',
      SupabaseBootstrapResult.pending => 'Connecting to cloud…',
    };
  }

  Future<bool> _ensureSupabaseReady() async {
    if (maybeSupabase() != null) return true;
    final result = await SupabaseBootstrap.initialize();
    return result == SupabaseBootstrapResult.ready;
  }

  Future<void> _handleLogin() async {
    if (!_isValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!await _ensureSupabaseReady()) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              _bootstrapMessage(SupabaseBootstrap.lastResult) ??
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
      if (!await _ensureSupabaseReady()) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              _bootstrapMessage(SupabaseBootstrap.lastResult) ??
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
      if (!await _ensureSupabaseReady()) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              _bootstrapMessage(SupabaseBootstrap.lastResult) ??
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
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final result = await showVDialog<bool>(
      context: context,
      title: 'Reset password',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter your email address. We will send you a password reset link.',
          ),
          const SizedBox(height: VSpacing.md),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.md),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.md),
                borderSide: BorderSide(
                  color: isDark ? VColors.outlineDark : VColors.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.md),
                borderSide: const BorderSide(
                  color: VColors.primary,
                  width: 2,
                ),
              ),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        vDialogActionsRow([
          VButton(
            label: 'Cancel',
            variant: ButtonVariant.text,
            onPressed: () => Navigator.pop(context, false),
          ),
          VButton(
            label: 'Send reset link',
            onPressed: () => Navigator.pop(context, true),
          ),
        ]),
      ],
    );

    if (result == true && emailController.text.trim().isNotEmpty) {
      try {
        final client = maybeSupabase();
        if (client != null) {
          await client.auth.resetPasswordForEmail(emailController.text.trim());
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
    emailController.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      border: border,
      enabledBorder: border.copyWith(
        borderSide: BorderSide(
          color: isDark ? VColors.outlineDark : VColors.outline,
        ),
      ),
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: VColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Vertiege',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: VFontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    'Welcome back',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VSpacing.xl),
                  if (_errorMessage != null) ...[
                    AuthErrorCard(message: _errorMessage!),
                    const SizedBox(height: VSpacing.md),
                  ],
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() => _errorMessage = null),
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    decoration: _fieldDecoration(
                      context,
                      label: 'Email',
                      hint: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: VSpacing.md),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _errorMessage = null),
                    onSubmitted: _isValid ? (_) => _handleLogin() : null,
                    decoration: _fieldDecoration(
                      context,
                      label: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpacing.lg),
                  VButton(
                    label: 'Sign In',
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _isValid ? _handleLogin : null,
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _showForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: VSpacing.lg),
                  AuthSocialButtons(
                    isLoading: _isLoading,
                    isDark: isDark,
                    onGoogle: _handleGoogleSignIn,
                    onApple: _handleAppleSignIn,
                  ),
                  const SizedBox(height: VSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.go('/signup'),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (AdminAccessService.isCurrentSessionVerifier()) {
                              context.push('/verifier/review');
                            } else {
                              context.go('/verifier/login');
                            }
                          },
                    child: Text(
                      AdminAccessService.isCurrentSessionVerifier()
                          ? 'Open staff review'
                          : 'Staff sign-in',
                    ),
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
