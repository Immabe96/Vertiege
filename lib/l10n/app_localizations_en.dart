// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vertiege';

  @override
  String get tabNexus => 'Nexus';

  @override
  String get tabWorlds => 'Worlds';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabYou => 'You';

  @override
  String get composePost => 'Compose post';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonBack => 'Back';

  @override
  String get commonGoBack => 'Go back';

  @override
  String get commonOpenProgress => 'Open Progress';

  @override
  String get commonClose => 'Close';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get postFailedTapRetry => 'Failed to post - tap to retry';

  @override
  String get messageFailedTapRetry => 'Failed to send · tap to retry';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorOffline =>
      'You\'re offline. Changes will sync when you\'re back.';

  @override
  String get cloudSyncUnavailable =>
      'Cloud sync is unavailable. Check .env and network, then restart.';

  @override
  String get buildOutdated =>
      'This build is outdated. Please update Vertiege from the store.';

  @override
  String get emptyJoinWorld => 'Join your first world';

  @override
  String get emptyFirstPost => 'Post your first update';

  @override
  String get emptyFirstMessage => 'Send your first message';

  @override
  String get contentInappropriate => 'Content contains inappropriate language';

  @override
  String get contentGuidelines => 'Content may violate community guidelines';

  @override
  String get rolesPausedTitle => 'Roles paused';

  @override
  String get marketplacePausedTitle => 'Marketplace paused';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get goToNexus => 'Go to Nexus';
}
