import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/theme_provider.dart';
import '../state/resident_provider.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/supabase.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import 'twin_seal_setup_screen.dart';
import '../ui/icons/v_icons.dart';
import '../ui/buttons/v_button.dart';

const _kPrefPushEnabled = 'settings_push_enabled';
const _kPrefLikesEnabled = 'settings_likes_enabled';
const _kPrefCommentsEnabled = 'settings_comments_enabled';
const _kPrefWorldInvitesEnabled = 'settings_world_invites_enabled';
const _kPrefTierUpgradesEnabled = 'settings_tier_upgrades_enabled';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushEnabled = true;
  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _worldInvitesEnabled = true;
  bool _tierUpgradesEnabled = true;
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
      _prefsLoaded = true;
    });
  }

  Future<void> _setNotificationPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _estimateCacheSize() {
    final paintingBinding = PaintingBinding.instance;
    final cache = paintingBinding.imageCache;
    final current = cache.currentSize;
    const averagePerImage = 150 * 1024;
    final estimated = (current * averagePerImage).clamp(0, 50 * 1024 * 1024);
    if (_cacheSizeBytes != estimated) {
      _cacheSizeBytes = estimated;
    }
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

  void _showCreditsDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Credits'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vertiege',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              const Text('A tier-gated social network built with love.'),
              const SizedBox(height: VSpacing.md),
              Text(
                'Design & Development',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text('The Vertiege Team'),
              const SizedBox(height: VSpacing.md),
              Text(
                'Special Thanks',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text('Flutter Community'),
              const Text('Supabase Team'),
              const Text('All our beta testers'),
            ],
          ),
        ),
        actions: [
          VButton(
            label: 'Close',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'New email address',
            prefixIcon: const Icon(Icons.email_outlined),
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
          ),
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Update',
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;
              try {
                final client = getSupabase();
                await client.auth.updateUser(UserAttributes(email: email));
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Check your new email to confirm the change',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update email: $e'),
                      backgroundColor: VColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                decoration: InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: const Icon(Icons.lock_outline),
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
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: VSpacing.sm),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New password',
                  prefixIcon: const Icon(VIcons.lock),
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
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: VSpacing.sm),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: const Icon(VIcons.lock),
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
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Change',
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final client = getSupabase();
                await client.auth.updateUser(
                  UserAttributes(password: newController.text),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update password: $e'),
                      backgroundColor: VColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final controller = TextEditingController();
    String confirmText = '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Delete Account', style: TextStyle(color: VColors.error)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone. All your data, posts, and memberships will be permanently removed.',
              ),
              const SizedBox(height: VSpacing.md),
              Text(
                'Type DELETE to confirm',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type DELETE here',
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
                      color: VColors.error,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (v) => setDialogState(() => confirmText = v),
              ),
            ],
          ),
          actions: [
            VButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(ctx),
              variant: ButtonVariant.text,
            ),
            VButton(
              label: 'Delete My Account',
              onPressed: confirmText.trim() == 'DELETE'
                  ? () async {
                      try {
                        final client = getSupabase();
                        final user = client.auth.currentUser;
                        if (user != null) {
                          await client.functions.invoke('delete-account');
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          await AuthService.signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete account: $e'),
                              backgroundColor: VColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Last updated: May 2025', style: theme.textTheme.bodySmall),
              const SizedBox(height: VSpacing.md),
              Text(
                'Information We Collect',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text(
                'We collect information you provide directly, such as your profile data, posts, and interactions.',
              ),
              const SizedBox(height: VSpacing.md),
              Text(
                'How We Use Your Data',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text(
                'Your data is used to provide and improve Vertiege services, personalize your experience, '
                'and communicate important updates. We never sell your personal data.',
              ),
              const SizedBox(height: VSpacing.md),
              Text(
                'Data Storage & Security',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text(
                'Data is stored securely using Supabase infrastructure with encryption at rest and in transit.',
              ),
              const SizedBox(height: VSpacing.md),
              Text(
                'Contact',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text('privacy@vertiege.app'),
            ],
          ),
        ),
        actions: [
          VButton(
            label: 'Close',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Last updated: May 2025', style: theme.textTheme.bodySmall),
              const SizedBox(height: VSpacing.md),
              Text(
                '1. Acceptance of Terms',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text(
                'By using Vertiege, you agree to these terms. If you do not agree, do not use the service.',
              ),
              const SizedBox(height: VSpacing.md),
              Text(
                '2. User Conduct',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text(
                'Users must follow community guidelines within each world. Harassment, spam, '
                'and illegal content are prohibited.',
              ),
              const SizedBox(height: VSpacing.md),
              Text(
                '3. Content Ownership',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text(
                'You retain ownership of content you create. By posting, you grant Vertiege a license '
                'to display and distribute your content within the platform.',
              ),
              const SizedBox(height: VSpacing.md),
              Text(
                '4. Limitation of Liability',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              const Text(
                'Vertiege is provided "as is" without warranties. We are not liable for damages '
                'arising from use of the service.',
              ),
            ],
          ),
        ),
        actions: [
          VButton(
            label: 'Close',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
        ],
      ),
    );
  }

  void _showRestoreBackupDialog() {
    final controller = TextEditingController();
    String? validationError;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
              const SizedBox(height: VSpacing.md),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Paste JSON here...',
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
                  errorText: validationError,
                  contentPadding: const EdgeInsets.all(VSpacing.md),
                ),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: VFontSize.bodyMd,
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
            VButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(ctx),
              variant: ButtonVariant.text,
            ),
            VButton(
              label: 'Validate & Restore',
              onPressed: () async {
                final raw = controller.text.trim();
                if (raw.isEmpty) {
                  setDialogState(
                    () => validationError = 'Please paste backup JSON',
                  );
                  return;
                }
                try {
                  final parsed = jsonDecode(raw);
                  if (parsed is! Map<String, dynamic>) {
                    setDialogState(
                      () =>
                          validationError = 'Invalid JSON: expected an object',
                    );
                    return;
                  }
                  if (!parsed.containsKey('backup')) {
                    setDialogState(
                      () => validationError =
                          'Missing "backup" key — not a valid backup file',
                    );
                    return;
                  }
                  if (parsed['backup'] is! Map<String, dynamic>) {
                    setDialogState(
                      () => validationError = '"backup" must be an object',
                    );
                    return;
                  }
                } catch (e) {
                  setDialogState(
                    () => validationError = 'Invalid JSON: ${e.toString()}',
                  );
                  return;
                }
                final success = await BackupService.restoreBackup(raw);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Backup restored successfully'
                            : 'Restore failed — data may be corrupted',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDataDialog() {
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

  Widget _sectionHeader(String title, bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.md,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: VFontWeight.bold,
          letterSpacing: 0.5,
          color: VColors.primary,
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children, required bool isDark}) {
    _estimateCacheSize();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? VColors.surfaceContainerDark
              : VColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VRadius.lg),
          border: Border.all(
            color: isDark
                ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                : VColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _sectionDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: VSpacing.lg + VSpacing.sm,
      color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadPrefs(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: VSpacing.xxl),
          children: [
            _sectionHeader('ABOUT', isDark),
            _sectionCard(
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.all(VSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(VRadius.lg),
                          gradient: VColors.gradientPrimary,
                        ),
                        child: const Icon(
                          Icons.public,
                          color: VColors.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: VSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vertiege',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: VFontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Version 1.0.0 (build 1)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Made with Flutter & Supabase',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionDivider(isDark),
                ListTile(
                  leading: const Icon(Icons.celebration, size: VIconSize.md),
                  title: const Text('Credits'),
                  subtitle: const Text('The people behind Vertiege'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: _showCreditsDialog,
                ),
              ],
            ),

            _sectionHeader('MODERATION', isDark),
            _sectionCard(
              isDark: isDark,
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user, size: VIconSize.md),
                  title: const Text('Verification Review'),
                  subtitle: const Text(
                    'Review pending profession verification requests',
                  ),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: () => context.push('/admin/verifications'),
                ),
              ],
            ),

            _sectionHeader('ACCOUNT', isDark),
            _sectionCard(
              isDark: isDark,
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined, size: VIconSize.md),
                  title: const Text('Change Email'),
                  subtitle: const Text('Update your email address'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: _showChangeEmailDialog,
                ),
                _sectionDivider(isDark),
                ListTile(
                  leading: const Icon(Icons.lock_outline, size: VIconSize.md),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your password'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: _showChangePasswordDialog,
                ),
                _sectionDivider(isDark),
                ListTile(
                  leading: const Icon(
                    Icons.security,
                    size: VIconSize.md,
                    color: VColors.tertiary,
                  ),
                  title: const Text('Twin Seal (2FA)'),
                  subtitle: const Text('Add an extra layer of security'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TwinSealSetupScreen(),
                      ),
                    );
                  },
                ),
                _sectionDivider(isDark),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    size: VIconSize.md,
                    color: VColors.error,
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: VColors.error),
                  ),
                  subtitle: const Text('Permanently remove your account'),
                  trailing: const Icon(
                    VIcons.chevronRight,
                    size: VIconSize.md,
                    color: VColors.error,
                  ),
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),

            _sectionHeader('NOTIFICATIONS', isDark),
            _sectionCard(
              isDark: isDark,
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_active,
                    size: VIconSize.md,
                  ),
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
                _sectionDivider(isDark),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.favorite_border,
                    size: VIconSize.md,
                  ),
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
                _sectionDivider(isDark),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.mode_comment_outlined,
                    size: VIconSize.md,
                  ),
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
                _sectionDivider(isDark),
                SwitchListTile(
                  secondary: const Icon(VIcons.globe, size: VIconSize.md),
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
                _sectionDivider(isDark),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.military_tech,
                    size: VIconSize.md,
                  ),
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

            _sectionHeader('APPEARANCE', isDark),
            _sectionCard(
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.palette, size: VIconSize.md),
                          const SizedBox(width: VSpacing.md),
                          Text(
                            'Theme',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: VFontWeight.medium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VSpacing.sm),
                      Text(
                        'Light, dark, or follow system',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: VSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SegmentedButton<ThemeScheme>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeScheme.system,
                              label: Text('Auto'),
                              icon: Icon(
                                Icons.brightness_auto,
                                size: VIconSize.sm,
                              ),
                            ),
                            ButtonSegment(
                              value: ThemeScheme.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode, size: VIconSize.sm),
                            ),
                            ButtonSegment(
                              value: ThemeScheme.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode, size: VIconSize.sm),
                            ),
                          ],
                          selected: {themeState.scheme},
                          onSelectionChanged: (scheme) {
                            ref
                                .read(themeProvider.notifier)
                                .setScheme(scheme.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionDivider(isDark),
                Consumer(
                  builder: (context, ref, _) {
                    final themeState = ref.watch(themeProvider);
                    final textSize = themeState.textSize;
                    return Padding(
                      padding: const EdgeInsets.all(VSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.text_fields, size: VIconSize.md),
                              const SizedBox(width: VSpacing.md),
                              Text(
                                'Text Size',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: VSpacing.sm),
                          Text(
                            'Adjust the application text size',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? VColors.onSurfaceVariantDark
                                      : VColors.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: VSpacing.md),
                          FSelect<TextSize>.rich(
                            format: (value) =>
                                value.name[0].toUpperCase() +
                                value.name.substring(1),
                            control: FSelectControl.lifted(
                              value: textSize,
                              onChange: (v) {
                                if (v != null) {
                                  ref
                                      .read(themeProvider.notifier)
                                      .setTextSize(v);
                                }
                              },
                            ),
                            children: TextSize.values
                                .map(
                                  (t) => FSelectItem<TextSize>(
                                    value: t,
                                    title: Text(
                                      t.name[0].toUpperCase() +
                                          t.name.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            Consumer(
              builder: (context, ref, _) {
                final resident = ref.watch(residentProvider).resident;
                if (resident == null) return const SizedBox.shrink();

                final notifier = ref.read(residentProvider.notifier);
                final multiplier = notifier.xpMultiplier;
                final coinBonus = notifier.dailyCoinBonus;
                final reactionSlots = notifier.customReactionSlots;
                final pinLimit = notifier.postPinLimit;
                final worldLimit = notifier.worldCreationLimit;
                final hasLounge = resident.tier.value >= 3;
                final hasVote = resident.tier.value >= 4;

                return Column(
                  children: [
                    _sectionHeader('TIER PERKS', isDark),
                    _sectionCard(
                      isDark: isDark,
                      children: [
                        _PerkTile(
                          icon: Icons.trending_up,
                          title: 'XP Multiplier',
                          value: 'x${multiplier.toStringAsFixed(2)}',
                          isDark: isDark,
                        ),
                        _sectionDivider(isDark),
                        _PerkTile(
                          icon: Icons.monetization_on,
                          title: 'Daily Coin Bonus',
                          value: '+$coinBonus',
                          isDark: isDark,
                        ),
                        _sectionDivider(isDark),
                        _PerkTile(
                          icon: Icons.emoji_emotions,
                          title: 'Custom Reactions',
                          value: '$reactionSlots slots',
                          isDark: isDark,
                        ),
                        _sectionDivider(isDark),
                        _PerkTile(
                          icon: Icons.push_pin,
                          title: 'Post Pins',
                          value: pinLimit > 0
                              ? '$pinLimit available'
                              : 'Locked',
                          isDark: isDark,
                        ),
                        _sectionDivider(isDark),
                        _PerkTile(
                          icon: Icons.language,
                          title: 'World Creation',
                          value: '$worldLimit worlds',
                          isDark: isDark,
                        ),
                        _sectionDivider(isDark),
                        _PerkTile(
                          icon: Icons.local_bar,
                          title: 'Lounge Access',
                          value: hasLounge ? 'Unlocked' : 'Locked',
                          isDark: isDark,
                        ),
                        _sectionDivider(isDark),
                        _PerkTile(
                          icon: Icons.how_to_vote,
                          title: 'Governance Vote',
                          value: hasVote ? 'Unlocked' : 'Locked',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            _sectionHeader('PRIVACY & LEGAL', isDark),
            _sectionCard(
              isDark: isDark,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    size: VIconSize.md,
                  ),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('How we handle your data'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: _showPrivacyPolicyDialog,
                ),
                _sectionDivider(isDark),
                ListTile(
                  leading: const Icon(VIcons.gavel, size: VIconSize.md),
                  title: const Text('Terms of Service'),
                  subtitle: const Text('Rules for using Vertiege'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: _showTermsDialog,
                ),
                _sectionDivider(isDark),
                ListTile(
                  leading: const Icon(
                    Icons.article_outlined,
                    size: VIconSize.md,
                  ),
                  title: const Text('Open Source Licenses'),
                  subtitle: const Text('Third-party software licenses'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Vertiege',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Copyright 2025 Vertiege',
                  ),
                ),
              ],
            ),

            _sectionHeader('DATA', isDark),
            _sectionCard(
              isDark: isDark,
              children: [
                ListTile(
                  leading: const Icon(Icons.backup, size: VIconSize.md),
                  title: const Text('Create Backup'),
                  subtitle: const Text('Export all app data as JSON'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
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
                _sectionDivider(isDark),
                ListTile(
                  leading: const Icon(Icons.restore, size: VIconSize.md),
                  title: const Text('Restore Backup'),
                  subtitle: const Text('Import previously saved data'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: _showRestoreBackupDialog,
                ),
                _sectionDivider(isDark),
                ListTile(
                  leading: const Icon(
                    Icons.cleaning_services_outlined,
                    size: VIconSize.md,
                  ),
                  title: const Text('Clear Cache'),
                  subtitle: Text('Frees up ~${_formatBytes(_cacheSizeBytes)}'),
                  trailing: const Icon(VIcons.chevronRight, size: VIconSize.md),
                  onTap: _cacheSizeBytes > 0 ? _clearCache : null,
                  enabled: _cacheSizeBytes > 0,
                ),
              ],
            ),

            _sectionHeader('DANGER ZONE', isDark),
            _sectionCard(
              isDark: isDark,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    size: VIconSize.md,
                    color: VColors.error,
                  ),
                  title: const Text(
                    'Reset All Data',
                    style: TextStyle(color: VColors.error),
                  ),
                  subtitle: Text(
                    'Clear all local data and start fresh',
                    style: TextStyle(
                      color: VColors.error.withValues(alpha: 0.7),
                    ),
                  ),
                  trailing: const Icon(
                    VIcons.chevronRight,
                    size: VIconSize.md,
                    color: VColors.error,
                  ),
                  onTap: _showResetDataDialog,
                ),
              ],
            ),

            const SizedBox(height: VSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PerkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _PerkTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: VIconSize.sm, color: VColors.tertiary),
          const SizedBox(width: VSpacing.md),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: value.contains('Locked')
                  ? (isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant)
                  : VColors.tertiary,
              fontWeight: VFontWeight.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetDataConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirmed;

  const _ResetDataConfirmationDialog({required this.onConfirmed});

  @override
  State<_ResetDataConfirmationDialog> createState() =>
      _ResetDataConfirmationDialogState();
}

class _ResetDataConfirmationDialogState
    extends State<_ResetDataConfirmationDialog> {
  int _step = 0;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: VColors.error),
          SizedBox(width: VSpacing.sm),
          Text('Reset all data?', style: TextStyle(color: VColors.error)),
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
                Text(
                  'Are you absolutely sure?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
                const SizedBox(height: VSpacing.md),
                const Text('Type RESET to confirm:'),
                const SizedBox(height: VSpacing.sm),
                TextField(
                  controller: _confirmController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Type RESET',
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
                        color: VColors.error,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() => _typedText = v),
                ),
              ],
            ),
      actions: _step == 0
          ? [
              VButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
                variant: ButtonVariant.text,
              ),
              VButton(label: 'Continue', onPressed: _goToStep2),
            ]
          : [
              VButton(
                label: 'Back',
                onPressed: _goBack,
                variant: ButtonVariant.text,
              ),
              VButton(
                label: 'Reset Everything',
                onPressed: _typedText.trim() == 'RESET'
                    ? widget.onConfirmed
                    : null,
              ),
            ],
    );
  }
}
