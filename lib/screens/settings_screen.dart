import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../theme/design_system.dart';
import '../theme/colors.dart';
import '../widgets/core/glass_panel.dart';

// ── SharedPreferences keys for notification toggles ────────────────
const _kPrefPushEnabled = 'settings_push_enabled';
const _kPrefLikesEnabled = 'settings_likes_enabled';
const _kPrefCommentsEnabled = 'settings_comments_enabled';
const _kPrefWorldInvitesEnabled = 'settings_world_invites_enabled';
const _kPrefTierUpgradesEnabled = 'settings_tier_upgrades_enabled';

// ── SharedPreferences key for text size ────────────────────────────
const _kPrefTextSize = 'settings_text_size';

enum _TextSize { small, normal, large }

extension _TextSizeX on _TextSize {
  String get label {
    switch (this) {
      case _TextSize.small:
        return 'Small';
      case _TextSize.normal:
        return 'Normal';
      case _TextSize.large:
        return 'Large';
    }
  }

  // Used by the app's ThemeProvider to apply text scaling app-wide.
  // ignore: unused_element
  double get scaleFactor {
    switch (this) {
      case _TextSize.small:
        return 0.85;
      case _TextSize.normal:
        return 1.0;
      case _TextSize.large:
        return 1.25;
    }
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ── Notification toggle states ──────────────────────────────────
  bool _pushEnabled = true;
  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _worldInvitesEnabled = true;
  bool _tierUpgradesEnabled = true;

  // ── Text size state ─────────────────────────────────────────────
  _TextSize _textSize = _TextSize.normal;

  // ── Cache size estimate ─────────────────────────────────────────
  int _cacheSizeBytes = 0;

  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _estimateCacheSize();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool(_kPrefPushEnabled) ?? true;
      _likesEnabled = prefs.getBool(_kPrefLikesEnabled) ?? true;
      _commentsEnabled = prefs.getBool(_kPrefCommentsEnabled) ?? true;
      _worldInvitesEnabled = prefs.getBool(_kPrefWorldInvitesEnabled) ?? true;
      _tierUpgradesEnabled = prefs.getBool(_kPrefTierUpgradesEnabled) ?? true;

      final textSizeStr = prefs.getString(_kPrefTextSize);
      _textSize = _TextSize.values.firstWhere(
        (t) => t.name == textSizeStr,
        orElse: () => _TextSize.normal,
      );

      _prefsLoaded = true;
    });
  }

  Future<void> _setNotificationPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setTextSize(_TextSize size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefTextSize, size.name);
    setState(() => _textSize = size);
  }

  void _estimateCacheSize() {
    final paintingBinding = PaintingBinding.instance;
    final cache = paintingBinding.imageCache;
    final current = cache.currentSize;
    // ~150 KB per cached image as a rough blended average
    const averagePerImage = 150 * 1024;
    setState(() {
      _cacheSizeBytes = (current * averagePerImage).clamp(0, 50 * 1024 * 1024);
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    setState(() => _cacheSizeBytes = 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image cache cleared'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Dialog helpers ─────────────────────────────────────────────

  void _showCreditsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Credits'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vertiege',
                style: TextStyle(
                  fontWeight: FontWeights.bold,
                  fontSize: FontSizes.headingCard,
                ),
              ),
              SizedBox(height: Spacing.sm),
              Text('A tier-gated social network built with love.'),
              SizedBox(height: Spacing.md),
              Text('Design & Development', style: TextStyle(fontWeight: FontWeights.bold)),
              SizedBox(height: Spacing.xs),
              Text('The Vertiege Team'),
              SizedBox(height: Spacing.md),
              Text('Special Thanks', style: TextStyle(fontWeight: FontWeights.bold)),
              SizedBox(height: Spacing.xs),
              Text('Flutter Community'),
              Text('Supabase Team'),
              Text('All our beta testers'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'New email address',
            prefixIcon: Icon(Icons.email_outlined),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.glassBackground,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email change requested — check your inbox'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tertiary,
              foregroundColor: AppColors.onTertiary,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.glassBackground,
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.glassBackground,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.lock),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.glassBackground,
                ),
                validator: (v) {
                  if (v != newController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tertiary,
              foregroundColor: AppColors.onTertiary,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showTwinSealSetup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.full),
        ),
        title: const Text('Twin Seal (2FA)'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, size: 48, color: AppColors.tertiary),
            SizedBox(height: Spacing.md),
            Text(
              'Twin Seal adds an extra layer of security to your account. '
              'Once enabled, you\'ll need to enter a 6-digit code from your '
              'authenticator app each time you sign in.',
              style: TextStyle(color: AppColors.inkSecondary),
            ),
            SizedBox(height: Spacing.md),
            Text(
              'To enable, use a Supabase Edge Function that generates a TOTP '
              'secret and QR code. This feature requires the supabase/functions/enroll-totp '
              'edge function to be deployed.',
              style: TextStyle(fontSize: FontSizes.labelSm, color: AppColors.inkMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Trigger Twin Seal enrollment via Supabase
              AuthService.generateTwinSeal();
            },
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final controller = TextEditingController();
    String confirmText = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Delete Account',
            style: TextStyle(color: AppColors.error),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone. All your data, posts, and memberships will be permanently removed.',
              ),
              const SizedBox(height: Spacing.md),
              const Text(
                'Type DELETE to confirm',
                style: TextStyle(fontWeight: FontWeights.bold),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type DELETE here',
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  filled: true,
                  fillColor: AppColors.glassBackground,
                ),
                onChanged: (v) => setDialogState(() => confirmText = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dangerRed,
              ),
              onPressed: confirmText.trim() == 'DELETE'
                  ? () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deletion requested'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : null,
              child: const Text('Delete My Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Last updated: May 2025', style: TextStyle(fontSize: FontSizes.caption)),
              SizedBox(height: Spacing.md),
              Text(
                'Information We Collect',
                style: TextStyle(fontWeight: FontWeights.bold),
              ),
              SizedBox(height: Spacing.xs),
              Text(
                'We collect information you provide directly, such as your profile data, posts, and interactions. '
                'We also collect usage data to improve the service.',
              ),
              SizedBox(height: Spacing.md),
              Text(
                'How We Use Your Data',
                style: TextStyle(fontWeight: FontWeights.bold),
              ),
              SizedBox(height: Spacing.xs),
              Text(
                'Your data is used to provide and improve Vertiege services, personalize your experience, '
                'and communicate important updates. We never sell your personal data.',
              ),
              SizedBox(height: Spacing.md),
              Text(
                'Data Storage & Security',
                style: TextStyle(fontWeight: FontWeights.bold),
              ),
              SizedBox(height: Spacing.xs),
              Text(
                'Data is stored securely using Supabase infrastructure with encryption at rest and in transit. '
                'You can request data deletion at any time.',
              ),
              SizedBox(height: Spacing.md),
              Text(
                'Contact',
                style: TextStyle(fontWeight: FontWeights.bold),
              ),
              SizedBox(height: Spacing.xs),
              Text('privacy@vertiege.app'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Last updated: May 2025', style: TextStyle(fontSize: FontSizes.caption)),
              SizedBox(height: Spacing.md),
              Text(
                '1. Acceptance of Terms',
                style: TextStyle(fontWeight: FontWeights.bold),
              ),
              SizedBox(height: Spacing.xs),
              Text(
                'By using Vertiege, you agree to these terms. If you do not agree, do not use the service.',
              ),
              SizedBox(height: Spacing.md),
              Text(
                '2. User Conduct',
                style: TextStyle(fontWeight: FontWeights.bold),
              ),
              SizedBox(height: Spacing.xs),
              Text(
                'Users must follow community guidelines within each world. Harassment, spam, '
                'and illegal content are prohibited and may result in account termination.',
              ),
              SizedBox(height: Spacing.md),
              Text(
                '3. Content Ownership',
                style: TextStyle(fontWeight: FontWeights.bold),
              ),
              SizedBox(height: Spacing.xs),
              Text(
                'You retain ownership of content you create. By posting, you grant Vertiege a license '
                'to display and distribute your content within the platform.',
              ),
              SizedBox(height: Spacing.md),
              Text(
                '4. Limitation of Liability',
                style: TextStyle(fontWeight: FontWeights.bold),
              ),
              SizedBox(height: Spacing.xs),
              Text(
                'Vertiege is provided "as is" without warranties. We are not liable for damages '
                'arising from use of the service.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRestoreBackupDialog() {
    final controller = TextEditingController();
    String? validationError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Restore Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your backup JSON below, then tap Validate & Restore.',
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Paste JSON here...',
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.glassBackground,
                  errorText: validationError,
                  contentPadding: const EdgeInsets.all(Spacing.md),
                ),
                style: const TextStyle(
                  fontFamily: AppFont.mono,
                  fontSize: FontSizes.body,
                ),
                onChanged: (_) {
                  if (validationError != null) {
                    setDialogState(() => validationError = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
              ),
              onPressed: () async {
                final raw = controller.text.trim();
                if (raw.isEmpty) {
                  setDialogState(() => validationError = 'Please paste backup JSON');
                  return;
                }

                // Validate JSON structure
                try {
                  final parsed = jsonDecode(raw);
                  if (parsed is! Map<String, dynamic>) {
                    setDialogState(() => validationError = 'Invalid JSON: expected an object');
                    return;
                  }
                  if (!parsed.containsKey('backup')) {
                    setDialogState(
                        () => validationError = 'Missing "backup" key — not a valid backup file');
                    return;
                  }
                  if (parsed['backup'] is! Map<String, dynamic>) {
                    setDialogState(
                        () => validationError = '"backup" must be an object');
                    return;
                  }
                } catch (e) {
                  setDialogState(() => validationError = 'Invalid JSON: ${e.toString()}');
                  return;
                }

                // Attempt restore
                final success = await BackupService.restoreBackup(raw);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Backup restored successfully'
                          : 'Restore failed — data may be corrupted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Validate & Restore'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDataDialog() {
    // Multi-step confirmation
    showDialog(
      context: context,
      builder: (ctx) {
        final router = GoRouter.of(context);
        return _ResetDataConfirmationDialog(
          onConfirmed: () async {
            await StorageService.clearAll();
            if (ctx.mounted) Navigator.pop(ctx);
            ref.read(themeProvider.notifier).setScheme(ThemeScheme.system);
            router.go('/onboarding');
          },
        );
      },
    );
  }

  // ── Build helpers ──────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.sm),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: FontSizes.caption,
          fontWeight: FontWeights.bold,
          letterSpacing: LetterSpacing.micro,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    _estimateCacheSize();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _sectionDivider() {
    return const Divider(
      height: 1,
      indent: Spacing.lg + Spacing.sm,
      color: AppColors.glassBorder,
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadPrefs(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: Spacing.xxl),
          children: [
          // ────────────────────────────────────────────────────
          // About
          // ────────────────────────────────────────────────────
          _sectionHeader('ABOUT'),
          _sectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(RadiusTokens.card),
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 52,
                        height: 52,
                        errorBuilder: (_, _, _) => Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(RadiusTokens.card),
                            gradient: const LinearGradient(
                              colors: AppColors.gradientPrimary,
                            ),
                          ),
                          child: const Icon(Icons.public, color: AppColors.ink, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vertiege',
                            style: TextStyle(
                              fontSize: FontSizes.headingCard,
                              fontWeight: FontWeights.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Version 1.0.0 (build 1)',
                            style: TextStyle(
                              fontSize: FontSizes.caption,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Made with Flutter & Supabase',
                            style: TextStyle(
                              fontSize: FontSizes.caption,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _sectionDivider(),
              ListTile(
                leading: const Icon(Icons.celebration, size: IconSizes.md),
                title: const Text('Credits'),
                subtitle: const Text('The people behind Vertiege'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: _showCreditsDialog,
              ),
            ],
          ),

          // ────────────────────────────────────────────────────
          // Moderation
          // ────────────────────────────────────────────────────
          _sectionHeader('MODERATION'),
          _sectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.verified_user, size: IconSizes.md),
                title: const Text('Verification Review'),
                subtitle: const Text('Review pending profession verification requests'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: () => context.push('/admin/verifications'),
              ),
            ],
          ),

          // ────────────────────────────────────────────────────
          // Account
          // ────────────────────────────────────────────────────
          _sectionHeader('ACCOUNT'),
          _sectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined, size: IconSizes.md),
                title: const Text('Change Email'),
                subtitle: const Text('Update your email address'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: _showChangeEmailDialog,
              ),
              _sectionDivider(),
              ListTile(
                leading: const Icon(Icons.lock_outline, size: IconSizes.md),
                title: const Text('Change Password'),
                subtitle: const Text('Update your password'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: _showChangePasswordDialog,
              ),
              _sectionDivider(),
              ListTile(
                leading: const Icon(Icons.security, size: IconSizes.md, color: AppColors.tertiary),
                title: const Text('Twin Seal (2FA)'),
                subtitle: const Text('Add an extra layer of security'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: _showTwinSealSetup,
              ),
              _sectionDivider(),
              ListTile(
                leading: Icon(Icons.delete_outline, size: IconSizes.md, color: AppColors.error),
                title: Text('Delete Account', style: TextStyle(color: AppColors.error)),
                subtitle: const Text('Permanently remove your account'),
                trailing: Icon(Icons.chevron_right, size: IconSizes.md, color: AppColors.error),
                onTap: _showDeleteAccountDialog,
              ),
            ],
          ),

          // ────────────────────────────────────────────────────
          // Notifications
          // ────────────────────────────────────────────────────
          _sectionHeader('NOTIFICATIONS'),
          _sectionCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active, size: IconSizes.md),
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive push notifications'),
                value: _pushEnabled,
                onChanged: _prefsLoaded
                    ? (v) {
                        setState(() => _pushEnabled = v);
                        _setNotificationPref(_kPrefPushEnabled, v);
                      }
                    : null,
              ),
              _sectionDivider(),
              SwitchListTile(
                secondary: const Icon(Icons.favorite_border, size: IconSizes.md),
                title: const Text('Likes'),
                subtitle: const Text('When someone likes your post'),
                value: _likesEnabled,
                onChanged: _prefsLoaded
                    ? (v) {
                        setState(() => _likesEnabled = v);
                        _setNotificationPref(_kPrefLikesEnabled, v);
                      }
                    : null,
              ),
              _sectionDivider(),
              SwitchListTile(
                secondary: const Icon(Icons.mode_comment_outlined, size: IconSizes.md),
                title: const Text('Comments'),
                subtitle: const Text('When someone comments on your post'),
                value: _commentsEnabled,
                onChanged: _prefsLoaded
                    ? (v) {
                        setState(() => _commentsEnabled = v);
                        _setNotificationPref(_kPrefCommentsEnabled, v);
                      }
                    : null,
              ),
              _sectionDivider(),
              SwitchListTile(
                secondary: const Icon(Icons.public, size: IconSizes.md),
                title: const Text('World Invites'),
                subtitle: const Text('When invited to a new world'),
                value: _worldInvitesEnabled,
                onChanged: _prefsLoaded
                    ? (v) {
                        setState(() => _worldInvitesEnabled = v);
                        _setNotificationPref(_kPrefWorldInvitesEnabled, v);
                      }
                    : null,
              ),
              _sectionDivider(),
              SwitchListTile(
                secondary: const Icon(Icons.military_tech, size: IconSizes.md),
                title: const Text('Tier Upgrades'),
                subtitle: const Text('When your tier level changes'),
                value: _tierUpgradesEnabled,
                onChanged: _prefsLoaded
                    ? (v) {
                        setState(() => _tierUpgradesEnabled = v);
                        _setNotificationPref(_kPrefTierUpgradesEnabled, v);
                      }
                    : null,
              ),
            ],
          ),

          // ────────────────────────────────────────────────────
          // Appearance
          // ────────────────────────────────────────────────────
          _sectionHeader('APPEARANCE'),
          _sectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.palette, size: IconSizes.md),
                        SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Theme', style: TextStyle(fontSize: FontSizes.body)),
                              Text(
                                'Light, dark, or follow system',
                                style: TextStyle(fontSize: FontSizes.body),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SegmentedButton<ThemeScheme>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeScheme.system,
                            label: Text('Auto'),
                            icon: Icon(Icons.brightness_auto, size: IconSizes.sm),
                          ),
                          ButtonSegment(
                            value: ThemeScheme.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode, size: IconSizes.sm),
                          ),
                          ButtonSegment(
                            value: ThemeScheme.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode, size: IconSizes.sm),
                          ),
                        ],
                        selected: {themeState.scheme},
                        onSelectionChanged: (scheme) {
                          ref.read(themeProvider.notifier).setScheme(scheme.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _sectionDivider(),
              ListTile(
                leading: const Icon(Icons.text_fields, size: IconSizes.md),
                title: const Text('Text Size'),
                subtitle: Text(_textSize.label),
                trailing: DropdownButton<_TextSize>(
                  value: _textSize,
                  underline: const SizedBox.shrink(),
                  items: _TextSize.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _setTextSize(v);
                  },
                ),
              ),
            ],
          ),

          // ────────────────────────────────────────────────────
          // Privacy & Legal
          // ────────────────────────────────────────────────────
          _sectionHeader('PRIVACY & LEGAL'),
          _sectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, size: IconSizes.md),
                title: const Text('Privacy Policy'),
                subtitle: const Text('How we handle your data'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: _showPrivacyPolicyDialog,
              ),
              _sectionDivider(),
              ListTile(
                leading: const Icon(Icons.gavel_outlined, size: IconSizes.md),
                title: const Text('Terms of Service'),
                subtitle: const Text('Rules for using Vertiege'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: _showTermsDialog,
              ),
              _sectionDivider(),
              ListTile(
                leading: const Icon(Icons.article_outlined, size: IconSizes.md),
                title: const Text('Open Source Licenses'),
                subtitle: const Text('Third-party software licenses'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Vertiege',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Copyright 2025 Vertiege',
                ),
              ),
            ],
          ),

          // ────────────────────────────────────────────────────
          // Data
          // ────────────────────────────────────────────────────
          _sectionHeader('DATA'),
          _sectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.backup, size: IconSizes.md),
                title: const Text('Create Backup'),
                subtitle: const Text('Export all app data as JSON'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: () async {
                  await BackupService.createBackup();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup created successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              _sectionDivider(),
              ListTile(
                leading: const Icon(Icons.restore, size: IconSizes.md),
                title: const Text('Restore Backup'),
                subtitle: const Text('Import previously saved data'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: _showRestoreBackupDialog,
              ),
              _sectionDivider(),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined, size: IconSizes.md),
                title: const Text('Clear Cache'),
                subtitle: Text('Frees up ~${_formatBytes(_cacheSizeBytes)}'),
                trailing: const Icon(Icons.chevron_right, size: IconSizes.md),
                onTap: _cacheSizeBytes > 0 ? _clearCache : null,
                enabled: _cacheSizeBytes > 0,
              ),
            ],
          ),

          // ────────────────────────────────────────────────────
          // Danger Zone
          // ────────────────────────────────────────────────────
          _sectionHeader('DANGER ZONE'),
          _sectionCard(
            children: [
              ListTile(
                leading: Icon(Icons.delete_forever, size: IconSizes.md, color: AppColors.error),
                title: Text('Reset All Data', style: TextStyle(color: AppColors.error)),
                subtitle: Text(
                  'Clear all local data and start fresh',
                  style: TextStyle(color: AppColors.error.withValues(alpha: 0.7)),
                ),
                trailing: Icon(Icons.chevron_right, size: IconSizes.md, color: AppColors.error),
                onTap: _showResetDataDialog,
              ),
            ],
          ),

          const SizedBox(height: Spacing.lg),
        ],
      ),
    ),
  );
  }
}

// ──────────────────────────────────────────────────────────────────
// Two-step reset confirmation dialog
// ──────────────────────────────────────────────────────────────────
class _ResetDataConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirmed;

  const _ResetDataConfirmationDialog({required this.onConfirmed});

  @override
  State<_ResetDataConfirmationDialog> createState() => _ResetDataConfirmationDialogState();
}

class _ResetDataConfirmationDialogState extends State<_ResetDataConfirmationDialog> {
  int _step = 0; // 0 = first confirm, 1 = type RESET

  final _confirmController = TextEditingController();
  String _typedText = '';

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _goToStep2() => setState(() => _step = 1);

  void _goBack() => setState(() {
        _step = 0;
        _typedText = '';
        _confirmController.clear();
      });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: Spacing.sm),
          Text('Reset all data?', style: TextStyle(color: AppColors.error)),
        ],
      ),
      content: _step == 0
          ? const Text(
              'This will permanently delete all local data including posts, notifications, '
              'achievements, and preferences. Your account will not be deleted, but all cached data will be gone.\n\n'
              'This action cannot be undone.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you absolutely sure?',
                  style: TextStyle(fontWeight: FontWeights.bold),
                ),
                const SizedBox(height: Spacing.md),
                const Text('Type RESET to confirm:'),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: _confirmController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Type RESET',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error),
                    ),
                    filled: true,
                    fillColor: AppColors.glassBackground,
                  ),
                  onChanged: (v) => setState(() => _typedText = v),
                ),
              ],
            ),
      actions: _step == 0
          ? [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: _goToStep2,
                child: const Text('Continue'),
              ),
            ]
          : [
              TextButton(onPressed: _goBack, child: const Text('Back')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: _typedText.trim() == 'RESET' ? widget.onConfirmed : null,
                child: const Text('Reset Everything'),
              ),
            ],
    );
  }
}
