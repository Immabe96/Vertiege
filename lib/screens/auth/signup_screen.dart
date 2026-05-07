import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../widgets/core/tactile_button.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/auth/auth_error_card.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

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

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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

    return email.contains('@') &&
        password.length >= 6 &&
        confirm == password;
  }

  String? _passwordError() {
    final password = _passwordController.text;
    if (password.isNotEmpty && password.length < 6) {
      return 'Password must be at least 6 characters';
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

      // Navigate to onboarding to create their resident profile
      context.go('/onboarding');
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            children: [
              const SizedBox(height: Spacing.xxl + Spacing.xl),

              // ── Brand — gold icon on obsidian ────────────
              FadeIn(
                delayMs: 0,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
                  ),
                  child: const Icon(
                    Icons.public,
                    size: IconSizes.xl,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              FadeIn(
                delayMs: 100,
                child: Text(
                  'Vertiege',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeights.bold,
                    letterSpacing: LetterSpacing.display,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xs),
              FadeIn(
                delayMs: 150,
                child: Text(
                  'Create your account',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xxl),

              // ── Glass form card ──────────────────────────
              GlassPanel(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Error Message ──────────────────────
                    if (_errorMessage != null) ...[
                      AuthErrorCard(message: _errorMessage!),
                      const SizedBox(height: Spacing.lg),
                    ],

                    // ── Email Field — ghost/underline ─────
                    FadeIn(
                      delayMs: 200,
                      child: TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enabled: !_isLoading,
                        style: const TextStyle(color: AppColors.ink),
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        onChanged: (_) => setState(() => _errorMessage = null),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          hintStyle: TextStyle(color: AppColors.inkMuted),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.glassBorder),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.glassBorder),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          prefixIcon: Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: AppColors.glassBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    // ── Password Field — ghost/underline ──
                    FadeIn(
                      delayMs: 250,
                      child: TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        style: const TextStyle(color: AppColors.ink),
                        onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                        onChanged: (_) => setState(() => _errorMessage = null),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'At least 6 characters',
                          hintStyle: const TextStyle(color: AppColors.inkMuted),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.glassBorder),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.glassBorder),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: AppColors.glassBackground,
                          errorText: _passwordError(),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    // ── Confirm Password — ghost/underline ─
                    FadeIn(
                      delayMs: 300,
                      child: TextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        style: const TextStyle(color: AppColors.ink),
                        onSubmitted: _isValid ? (_) => _handleSignUp() : null,
                        onChanged: (_) => setState(() => _errorMessage = null),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintStyle: const TextStyle(color: AppColors.inkMuted),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.glassBorder),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.glassBorder),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          filled: true,
                          fillColor: AppColors.glassBackground,
                          errorText: _confirmPasswordError(),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),

                    // ── Create Account Button — gold CTA ───
                    FadeIn(
                      delayMs: 350,
                      child: TactileButton(
                        label: _isLoading ? 'Creating account...' : 'Create Account',
                        icon: _isLoading ? null : Icons.arrow_forward,
                        fullWidth: true,
                        color: AppColors.tertiary,
                        textColor: AppColors.onTertiary,
                        onPressed: _isLoading || !_isValid ? null : _handleSignUp,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Spacing.lg),

              // ── Sign In Link ─────────────────────────────
              FadeIn(
                delayMs: 400,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () => context.go('/login'),
                      child: Text(
                        'Sign In',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeights.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
