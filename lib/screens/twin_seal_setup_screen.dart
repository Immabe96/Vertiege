import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/v_colors.dart';
import '../theme/design_system.dart';
import '../ui/icons/v_icons.dart';
import '../ui/buttons/v_button.dart';

class TwinSealSetupScreen extends StatefulWidget {
  const TwinSealSetupScreen({super.key});

  @override
  State<TwinSealSetupScreen> createState() => _TwinSealSetupScreenState();
}

class _TwinSealSetupScreenState extends State<TwinSealSetupScreen> {
  bool _isLoading = false;
  String? _secret;
  String? _qrCodeUrl;
  final _codeController = TextEditingController();
  bool _enrolled = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateSecret() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AuthService.generateTwinSeal();
      if (result != null) {
        setState(() {
          _secret = result['secret'] as String?;
          _qrCodeUrl = result['qr_code_url'] as String?;
        });
      } else {
        setState(() {
          _error = 'Failed to generate 2FA secret. Ensure the Supabase edge function is deployed.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to generate 2FA secret: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndEnroll() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter a 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final valid = await AuthService.verifyTwinSeal(code);
      if (!valid) {
        setState(() => _error = 'Invalid code. Please check and try again.');
        return;
      }

      final enrolled = await AuthService.enrollTwinSeal(_secret!, code);
      if (enrolled) {
        setState(() => _enrolled = true);
      } else {
        setState(() => _error = 'Failed to enroll. Please try again.');
      }
    } catch (e) {
      setState(() => _error = 'Verification failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twin Seal (2FA)'),
        backgroundColor: (isDark ? VColors.surfaceDark : VColors.surface)
            .withValues(alpha: 0.8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: VColors.tertiary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 32,
                  color: VColors.tertiary,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Secure your account',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeights.bold,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Twin Seal adds an extra layer of security. After setup, you\'ll need a 6-digit code from your authenticator app each time you sign in.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            _buildContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_enrolled) {
      return _buildSuccessState(theme);
    } else if (_secret != null) {
      return _buildVerifyState(theme);
    } else {
      return _generateState(theme);
    }
  }

  Widget _buildSuccessState(ThemeData theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: VColors.success,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Twin Seal Enabled!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeights.bold,
              color: VColors.success,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Your account is now protected with two-factor authentication.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xl),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(VIcons.badgeCheck),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyState(ThemeData theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Verify setup',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeights.bold,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'Scan the QR code in your authenticator app (Google Authenticator, Authy, etc.), then enter the 6-digit code below.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? VColors.onSurfaceVariantDark
                : VColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        if (_qrCodeUrl != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: isDark ? VColors.surfaceDark : VColors.surface,
                borderRadius: BorderRadius.circular(RadiusTokens.xl),
                border: Border.all(
                  color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    color: isDark
                        ? VColors.surfaceContainerDark
                        : VColors.surfaceContainer,
                    child: Center(
                      child: Text(
                        'QR Code\n(Use qr_flutter package)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Secret: $_secret',
                    style: TextStyle(
                      fontFamily: AppFont.mono,
                      fontSize: FontSizes.bodyMd,
                      color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _secret!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Secret copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: IconSizes.sm),
                    label: const Text('Copy secret'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: Spacing.xl),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: FontSizes.headlineLg,
            fontFamily: AppFont.mono,
            letterSpacing: 8,
          ),
          maxLength: 6,
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RadiusTokens.xl),
              ),
              filled: true,
              fillColor: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Text(
                _error!,
                style: const TextStyle(color: VColors.error),
              ),
            ),
        VButton(
          label: 'Verify & Enable',
          onPressed: _verifyAndEnroll,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _generateState(ThemeData theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Generate secret',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeights.bold,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'Tap the button below to generate your unique Twin Seal secret. You\'ll need an authenticator app ready.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? VColors.onSurfaceVariantDark
                : VColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Text(
              _error!,
              style: const TextStyle(color: VColors.error),
            ),
          ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _generateSecret,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(VIcons.shield),
          label: const Text('Generate Secret'),
        ),
      ],
    );
  }
}
