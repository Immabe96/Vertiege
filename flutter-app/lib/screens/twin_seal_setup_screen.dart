import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/v_colors.dart';
import 'package:vertiege/ui/ui.dart';
import '../theme/v_tokens.dart';

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
  bool _secretRevealed = false;

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
          _error =
              'Failed to generate 2FA secret. Ensure the Supabase edge function is deployed.';
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

    return VHubPage(
      title: 'Twin Seal (2FA)',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.lg),
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
            const SizedBox(height: VSpacing.lg),
            Text(
              'Secure your account',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              'Twin Seal adds an extra layer of security. After setup, you\'ll need a 6-digit code from your authenticator app each time you sign in.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VSpacing.xl),
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
    return Center(
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 64, color: VColors.success),
          const SizedBox(height: VSpacing.md),
          Text(
            'Twin Seal Enabled!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: VFontWeight.bold,
              color: VColors.success,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            'Your account is now protected with two-factor authentication.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpacing.xl),
          VButton(
            label: 'Done',
            icon: const Icon(VIcons.badgeCheck),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Verify setup',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.md),
        Text(
          'Scan the QR code in your authenticator app (Google Authenticator, Authy, etc.), then enter the 6-digit code below.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: VSpacing.lg),
        if (_qrCodeUrl != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(VSpacing.md),
              decoration: BoxDecoration(
                color: VColors.surfaceDark,
                borderRadius: BorderRadius.circular(VRadius.xl),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    color: VColors.surfaceContainerDark,
                    child: Center(
                      child: Text(
                        'QR Code\n(Use qr_flutter package)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpacing.md),
                  Text(
                    'Scan the QR with your authenticator app. '
                    'Reveal the secret only if you cannot scan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: VFontSize.bodySm,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: VSpacing.sm),
                  if (_secretRevealed)
                    SelectableText(
                      _secret!,
                      style: TextStyle(
                        fontFamily: VFont.mono,
                        fontSize: VFontSize.bodyMd,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  else
                    VButton(
                      label: 'Reveal secret',
                      icon: const Icon(Icons.visibility_outlined, size: VIconSize.sm),
                      variant: ButtonVariant.text,
                      onPressed: () => setState(() => _secretRevealed = true),
                    ),
                  const SizedBox(height: VSpacing.sm),
                  VButton(
                    label: 'Copy secret',
                    icon: const Icon(Icons.copy, size: VIconSize.sm),
                    variant: ButtonVariant.text,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _secret!));
                      VFeedback.showMessage(
                        context,
                        'Secret copied to clipboard',
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: VSpacing.xl),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: VFontSize.headlineLg,
            fontFamily: VFont.mono,
            letterSpacing: 8,
          ),
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VRadius.xl),
            ),
            filled: true,
            fillColor: VColors.surfaceContainerDark,
          ),
        ),
        const SizedBox(height: VSpacing.lg),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.md),
            child: Text(_error!, style: const TextStyle(color: VColors.error)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Generate secret',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.md),
        Text(
          'Tap the button below to generate your unique Twin Seal secret. You\'ll need an authenticator app ready.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: VSpacing.xl),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.md),
            child: Text(_error!, style: const TextStyle(color: VColors.error)),
          ),
        VButton(
          label: 'Generate Secret',
          isFullWidth: true,
          isLoading: _isLoading,
          icon: const Icon(VIcons.shield),
          onPressed: _generateSecret,
        ),
      ],
    );
  }
}
