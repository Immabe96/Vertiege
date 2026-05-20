/// Standard Firebase Analytics event names.
///
/// Usage: `AnalyticsService.logEvent(AnalyticsEvents.worldViewed, parameters: {'world_id': id});`
///
/// PII RULE: Never log message body, post body, email, resident name, or any
/// user-generated text content. Only log IDs and structural properties.
class AnalyticsEvents {
  AnalyticsEvents._();

  // Onboarding
  static const onboardingStarted = 'onboarding_started';
  static const onboardingCompleted = 'onboarding_completed';
  static const gateCompleted = 'gate_completed';

  // Worlds
  static const worldViewed = 'world_viewed';
  static const worldJoined = 'world_joined';
  static const worldCreated = 'world_created';
  static const worldLeft = 'world_left';

  // Channels
  static const channelOpened = 'channel_opened';

  // Posts
  static const postCreated = 'post_created';
  static const postViewed = 'post_viewed';
  static const postDeleted = 'post_deleted';

  // Comments
  static const commentCreated = 'comment_created';

  // Reactions
  static const reactionAdded = 'reaction_added';

  // Bookmarks
  static const bookmarkToggled = 'bookmark_toggled';

  // Notifications
  static const notificationOpened = 'notification_opened';

  // Marketplace
  static const marketplaceViewed = 'marketplace_viewed';
  static const marketplaceAction = 'marketplace_action';

  // Quests
  static const questAction = 'quest_action';
  static const questCompleted = 'quest_completed';

  // Errors
  static const errorSurfaced = 'error_surfaced';
  static const outboxFailure = 'outbox_failure';

  // App
  static const appForeground = 'app_foreground';
  static const appBackground = 'app_background';
  static const signIn = 'sign_in';
  static const signOut = 'sign_out';
  static const searchPerformed = 'search_performed';
}
