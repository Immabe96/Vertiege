import 'onboarding_funnel_prefs.dart';
import 'profile_service.dart';
import 'supabase.dart';

/// Merges local First Steps flags with [profiles.onboarding_funnel] on Supabase.
class OnboardingFunnelSync {
  OnboardingFunnelSync._();

  static Future<void> pullFromServer(String userId) async {
    if (!isSupabaseConfigured()) return;
    final remote = await ProfileService.getOnboardingFunnel(userId);
    if (remote == null || remote.isEmpty) return;
    await OnboardingFunnelPrefs.applyRemote(remote);
  }

  static Future<void> pushToServer(String userId) async {
    if (!isSupabaseConfigured()) return;
    final snapshot = await OnboardingFunnelPrefs.readSnapshot();
    await ProfileService.patchOnboardingFunnel(userId, snapshot);
  }

  static Future<void> markOpenedWorld(String userId) async {
    await OnboardingFunnelPrefs.markOpenedWorld();
    await pushToServer(userId);
  }

  static Future<void> markOpenedNexus(String userId) async {
    await OnboardingFunnelPrefs.markOpenedNexus();
    await pushToServer(userId);
  }

  static Future<void> setDismissed(String userId, bool value) async {
    await OnboardingFunnelPrefs.setDismissed(value);
    await pushToServer(userId);
  }
}
