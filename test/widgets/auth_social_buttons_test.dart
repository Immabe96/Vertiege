import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/widgets/auth/auth_social_buttons.dart';

void main() {
  test('showAppleSignIn is true on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      expect(AuthSocialButtons.showAppleSignIn, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('showAppleSignIn is false on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      expect(AuthSocialButtons.showAppleSignIn, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
