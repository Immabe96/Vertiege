# Vertiege Long-Horizon Product Completion Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` task-by-task. The implementing agent may not have image-reading capability. If a task requires visual inspection of screenshots, generated assets, UI captures, image quality, placeholder quality, contrast from screenshots, or banner/icon evaluation, write a clear note in the milestone report for Codex to perform the visual review.

**Goal:** Turn Vertiege from a working stabilization APK into a polished, reliable, production-grade social world app with consistent Forui UI, persistent Supabase-backed data, Firebase infrastructure, fast loading, complete world content, and a clear feature roadmap.

**Architecture:** Supabase remains source of truth for app data, auth, storage, realtime, RLS, and domain state. Firebase is infrastructure-only for Crashlytics, Analytics, Remote Config, and FCM. Flutter uses Forui-led app primitives, repository-backed state, cache-first loading, durable outbox mutations, and explicit error/loading/sync states.

**Tech Stack:** Flutter/Dart, Riverpod, go_router, Forui, Supabase Postgres/RLS/Realtime/Storage/Edge Functions, Firebase Core/Messaging/Crashlytics/Analytics/Remote Config, Android JDK 21, GitHub Actions.

---

## Non-Negotiable Agent Reporting Rule

Maintain an implementation report after each milestone with completed tasks, files changed, test results, unresolved risks, screenshots or APK paths if produced, and Codex visual-review requests for anything requiring image/UI inspection.

Use this exact marker:

```markdown
## Codex Visual Review Needed
- Screen/asset:
- Why visual inspection is needed:
- How to reproduce/open it:
- Related files:
```

Do not claim visual quality is fixed purely from code inspection when the issue depends on rendered screenshots or images.

---

## Phase 0: Baseline And Merge

**Goal:** Accept the stabilization branch as the new baseline, then stop treating old plans as active truth.

**Required Actions**
- Merge `feat/stabilization-plan` into `main` after confirming Nexus feed recursion is gone, world channels show, FAB behavior is accepted, APK builds and installs, and `flutter test` passes.
- Delete or archive stale feature branches only after confirming their commits are merged or obsolete.
- Keep `REPORT.md` as historical reference.
- Make this `PLAN.md` the active working plan.
- Update `README.md`, `docs/DESIGN.md`, and `docs/PROGRESS.md` because they still describe older dark/glass direction.

**Acceptance**
- `main` contains stabilization work.
- Root `PLAN.md` contains this roadmap or a task-sliced version of it.
- No active docs describe glass-first/dark-first UI as current product direction.

---

## Phase 1: Immediate Installed-App Polish

**Goal:** Fix the issues still visible in the installed APK before starting deeper architecture work.

**Key Fixes**
- Redesign Chat > Worlds so the world rail shows both icon/image and readable name.
- Replace overcrowded world detail tabs with `Feed`, `Channels`, `Residents`, `More`.
- Move secondary world tools into `More`.
- Verify create-world flow on device and capture exact error if it fails.
- Separate `Foundation` lore from `Guide` action shortcuts.
- Replace missing/noisy empty states with minimal Forui-style states.

**Visual Review Note**
- Ask Codex to review screenshots for world rail readability, tab overflow, placeholder image quality, banner image distortion, and light/dark contrast.

**Acceptance**
- User can identify worlds by name in Chat.
- No world page has clipped tab labels.
- Create world succeeds or reports a precise actionable error.
- Empty states look intentional after Codex visual review.

---

## Phase 2: Product Source Of Truth Cleanup

**Goal:** Make the app vision, docs, and implementation agree.

**Update**
- `README.md`
- `docs/DESIGN.md`
- `docs/PROGRESS.md`
- `PLAN.md`
- `docs/audits/product-gap-audit.md`

**Product Definition**
- Vertiege is a social world/community app, not a financial app.
- Worlds are identity-rich communities with channels, residents, lore, posts, polls, quests, events, achievements, and economy features where relevant.
- Default worlds must feel independent.
- Immabe remains admin/testing superuser with all-world access.

**Acceptance**
- New agent can understand the current product from docs.
- Historical glass/dark-first design language is removed or explicitly marked historical.

---

## Phase 3: Forui Design System Completion

**Goal:** Finish the UI migration so every screen feels like one app.

**Design Rules**
- Light theme: white/minimal surfaces, dark readable text, compact spacing.
- Dark theme: AMOLED black, high-contrast text, restrained borders.
- Accent colors only for selected state, semantic status, world identity, rarity, or destructive/success/warning states.
- Avoid heavy gradients, blur panels, and white text over uncontrolled images.
- Use subtle scrims only when text overlays images.

**Implementation**
- Standardize app primitives: `VScaffold`, `VTopBar`, `VBottomNav`, `VCard`, `VListTile`, `VButton`, `VEmptyState`, `VLoadingState`, `VErrorState`, `VImage`, `VWorldBadge`, and `VSyncStatusBadge`.
- Replace legacy patterns: `GlassPanel`, `GlassSheet`, `SovereignCard`, screen-level `GoogleFonts`, arbitrary `Colors.*`, unreviewed `LinearGradient`, and unreviewed `BackdropFilter`.
- Keep documented exceptions only for image viewers, export/share visuals, readable image scrims, and generated media previews.

**Acceptance**
- Legacy UI searches only return documented exceptions.
- No low-contrast text, clipped labels, oversized card headings, or mismatched plain widgets after Codex visual review.

---

## Phase 4: Navigation And Information Architecture

**Goal:** Make the app easier to understand and faster to move through.

**Navigation Model**
- Bottom tabs: `Nexus`, `Discover`, `Chat`, `Identity`, `More`.
- Chat owns DMs, world channels, unread counts, and active residents.
- World detail owns overview, feed, channels shortcut, residents, and secondary modules through `More`.
- Composer appears only from valid feed/channel contexts.

**Deep Links**
- Add routes for post detail, world detail, channel, profile, notification target, and auth callback.
- Replace placeholder auth callback handling with real session handling.

**Acceptance**
- New user can find worlds, join/enter channels, create a post, and return home without confusion.
- Route restoration works after restart or notification tap.

---

## Phase 5: World Content, Identity, And Media System

**Goal:** Make every world feel distinct and remove placeholder-looking content.

**World Requirements**
- Every world has name, slug, description, lore, banner, icon, accent, category, tags, default channels, and starter content.
- Starter worlds remain `neon-district` and `crystal-shore`.
- Immabe can access every world regardless of tier or visibility.

**Channels**
- Every default world gets `info`, `rules`, `roles`, and `general`.
- Channel text must be world-specific and include safety disclaimers for medical, financial, legal, and technical-risk worlds.

**Media Pipeline**
- Standardize all images through `VImage`.
- Fallback order: Supabase image, bundled generated asset, category placeholder, minimal icon empty state.
- Compress large assets.
- Add or verify storage buckets for avatars, world banners, icons, post media, marketplace media, and verification evidence.

**Acceptance**
- No world uses generic placeholder visuals unless intentionally unconfigured.
- Chat world navigation shows recognizable icon and name.
- Missing images degrade gracefully.

---

## Phase 6: Supabase Reliability And Migration Hygiene

**Goal:** Ensure the backend can be trusted across fresh projects and the existing remote project.

**Work**
- Do not rewrite applied migrations.
- Add corrective migrations for remote issues.
- Quarantine faulty unapplied migrations.
- Audit RLS for worlds, memberships, channels, messages, posts, comments, reactions, bookmarks, polls, quests, events, notifications, marketplace, treasury, achievements, device tokens, and storage.
- Eliminate recursive policy patterns.
- Use security-definer helpers with fixed `search_path`.
- Add or verify RPCs for join world, create world, post actions, comments, reactions, bookmarks, poll votes, channel reads/messages, marketplace, treasury, and quest progress.
- Add indexes for feed, comments, reactions, bookmarks, memberships, channel messages, notifications, search, and marketplace filters.

**Acceptance**
- Fresh Supabase project can run all migrations once.
- Existing remote project can apply new migrations without reset.
- Allowed reads work; denied private rows remain denied.
- Immabe superuser can read/admin all worlds.

---

## Phase 7: Persistence, Repositories, And Outbox

**Goal:** Stop features from pretending to work locally when they are not durable.

**Repository Standard**
- Add or complete repositories for profile, worlds, posts, chat, notifications, achievements, quests, events, polls, marketplace, treasury, alliances, and cosmetics.
- Providers must call repositories, not write authoritative state directly to `SharedPreferences`.

**State Types**
- Standardize `RepositoryResult<T>`, `LoadState<T>`, `AppFailure`, `SyncStatus`, `MutationOutboxItem`, `RetryPolicy`, and `ConflictResolution`.

**Outbox**
- Unify deprecated offline queue and mutation outbox.
- Durable actions: post, comment, reaction, bookmark, poll vote, join world, create world, channel message, marketplace action, treasury action, quest progress.
- Failed mutations show visible retry/failure state.

**Acceptance**
- Refresh/restart does not lose user actions.
- Missing Supabase/auth does not return fake success.
- Offline actions reconcile when connectivity returns.

---

## Phase 8: Performance And Loading Speed

**Goal:** Make the app feel fast without hiding backend failures.

**Startup**
- Remove fixed splash delays.
- Show shell quickly.
- Load resident/world/feed first.
- Lazy-load achievements, events, quests, store, notifications.
- Register push tokens after resident becomes available.

**Loading**
- Add pagination for feed, comments, channel messages, notifications, marketplace, and residents.
- Use cache-first display, server refresh, and realtime updates.
- Batch queries and avoid duplicate provider loads.

**Images**
- Use thumbnails in lists.
- Precache visible world icons/banners.
- Compress oversized bundled images.
- Avoid full banners in small rail/list cells.

**Instrumentation**
- Trace startup, first feed load, world list load, channel load, create post, create world, and notification open.

**Acceptance**
- App shell appears quickly.
- Nexus and Chat show skeletons instead of blank stalls.
- Large images do not cause jank.

---

## Phase 9: Firebase Infrastructure Completion

**Goal:** Make Firebase useful without moving app data out of Supabase.

**Crashlytics**
- Replace console-only reporter with Firebase Crashlytics.
- Record Flutter/platform/repository/Supabase/outbox failures.
- Attach only non-PII context.

**Analytics**
- Track onboarding, world viewed/joined/created, channel opened, post/comment/reaction/bookmark, notification opened, marketplace action, quest action, surfaced errors, and outbox failures.
- Do not log message body, post body, email, or sensitive content.

**Remote Config**
- Add feature flags and defaults for marketplace, treasury, quests, events, page sizes, startup load limit, verbose errors, minimum build, and maintenance banner.

**FCM**
- Handle token registration, token refresh, foreground notifications, background/opened notifications, and notification deep-link routing.
- Use Supabase Edge Functions for fanout.

**Acceptance**
- Crash test appears in Crashlytics.
- Notification tap opens the right route.
- Remote Config can disable a feature without app release.

---

## Phase 10: Feature Completion Roadmap

**Goal:** Close the gap between app vision and visible product.

**Major Areas**
- Nexus/feed: unified composer, media, post detail, comments, reactions, bookmarks, edit/delete/pin, filters, report/hide/mute.
- Worlds: creation, settings, roles, permissions, invites, resident list, moderation, analytics.
- Chat: persistent messages, unread badges, last-read marker, edit/delete, attachments, mentions.
- Quests/events/challenges: definitions, progress, RSVP, reminders, rewards.
- Marketplace/treasury: listings, media, transactions, ledger, admin audit.
- Cosmetics/achievements: inventory, unlock/equip, progress, rarity styles.
- Governance/polls: creation, voting, results, eligibility, realtime updates.
- Search/discovery: worlds, posts, residents, channels, tags, recommendations.
- Identity: edit profile, avatar upload, verification, account export/delete, privacy.
- Admin/moderation: reports queue, takedown, suspension, audit log, real moderation pipeline.

**Acceptance**
- No visible "coming soon" unless feature-flagged off.
- Every visible button works, explains unavailable state, or is hidden.
- Feature data persists through restart.

---

## Phase 11: Security, Privacy, And Abuse Prevention

**Goal:** Avoid shipping a social app with weak access control or unsafe content handling.

**Work**
- RLS tests for every table.
- Storage bucket policy tests.
- Superuser access scoped and auditable.
- No service-role key in Flutter app.
- Rate limits for post, world, message, reaction, report, invite flows.
- Edge Functions verify JWT and permissions.
- Account deletion/export.
- Block/mute/report.
- No PII in analytics/crash logs.
- World-specific safety rules for medical, financial, legal, and exploit-risk content.

**Acceptance**
- RLS denial cases are tested.
- Abuse-prone flows have limits and report paths.
- Sensitive text is not sent to analytics.

---

## Phase 12: Accessibility, Mobile Quality, And Internationalization

**Goal:** Make the app usable on real phones, not just ideal screenshots.

**Work**
- Test text scale at 1.0, 1.3, and 1.6.
- Minimum tap target 44x44 where practical.
- Semantic labels for icon-only buttons.
- Contrast checks in light and AMOLED dark.
- Reduced motion support.
- Keyboard avoidance for composer, comments, chat, auth, and create world.
- Safe areas on every screen.
- Pull-to-refresh where expected.
- Extract user-facing strings.

**Acceptance**
- No major screen breaks with larger text.
- Keyboard does not cover submit buttons.
- Icon-only controls have semantics/tooltips.

---

## Phase 13: Testing, CI, And Release Discipline

**Goal:** Make future agents prove changes before producing APKs.

**Test Layers**
- Unit tests for models, repositories, outbox, sync status, remote config defaults.
- Provider tests for cache-first load, refresh, error, retry.
- Supabase tests for RLS and RPC behavior.
- Widget/golden tests for Nexus, Chat > Worlds, World Detail, Channel, Identity, Composer, Empty/Error states.
- Integration tests for onboarding, join world, create post, send message, create world, restart persistence.
- Performance tests for startup, feed load, channel load, image-heavy screens.

**CI**
- Analyze.
- Test.
- Migration validation.
- Android release APK build with JDK 21.
- Upload APK artifact.
- Optional Firebase App Distribution after secrets are configured.

**Required Commands**

```powershell
$env:JAVA_HOME="C:\Users\Immabe\AppData\Local\jdk-21.0.9+10"
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release
```

**Acceptance**
- CI can build APK without local machine intervention.
- Release APK is attached as artifact.
- No branch merges without green checks unless explicitly overridden.

---

## Public Interfaces And Types To Add Or Standardize

**Flutter**
- `RepositoryResult<T>`
- `LoadState<T>`
- `AppFailure`
- `SyncStatus`
- `MutationOutboxItem`
- `WorldNavigationSummary`
- `WorldMedia`
- `MediaAssetRef`
- `VImageSource`
- `NotificationPayload`
- `AnalyticsEvent`
- `RemoteConfigKeys`
- `PerformanceTraceName`

**Supabase**
- Stable RPCs for core mutations.
- `device_tokens` token refresh support.
- Storage buckets and policies for media.
- World icon/banner fields.
- Channel foundation/starter content fields.
- Audit log table for admin/moderation actions.

**UI**
- One canonical composer.
- One canonical empty state.
- One canonical image widget.
- One canonical world list/rail item.
- One canonical error surface.

---

## Milestone Order

1. Merge stabilization baseline.
2. Fix installed-app polish: world names, tab overflow, create-world verification.
3. Rewrite source-of-truth docs.
4. Finish Forui UI migration.
5. Complete media/world identity system.
6. Harden Supabase/RLS/RPC/migrations.
7. Standardize repositories and durable outbox.
8. Improve startup/loading/realtime/image performance.
9. Complete Firebase infrastructure.
10. Fill feature gaps.
11. Harden security/privacy/accessibility.
12. Build CI-backed release process.

---

## Assumptions

- The stabilization APK is good enough to merge, but not production quality.
- `feat/stabilization-plan` is the accepted baseline branch.
- Supabase remains the source of truth for app data and auth.
- Firebase remains infrastructure-only.
- Immabe / `ltyl.naughty@gmail.com` remains superuser with all-world access.
- Light theme is the default.
- Dark theme should be AMOLED black.
- DeepSeek v4 Pro can implement code and run tests, but Codex must handle visual/image-based review.
- Work should proceed in milestones, not one giant change.
