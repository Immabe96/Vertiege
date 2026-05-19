# Product Gap Audit

**Date:** 2026-05-19
**Scope:** Gaps between app vision (PLAN.md) and current implementation as of Phase 2.

---

## Critical Gaps (block production use)

### 1. No push notification delivery
- FCM token registration exists but no Edge Function fanout or device token sync
- Notifications are in-app only; nothing reaches the device when app is closed
- **PLAN.md Phase 9** covers this

### 2. Auth deep-link handling is a placeholder
- `AuthCallbackScreen` shows a loading indicator but doesn't handle magic links, OAuth redirects, or password reset callbacks
- **PLAN.md Phase 4** covers deep link routes

### 3. No realtime subscriptions active
- Supabase Realtime is configured but channels are not subscribed with proper presence or broadcast
- World channels load via polling/refresh, not realtime push
- **PLAN.md Phase 6** covers realtime audit

### 4. Offline durability is partial
- `MutationOutboxService` exists but missed mutations may not reconcile correctly after restart
- Some providers write to SharedPreferences directly, bypassing repository layer
- **PLAN.md Phase 7** covers repository/outbox standardization

---

## High Gaps (visible to users)

### 5. Glass/legacy UI remains in ~60% of screens
- `GlassPanel`, `GlassSheet`, `SovereignCard`, `GlassLoadingList` still used across 20+ files
- Screens like HallOfAscension, AscensionPath, Subscription, WorldSettings still use glass loading
- **PLAN.md Phase 3** covers Forui migration completion

### 6. Navigation doesn't match target IA
- Bottom tabs are Nexus/Explore/Chat/Identity (4 tabs) — PLAN.md Phase 4 specifies Nexus/Discover/Chat/Identity/More (5 tabs)
- No deep link handling for notification targets, post detail, or profile routes
- **PLAN.md Phase 4** covers this

### 7. World content is generic for non-starter worlds
- 14 default worlds exist in config but only `neon-district` and `crystal-shore` have full foundation content
- Remaining worlds have auto-generated or minimal lore
- **PLAN.md Phase 5** covers world content completion

### 8. Image pipeline is inconsistent
- Some screens use `NetworkImage` directly instead of `CosmeticAvatar` or `VImage`
- No standardized fallback chain (Supabase → bundled asset → category placeholder → empty icon)
- Storage bucket policies not verified for all media types
- **PLAN.md Phase 5** covers media pipeline

### 9. Font loading can cause flash
- Google Fonts (`Space Grotesk`, `Inter`) loaded dynamically may cause text flash on first render
- **PLAN.md Phase 3** covers replacing Google Fonts with system fonts

---

## Medium Gaps (feature completeness)

### 10. Features exist as screens but aren't integrated
- Marketplace, Treasury, Polls, Challenges have dedicated screen files but aren't wired with real data or transaction logic
- These screens were moved to More tab in Phase 1 with "coming soon" messaging
- **PLAN.md Phase 10** covers feature completion

### 11. Search is global but limited
- Searches worlds and residents but not posts, channels, or tags
- No recent searches persistence across sessions
- **PLAN.md Phase 10** covers search expansion

### 12. Composer is FAB-only on Nexus
- No inline composer on feed cards or world detail
- FAB opens modal; no dedicated compose screen (CreatePostScreen removed in stabilization)
- **PLAN.md Phase 10** covers composer unification

---

## Low Gaps (infrastructure and polish)

### 13. Crash reporting is console-only
- `CrashReporter` abstraction exists with `ConsoleCrashReporter` default
- Firebase Crashlytics integration not complete
- **PLAN.md Phase 9** covers this

### 14. No analytics tracking
- No events fired for onboarding, world views, post creation, or errors
- **PLAN.md Phase 9** covers this

### 15. Remote Config not wired
- No feature flags — Marketplace, Treasury, Quests, Events can't be toggled without a build
- **PLAN.md Phase 9** covers this

### 16. Migrations have unapplied files
- Two unapplied migrations (`20260519_001`, `20260519_add_rpc`) are safe but not applied to remote
- **PLAN.md Phase 6** covers migration hygiene

### 17. No accessibility semantics
- Icon-only buttons lack semantic labels
- No text scaling testing beyond default
- **PLAN.md Phase 12** covers accessibility

### 18. Test coverage is narrow
- 101 tests exist but cover mainly config, models, utils, and services
- No widget/golden tests for screens, no integration tests, no RLS tests
- **PLAN.md Phase 13** covers test expansion

---

## Not Gaps (by design)

- **No service-role key in Flutter app**: Anon key only — correct
- **Immabe superuser bypass**: Hardcoded email check is intentional admin access per PLAN.md
- **IAP gated in dev mode**: `StoreService.isEnabled => false` in debug — intentional safety
- **Starter worlds auto-join**: New residents auto-join `neon-district` and `crystal-shore` — intentional
- **Splash delay**: Currently has fixed delay — PLAN.md Phase 8 will address

---

## Summary

| Severity | Count | Phases that address |
|----------|-------|---------------------|
| Critical | 4 | 4, 6, 7, 9 |
| High | 5 | 3, 4, 5 |
| Medium | 3 | 10 |
| Low | 6 | 9, 6, 12, 13 |
