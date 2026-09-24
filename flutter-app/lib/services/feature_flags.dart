import 'package:flutter/foundation.dart';

import 'remote_config_service.dart';

/// Central feature flag lookup.
///
/// All flags default to false when Firebase is unavailable.
/// Firebase Remote Config can override any flag remotely without a new build.
class FeatureFlags {
  FeatureFlags._();

  // ── Feature gates ──

  static bool get marketplace =>
      RemoteConfigService.getBool('marketplace_enabled');

  static bool get treasury =>
      RemoteConfigService.getBool('treasury_enabled');

  /// World jobs / role board. Off by default in closed beta.
  static bool get worldJobs =>
      RemoteConfigService.getBool('world_jobs_enabled');

  /// Academy / sanctuary learning modules. Off by default in closed beta.
  static bool get worldAcademy =>
      RemoteConfigService.getBool('world_academy_enabled');

  /// Live Campfire voice. Off until reliability UAT — broken voice hurts trust.
  static bool get campfireEnabled =>
      RemoteConfigService.getBool('campfire_enabled');

  static bool get quests =>
      RemoteConfigService.getBool('quests_enabled', fallback: true);

  static bool get events =>
      RemoteConfigService.getBool('events_enabled', fallback: true);

  static bool get polls =>
      RemoteConfigService.getBool('polls_enabled', fallback: true);

  static bool get challenges =>
      RemoteConfigService.getBool('challenges_enabled', fallback: true);

  /// Immersive Campfire UI (minimal chrome). Default off until device UAT.
  static bool get campfireImmersive => RemoteConfigService.getBool(
        'campfire_immersive',
        fallback: true,
      );

  /// When true, subscriptions verify via the verify-subscription-purchase edge function.
  /// Defaults on so stub client RPC cannot mint entitlements; override via Remote Config.
  static bool get receiptEdgeVerify => RemoteConfigService.getBool(
        'receipt_edge_verify',
        fallback: true,
      );

  /// When true, route user text through the moderate-content edge function
  /// (server-side). Defaults on; disable via Remote Config for local offline UX.
  static bool get contentModerationRemote => RemoteConfigService.getBool(
        'content_moderation_remote',
        fallback: true,
      );

  // ── UI knobs ──

  static bool get foruiStrictMode =>
      RemoteConfigService.getBool('forui_strict_mode', fallback: true);

  static bool get postOutboxEnabled =>
      RemoteConfigService.getBool('post_outbox_enabled', fallback: true);

  static bool get verboseErrors =>
      RemoteConfigService.getBool('verbose_errors');

  // ── Pagination ──

  static int get feedPageSize =>
      RemoteConfigService.getInt('feed_page_size', fallback: 20);

  static int get commentsPageSize =>
      RemoteConfigService.getInt('comments_page_size', fallback: 20);

  static int get chatPageSize =>
      RemoteConfigService.getInt('chat_page_size', fallback: 30);

  static int get notificationsPageSize =>
      RemoteConfigService.getInt('notifications_page_size', fallback: 20);

  // ── App ──

  /// Global minimum, unless `minimum_build_ios` / `minimum_build_android` is set.
  static int get minimumBuild {
    if (!kIsWeb) {
      final platformKey = defaultTargetPlatform == TargetPlatform.iOS
          ? 'minimum_build_ios'
          : 'minimum_build_android';
      final platformMin = RemoteConfigService.getInt(platformKey);
      if (platformMin > 0) return platformMin;
    }
    return RemoteConfigService.getInt('minimum_build', fallback: 1);
  }

  static String get maintenanceBanner =>
      RemoteConfigService.getString('maintenance_banner');

  /// When > 0 and message non-empty, show one-shot What's New after splash.
  static int get whatsNewBuild =>
      RemoteConfigService.getInt('whats_new_build');

  static String get whatsNewMessage =>
      RemoteConfigService.getString('whats_new_message');

  /// Beta feedback form URL (Settings). Prefer a real form; mailto is fallback.
  static String get betaFeedbackUrl => RemoteConfigService.getString(
        'beta_feedback_url',
        fallback: 'mailto:privacy@vertiege.app?subject=Vertiege%20beta%20feedback',
      );

  /// Hosted Privacy Policy URL for store listings / "View online".
  static String get privacyPolicyUrl => RemoteConfigService.getString(
        'privacy_policy_url',
        fallback: 'https://veritage.web.app/privacy.html',
      );

  /// Hosted Terms of Service URL.
  static String get termsOfServiceUrl => RemoteConfigService.getString(
        'terms_of_service_url',
        fallback: 'https://veritage.web.app/terms.html',
      );

  /// Streak push copy: `calm` (default) or `direct` (legacy urgency).
  static String get reEngagementPushVariant => RemoteConfigService.getString(
        're_engagement_push_variant',
        fallback: 'calm',
      );

  /// Nexus bento order: `default`, `quest_first`, or `social`.
  static String get nexusBentoSegment => RemoteConfigService.getString(
        'nexus_bento_segment',
        fallback: 'quest_first',
      );
}
