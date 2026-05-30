import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/invite_service.dart';
import '../../services/admin_access_service.dart';
import '../../services/supabase.dart';
import '../../state/resident_provider.dart';
import '../../state/supabase_bootstrap_provider.dart';
import '../../services/supabase_bootstrap.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/auth/auth_error_card.dart';
import '../../widgets/auth/auth_fields.dart';
import '../../theme/v_colors.dart';
import '../../utils/asset_image_decode.dart';
import '../../utils/brand_assets.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import '../../ui/buttons/v_button.dart';
import '../../widgets/core/v_feedback.dart';

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

  bool _isLoading = false;
  String? _errorMessage;

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
      unawaited(AnalyticsService.logEvent(AnalyticsEvents.signIn));
      await _routeAfterSignIn();
    } else {
      context.go('/onboarding');
    }
  }

  Future<void> _routeAfterSignIn() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null || !resident.gateCompleted) {
      if (mounted) context.go('/onboarding');
      return;
    }

    final invitePath = await InviteService.takePendingInvitePath();
    if (!mounted) return;
    context.go(invitePath ?? '/');
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

    if (!await _ensureSupabaseReady()) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _bootstrapMessage(ref.read(supabaseBootstrapProvider)) ??
            'Cloud sign-in is unavailable.';
      });
      return;
    }

    try {
      await AuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

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

    if (!await _ensureSupabaseReady()) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _bootstrapMessage(ref.read(supabaseBootstrapProvider)) ??
            'Cloud sign-in is unavailable.';
      });
      return;
    }

    try {
      final launched = await AuthService.signInWithGoogle();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!launched) {
        setState(() {
          _errorMessage =
              'Could not open Google sign-in. Check that a browser is installed.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Google sign-in failed. Use email/password or try again later.';
      });
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!await _ensureSupabaseReady()) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _bootstrapMessage(ref.read(supabaseBootstrapProvider)) ??
            'Cloud sign-in is unavailable.';
      });
      return;
    }

    try {
      final launched = await AuthService.signInWithApple();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!launched) {
        setState(() {
          _errorMessage = 'Could not open Apple sign-in.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Apple sign-in failed. Try email/password instead.';
      });
    }
  }

  Future<void> _showForgotPassword() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
                  borderSide: const BorderSide(color: VColors.primary, width: 2),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Send reset link',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.trim().isNotEmpty) {
      try {
        final client = maybeSupabase();
        if (client != null) {
          await client.auth.resetPasswordForEmail(emailController.text.trim());
          if (mounted) {
            VFeedback.showMessage(context, 'Password reset link sent. Check your email.');
          }
        }
      } catch (e) {
        if (mounted) {
          VFeedback.showMessage(context, 'Failed to send reset link. Please try again.');
        }
      }
    }
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bootstrap = ref.watch(supabaseBootstrapProvider);

    ref.listen<ResidentState>(residentProvider, (previous, next) {
      if (!mounted || _isLoading) return;
      if (next.isLoading || next.resident == null) return;
      if (maybeSupabase()?.auth.currentSession == null) return;
      unawaited(_routeAfterSignIn());
    });

    final bootstrapHint = _bootstrapMessage(bootstrap);
    final displayError = _errorMessage ?? bootstrapHint;

    final coverCache = assetCacheSizeForCover(context);

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/generated/bg-onboarding.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            cacheWidth: coverCache.width,
            cacheHeight: coverCache.height,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? VColors.surfaceDark : VColors.surface).withValues(alpha: 0.30),
                  (isDark ? VColors.surfaceDark : VColors.surface).withValues(alpha: 0.76),
                  isDark ? VColors.surfaceDark : VColors.surface,
                ],
              ),
            ),
          ),
          SafeArea(
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
                        boxShadow: [
                          BoxShadow(
                            color: VColors.primary.withValues(alpha: 0.18),
                            blurRadius: 28,
                          ),
                        ],
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
                      'Welcome back to your worlds',
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
                        if (displayError != null) ...[
                          AuthErrorCard(message: displayError),
                          const SizedBox(height: VSpacing.lg),
                        ],

                        FadeIn(
                          delayMs: 200,
                          child: AuthEmailField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            enabled: !_isLoading,
                            onChanged: () =>
                                setState(() => _errorMessage = null),
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
                            onChanged: () =>
                                setState(() => _errorMessage = null),
                            onSubmit:
                                _isValid ? (_) => _handleLogin() : null,
                          ),
                        ),
                        const SizedBox(height: VSpacing.xl),

                        FadeIn(
                          delayMs: 300,
                        child: VButton(
                          label: 'Sign In',
                          onPressed: _isLoading || !_isValid ? null : _handleLogin,
                          icon: const Icon(VIcons.arrowLeft),
                          isLoading: _isLoading,
                        ),
                        ),
                        const SizedBox(height: VSpacing.sm),
                        FadeIn(
                          delayMs: 320,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _showForgotPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: VColors.tertiary,
                                  fontWeight: VFontWeight.semiBold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: VSpacing.lg),

                  FadeIn(
                    delayMs: 350,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? VColors.outlineVariantDark
                                    : VColors.outlineVariant,
                              ),
                            ),
                            const SizedBox(width: VSpacing.md),
                            Text(
                              'or',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: VSpacing.md),
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? VColors.outlineVariantDark
                                    : VColors.outlineVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VSpacing.md),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.g_mobiledata, size: VIconSize.lg),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(VRadius.md),
                            ),
                          ),
                        ),
                        const SizedBox(height: VSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleAppleSignIn,
                          icon: const Icon(Icons.apple, size: VIconSize.lg),
                          label: const Text('Continue with Apple'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(VRadius.md),
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
                          "Don't have an account? ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => context.go('/signup'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign Up',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: VColors.tertiary,
                              fontWeight: VFontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpacing.lg),
                  FadeIn(
                    delayMs: 450,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (AdminAccessService
                                  .isCurrentSessionVerifier()) {
                                context.push('/verifier/review');
                              } else {
                                context.go('/verifier/login');
                              }
                            },
                      child: Text(
                        AdminAccessService.isCurrentSessionVerifier()
                            ? 'Open staff review'
                            : 'Staff sign-in',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
