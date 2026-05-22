import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/admin_access_service.dart';
import '../../services/auth_service.dart';
import '../../services/verifier_session.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import '../../widgets/auth/auth_error_card.dart';

/// Staff-only sign-in. Successful login lands on [VerificationReviewScreen] only.
class VerifierLoginScreen extends ConsumerStatefulWidget {
  const VerifierLoginScreen({super.key});

  @override
  ConsumerState<VerifierLoginScreen> createState() => _VerifierLoginScreenState();
}

class _VerifierLoginScreenState extends ConsumerState<VerifierLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) &&
        _passwordController.text.length >= 6;
  }

  Future<void> _handleLogin() async {
    if (!_isValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final user = response.user;
      if (!AdminAccessService.isVerifierUser(user)) {
        await AuthService.signOut();
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              'This account is not authorized for verification review.';
        });
        return;
      }
      if (!mounted) return;
      VerifierSession.enter();
      context.go('/verifier/review');
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
        _errorMessage = e.toString();
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 48,
                    color: VColors.primary,
                  ),
                  const SizedBox(height: VSpacing.md),
                  Text(
                    'Verifier sign-in',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: VFontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    'Staff access for profession verification review only.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: VColors.onSurfaceVariant,
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
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Admin email',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: VSpacing.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
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
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: VSpacing.lg),
                  VButton(
                    label: _isLoading ? 'Signing in…' : 'Sign in',
                    onPressed: _isValid && !_isLoading ? _handleLogin : null,
                    isLoading: _isLoading,
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
