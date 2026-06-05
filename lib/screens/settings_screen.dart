import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/build_info.dart';
import '../config/platform_label.dart';
import '../state/theme_provider.dart';
import '../state/resident_provider.dart';
import '../services/storage_service.dart';
import '../services/admin_access_service.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/device_permission_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/push_token_service.dart';
import '../services/mutation_outbox_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/supabase.dart';
import '../services/world_nav_prefs.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../ui/icons/v_icons.dart';
import 'package:vertiege/ui/ui.dart';
import '../widgets/core/v_feedback.dart';
import '../widgets/core/v_theme_scheme_picker.dart';

const _kPrefPushEnabled = 'settings_push_enabled';
const _kPrefLikesEnabled = 'settings_likes_enabled';
const _kPrefCommentsEnabled = 'settings_comments_enabled';
const _kPrefWorldInvitesEnabled = 'settings_world_invites_enabled';
const _kPrefMemberOpensOnFeed = WorldNavPrefs.memberOpensOnFeedKey;
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
  bool _memberOpensOnFeed = true;
  bool _tierUpgradesEnabled = true;
  int _cacheSizeBytes = 0;
  int _failedOutboxCount = 0;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _estimateCacheSize();
    _loadFailedOutboxCount();
  }

  Future<void> _loadFailedOutboxCount() async {
    final failed = await MutationOutboxService.getFailed();
    if (!mounted) return;
    setState(() => _failedOutboxCount = failed.length);
  }

  Future<void> _discardFailedOutbox() async {
    await MutationOutboxService.discardFailed();
    await _loadFailedOutboxCount();
    if (!mounted) return;
    VFeedback.showMessage(context, 'Discarded failed sync items');
  }

  Future<void> _loadPrefs() async {
    await NotificationPreferencesService.pullFromServer();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushEnabled = prefs.getBool(_kPrefPushEnabled) ?? true;
      _likesEnabled = prefs.getBool(_kPrefLikesEnabled) ?? true;
      _commentsEnabled = prefs.getBool(_kPrefCommentsEnabled) ?? true;
      _worldInvitesEnabled = prefs.getBool(_kPrefWorldInvitesEnabled) ?? true;
      _memberOpensOnFeed = prefs.getBool(_kPrefMemberOpensOnFeed) ?? true;
      _tierUpgradesEnabled = prefs.getBool(_kPrefTierUpgradesEnabled) ?? true;
      _prefsLoaded = true;
    });
  }

  Future<void> _setNotificationPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (key == _kPrefPushEnabled) {
      await StorageService.setString(
        _kPrefPushEnabled,
        value ? 'true' : 'false',
      );
    }
    await _syncNotificationPrefToServer(key, value);
  }

  Future<void> _syncNotificationPrefToServer(String key, bool value) async {
    await NotificationPreferencesService.pushToServer(
      likesEnabled: key == _kPrefLikesEnabled ? value : null,
      commentsEnabled: key == _kPrefCommentsEnabled ? value : null,
      worldInvitesEnabled: key == _kPrefWorldInvitesEnabled ? value : null,
      tierUpgradesEnabled: key == _kPrefTierUpgradesEnabled ? value : null,
      pushEnabled: key == _kPrefPushEnabled ? value : null,
    );
  }

  Future<void> _onPushToggleChanged(bool enabled) async {
    if (enabled && FirebaseBootstrap.isInitialized) {
      final granted = await DevicePermissionService.requestNotifications();
      if (!granted) {
        if (!mounted) return;
        await DevicePermissionService.showPermissionDeniedSheet(
          context,
          title: 'Enable notifications',
          message:
              'Push alerts are turned off at the OS level. Open Settings to allow Vertiege notifications.',
        );
        return;
      }
      final resident = ref.read(residentProvider).resident;
      if (granted && resident != null) {
        unawaited(PushTokenService.registerForResident(resident.id));
      }
    }
    if (!mounted) return;
    setState(() => _pushEnabled = enabled);
    await _setNotificationPref(_kPrefPushEnabled, enabled);
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
      VFeedback.showMessage(context, 'Image cache cleared');
    }
  }

  void _showCreditsDialog() {
    final theme = Theme.of(context);
    showVDialog(
      context: context,
      title: 'Credits',
      scrollContent: true,
      content: Column(
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
      actions: [
        vDialogActionsRow([
          VButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.text,
          ),
        ]),
      ],
    );
  }

  void _showChangeEmailDialog() {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showVDialog(
      context: context,
      title: 'Change Email',
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
        vDialogActionsRow([
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Update',
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;
              try {
                final client = maybeSupabase();
                if (client == null) {
                  if (context.mounted) {
                    VFeedback.showError(
                      context,
                      'Cloud sync is unavailable. Check your connection and try again.',
                    );
                  }
                  return;
                }
                await client.auth.updateUser(UserAttributes(email: email));
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  VFeedback.showMessage(
                    context,
                    'Check your new email to confirm the change',
                  );
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  VFeedback.showError(context, 'Failed to update email: $e');
                }
              }
            },
          ),
        ]),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showVDialog(
      context: context,
      title: 'Change Password',
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
        vDialogActionsRow([
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Change',
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final client = maybeSupabase();
                if (client == null) {
                  if (context.mounted) {
                    VFeedback.showError(
                      context,
                      'Cloud sync is unavailable. Check your connection and try again.',
                    );
                  }
                  return;
                }
                await client.auth.updateUser(
                  UserAttributes(password: newController.text),
                );
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  VFeedback.showMessage(
                    context,
                    'Password changed successfully',
                  );
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  VFeedback.showError(context, 'Failed to update password: $e');
                }
              }
            },
          ),
        ]),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    final controller = TextEditingController();
    String confirmText = '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showVDialog(
      context: context,
      title: 'Delete Account',
      titleStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: VFontWeight.bold,
        color: VColors.error,
      ),
      content: StatefulBuilder(
        builder: (ctx, setDialogState) => Column(
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
                  borderSide: const BorderSide(color: VColors.error, width: 2),
                ),
              ),
              onChanged: (v) => setDialogState(() => confirmText = v),
            ),
            const SizedBox(height: VSpacing.lg),
            vDialogActionsRow([
              VButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
                variant: ButtonVariant.text,
              ),
              VButton(
                label: 'Delete My Account',
                onPressed: confirmText.trim() == 'DELETE'
                    ? () async {
                        try {
                          final client = maybeSupabase();
                          if (client == null) {
                            if (context.mounted) {
                              VFeedback.showError(
                                context,
                                'Cloud sync is unavailable. Check your connection and try again.',
                              );
                            }
                            return;
                          }
                          final user = client.auth.currentUser;
                          if (user != null) {
                            await client.functions.invoke('delete-account');
                          }
                          if (context.mounted) Navigator.pop(context);
                          if (context.mounted) {
                            await AuthService.signOut(ref: ref);
                            if (context.mounted) {
                              context.go('/login');
                            }
                          }
                        } catch (e) {
                          if (context.mounted) Navigator.pop(context);
                          if (context.mounted) {
                            VFeedback.showError(
                              context,
                              'Failed to delete account: $e',
                            );
                          }
                        }
                      }
                    : null,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showRestoreBackupDialog() {
    final controller = TextEditingController();
    String? validationError;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showVDialog(
      context: context,
      title: 'Restore Backup',
      content: StatefulBuilder(
        builder: (ctx, setDialogState) => Column(
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
            const SizedBox(height: VSpacing.lg),
            vDialogActionsRow([
              VButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
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
                        () => validationError =
                            'Invalid JSON: expected an object',
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
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (mounted) {
                    VFeedback.showMessage(
                      context,
                      success
                          ? 'Backup restored successfully'
                          : 'Restore failed — data may be corrupted',
                    );
                  }
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showResetDataDialog() {
    final router = GoRouter.of(context);
    showFDialog(
      context: context,
      builder: (ctx, style, animation) => FDialog.raw(
        builder: (context, dialogStyle) => _ResetDataConfirmationDialog(
          onConfirmed: () async {
            await StorageService.clearAll();
            if (ctx.mounted) Navigator.pop(ctx);
            ref.read(themeProvider.notifier).setScheme(ThemeScheme.system);
            router.go('/onboarding');
          },
        ),
      ),
    );
  }

  Widget _appearancePanel({
    required ThemeData theme,
    required bool isDark,
    required ThemeScheme scheme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(VSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                size: VIconSize.md,
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
              const SizedBox(width: VSpacing.md),
              Text(
                'Theme',
                style: TextStyle(
                  fontSize: VFontSize.bodyMd,
                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          VThemeSchemePicker(
            scheme: scheme,
            onChanged: (s) => ref.read(themeProvider.notifier).setScheme(s),
          ),
          const SizedBox(height: VSpacing.md),
          Row(
            children: [
              Icon(
                Icons.text_fields,
                size: VIconSize.md,
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
              const SizedBox(width: VSpacing.md),
              Text(
                'Text Size',
                style: TextStyle(
                  fontSize: VFontSize.bodyMd,
                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          Consumer(
            builder: (context, ref, _) {
              final textSize = ref.watch(themeProvider).textSize;
              final highContrast =
                  textSize == TextSize.large || textSize == TextSize.xlarge;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FSelect<TextSize>.rich(
                    format: (value) =>
                        value.name[0].toUpperCase() + value.name.substring(1),
                    control: FSelectControl.lifted(
                      value: textSize,
                      onChange: (v) {
                        if (v != null) {
                          ref.read(themeProvider.notifier).setTextSize(v);
                        }
                      },
                    ),
                    children: TextSize.values
                        .map(
                          (t) => FSelectItem<TextSize>(
                            value: t,
                            title: Text(
                              t.name[0].toUpperCase() + t.name.substring(1),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.contrast,
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: VSpacing.md),
                      Expanded(
                        child: Text(
                          'High contrast text',
                          style: TextStyle(
                            fontSize: VFontSize.bodyMd,
                            color: isDark
                                ? VColors.onSurfaceDark
                                : VColors.onSurface,
                          ),
                        ),
                      ),
                      FSwitch(
                        value: highContrast,
                        onChange: (enabled) {
                          ref
                              .read(themeProvider.notifier)
                              .setTextSize(
                                enabled ? TextSize.large : TextSize.medium,
                              );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _estimateCacheSize();
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final variantColor = isDark
        ? VColors.onSurfaceVariantDark
        : VColors.onSurfaceVariant;

    return VHubPage(
      title: 'Settings',
      showBack: true,
      body: RefreshIndicator(
        onRefresh: () async => _loadPrefs(),
        child: ListView(
          padding: const EdgeInsets.all(VSpacing.md),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            VSectionList(
              title: 'About',
              children: [
                FTile(
                  title: Text(
                    'Version $kAppVersionLabel',
                    style: TextStyle(
                      fontSize: VFontSize.bodySm,
                      color: variantColor,
                    ),
                  ),
                  subtitle: Text(
                    'Build $kAppBuildNumber · $kPlatformBuildLabel',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: variantColor,
                    ),
                  ),
                ),
                VSectionTile(
                  icon: Icons.celebration,
                  label: 'Credits',
                  onTap: _showCreditsDialog,
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            VSectionList(
              title: 'Account',
              children: [
                if (AdminAccessService.isCurrentSessionVerifier())
                  VSectionTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Staff review',
                    onTap: () => context.push('/verifier/review'),
                  ),
                VSectionTile(
                  icon: Icons.email_outlined,
                  label: 'Change Email',
                  onTap: _showChangeEmailDialog,
                ),
                VSectionTile(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: _showChangePasswordDialog,
                ),
                VSectionTile(
                  icon: Icons.security,
                  label: 'Twin Seal (2FA)',
                  iconColor: VColors.tertiary,
                  onTap: () => context.push('/twin-seal'),
                ),
                VSectionTile(
                  icon: Icons.monetization_on_outlined,
                  label: 'Coin history',
                  onTap: () => context.push('/coin-history'),
                ),
                VSectionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete Account',
                  iconColor: VColors.error,
                  titleColor: VColors.error,
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            VSectionList(
              title: 'Notifications',
              children: [
                VSectionSwitchTile(
                  icon: Icons.notifications_active,
                  label: 'Push Notifications',
                  value: _pushEnabled,
                  onChanged: _prefsLoaded ? _onPushToggleChanged : null,
                ),
                VSectionSwitchTile(
                  icon: Icons.favorite_border,
                  label: 'Likes',
                  value: _likesEnabled,
                  onChanged: _prefsLoaded
                      ? (v) {
                          setState(() => _likesEnabled = v);
                          _setNotificationPref(_kPrefLikesEnabled, v);
                        }
                      : null,
                ),
                VSectionSwitchTile(
                  icon: Icons.mode_comment_outlined,
                  label: 'Comments',
                  value: _commentsEnabled,
                  onChanged: _prefsLoaded
                      ? (v) {
                          setState(() => _commentsEnabled = v);
                          _setNotificationPref(_kPrefCommentsEnabled, v);
                        }
                      : null,
                ),
                VSectionSwitchTile(
                  icon: VIcons.globe,
                  label: 'World Invites',
                  value: _worldInvitesEnabled,
                  onChanged: _prefsLoaded
                      ? (v) {
                          setState(() => _worldInvitesEnabled = v);
                          _setNotificationPref(_kPrefWorldInvitesEnabled, v);
                        }
                      : null,
                ),
                VSectionSwitchTile(
                  icon: Icons.military_tech,
                  label: 'Tier Upgrades',
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
            const SizedBox(height: VSpacing.md),
            VSectionList(
              title: 'Progression',
              children: [
                VSectionSwitchTile(
                  icon: Icons.leaderboard_outlined,
                  label: 'Low-pressure mode',
                  value:
                      ref.watch(residentProvider).resident?.leaderboardOptOut ??
                      false,
                  onChanged: (v) {
                    ref.read(residentProvider.notifier).setLeaderboardOptOut(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            VSectionList(
              title: 'Worlds',
              children: [
                VSectionSwitchTile(
                  icon: Icons.dynamic_feed,
                  label: 'Open joined worlds on Feed',
                  value: _memberOpensOnFeed,
                  onChanged: _prefsLoaded
                      ? (v) async {
                          setState(() => _memberOpensOnFeed = v);
                          await WorldNavPrefs.setMemberOpensOnFeed(v);
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsSectionLabel(title: 'Appearance'),
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VRadius.md),
                    side: BorderSide(
                      color: isDark
                          ? VColors.outlineVariantDark
                          : VColors.outlineVariant,
                    ),
                  ),
                  child: _appearancePanel(
                    theme: theme,
                    isDark: isDark,
                    scheme: themeState.scheme,
                  ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: VSpacing.md),
                    VSectionList(
                      title: 'Tier Perks',
                      children: [
                        _PerkTile(
                          icon: Icons.trending_up,
                          title: 'XP Multiplier',
                          value: 'x${multiplier.toStringAsFixed(2)}',
                        ),
                        _PerkTile(
                          icon: Icons.monetization_on,
                          title: 'Daily Coin Bonus',
                          value: '+$coinBonus',
                        ),
                        _PerkTile(
                          icon: Icons.emoji_emotions,
                          title: 'Custom Reactions',
                          value: '$reactionSlots slots',
                        ),
                        _PerkTile(
                          icon: Icons.push_pin,
                          title: 'Post Pins',
                          value: pinLimit > 0
                              ? '$pinLimit available'
                              : 'Locked',
                        ),
                        _PerkTile(
                          icon: Icons.language,
                          title: 'World Creation',
                          value: '$worldLimit worlds',
                        ),
                        _PerkTile(
                          icon: Icons.local_bar,
                          title: 'Lounge Access',
                          value: hasLounge ? 'Unlocked' : 'Locked',
                        ),
                        _PerkTile(
                          icon: Icons.how_to_vote,
                          title: 'Governance Vote',
                          value: hasVote ? 'Unlocked' : 'Locked',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: VSpacing.md),
            VSectionList(
              title: 'Help & legal',
              children: [
                VSectionTile(
                  icon: Icons.info_outline,
                  label: 'Privacy, terms & licenses',
                  detail: 'Open the More tab',
                  onTap: () => context.go('/more'),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            VSectionList(
              title: 'Data',
              children: [
                VSectionTile(
                  icon: Icons.backup,
                  label: 'Create Backup',
                  onTap: () async {
                    await BackupService.createBackup();
                    if (context.mounted) {
                      VFeedback.showMessage(
                        context,
                        'Backup created successfully',
                      );
                    }
                  },
                ),
                VSectionTile(
                  icon: Icons.restore,
                  label: 'Restore Backup',
                  onTap: _showRestoreBackupDialog,
                ),
                VSectionTile(
                  icon: Icons.cleaning_services_outlined,
                  label: 'Clear Cache (${_formatBytes(_cacheSizeBytes)})',
                  onTap: _cacheSizeBytes > 0 ? _clearCache : null,
                  enabled: _cacheSizeBytes > 0,
                ),
                if (_failedOutboxCount > 0)
                  VSectionTile(
                    icon: Icons.sync_problem,
                    label: 'Discard failed sync ($_failedOutboxCount)',
                    onTap: _discardFailedOutbox,
                  ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: VSpacing.md),
              VSectionList(
                title: 'Developer',
                children: [
                  VSectionTile(
                    icon: Icons.cloud_outlined,
                    label: FirebaseBootstrap.isInitialized
                        ? 'Firebase: connected'
                        : 'Firebase: ${FirebaseBootstrap.lastError ?? "offline"}',
                    enabled: false,
                  ),
                  VSectionTile(
                    icon: Icons.science_outlined,
                    label: 'UI reference (Forui)',
                    detail: 'Debug wrapper smoke',
                    onTap: () => context.push('/debug/ui-spike'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: VSpacing.md),
            VSectionList(
              title: 'Danger Zone',
              children: [
                VSectionTile(
                  icon: Icons.delete_forever,
                  label: 'Reset All Data',
                  iconColor: VColors.error,
                  titleColor: VColors.error,
                  onTap: _showResetDataDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Matches [VSectionList] uppercase section labels.
class _SettingsSectionLabel extends StatelessWidget {
  final String title;

  const _SettingsSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(left: VSpacing.xs, bottom: VSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: theme.typography.sm.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colors.mutedForeground,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PerkTile extends FTile {
  _PerkTile({
    required IconData icon,
    required String title,
    required String value,
  }) : super(
         prefix: Builder(
           builder: (context) =>
               Icon(icon, color: context.theme.colors.mutedForeground),
         ),
         title: Builder(
           builder: (context) => Text(
             title,
             style: TextStyle(color: context.theme.colors.foreground),
           ),
         ),
         details: Builder(
           builder: (context) {
             final valueColor = value.contains('Locked')
                 ? context.theme.colors.mutedForeground
                 : VColors.tertiary;
             return Text(
               value,
               style: TextStyle(color: valueColor, fontWeight: FontWeight.w600),
             );
           },
         ),
       );
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
    return Padding(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: VColors.error),
              const SizedBox(width: VSpacing.sm),
              Text(
                'Reset all data?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: VColors.error,
                  fontWeight: VFontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          if (_step == 0)
            const Text(
              'This will permanently delete all local data including posts, notifications, '
              'achievements, and preferences. Your account will not be deleted, but all cached data will be gone.\n\n'
              'This action cannot be undone.',
            )
          else
            Column(
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
          const SizedBox(height: VSpacing.lg),
          vDialogActionsRow(
            _step == 0
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
          ),
        ],
      ),
    );
  }
}
