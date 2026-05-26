import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/v_tokens.dart';
import '../ui/buttons/v_button.dart';
import 'firebase_bootstrap.dart';
import 'storage_service.dart';

/// OS-level permissions (camera, gallery, push). Distinct from [WorldPermissions].
class DevicePermissionService {
  DevicePermissionService._();

  static const _kPushPermanentlyDenied = 'push_notification_permanently_denied';

  /// Android [POST_NOTIFICATIONS] plus FCM authorization. Returns whether alerts are allowed.
  static Future<bool> requestNotifications() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      var status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
      }
      if (status.isPermanentlyDenied) {
        await _setPushPermanentlyDenied(true);
        return false;
      }
      if (!status.isGranted) {
        await _setPushPermanentlyDenied(false);
        return false;
      }
      await _setPushPermanentlyDenied(false);
    }

    if (!FirebaseBootstrap.isInitialized) return false;

    final messaging = FirebaseMessaging.instance;
    var settings = await messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted &&
        settings.authorizationStatus == AuthorizationStatus.denied &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS) {
      await _setPushPermanentlyDenied(true);
    } else if (granted) {
      await _setPushPermanentlyDenied(false);
    }

    await StorageService.setString(
      'push_permission_status',
      settings.authorizationStatus.name,
    );
    return granted;
  }

  static Future<bool> isPushPermanentlyDenied() async {
    final value = await StorageService.getString(_kPushPermanentlyDenied);
    return value == 'true';
  }

  static Future<void> _setPushPermanentlyDenied(bool denied) async {
    await StorageService.setString(
      _kPushPermanentlyDenied,
      denied ? 'true' : 'false',
    );
  }

  static Future<void> showPermissionDeniedSheet(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showFDialog<void>(
      context: context,
      builder: (ctx, style, animation) => FDialog.raw(
        builder: (context, dialogStyle) => Padding(
          padding: const EdgeInsets.all(VSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              Text(message),
              const SizedBox(height: VSpacing.lg),
              VButton(
                label: 'Open Settings',
                isFullWidth: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettings();
                },
              ),
              const SizedBox(height: VSpacing.sm),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool> requestCameraAccess(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (!context.mounted) return false;
    if (status.isPermanentlyDenied || status.isDenied) {
      await showPermissionDeniedSheet(
        context,
        title: 'Camera access needed',
        message:
            'Vertiege needs camera access to take photos. Enable it in system settings.',
      );
    }
    return false;
  }

  static Future<bool> requestGalleryAccess(BuildContext context) async {
    final permission = _galleryPermission();
    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
    }
    if (status.isGranted) return true;
    if (!context.mounted) return false;
    if (status.isPermanentlyDenied || status.isDenied) {
      await showPermissionDeniedSheet(
        context,
        title: 'Photos access needed',
        message:
            'Vertiege needs access to your photo library. Enable it in system settings.',
      );
    }
    return false;
  }

  static Permission _galleryPermission() {
    if (kIsWeb) return Permission.photos;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Permission.photos;
    }
    return Permission.photos;
  }
}
