# Vertiege OpenCode Full App Audit + Fix Plan

## Operating Rules

OpenCode should act as the implementation worker. Codex remains the reviewer and merger.

- Work from `main`; do not base work on stale branches.
- Make small, reviewable PRs or commits grouped by domain.
- Do not use prior external-agent branches, prompts, helper scripts, or generated PRs.
- Do not create scratch files, root probe files, broad regex rewrites, or mechanical app-wide edits.
- Preserve routes and user-facing features unless the task explicitly says to remove one.
- Supabase remains the source of truth for app data and auth.
- Firebase, if present, is infrastructure only: FCM, Crashlytics, Analytics, Remote Config.
- Android release builds require JDK 21. GitHub Actions should use Temurin 21.
- For Dart changes, run:
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `flutter test`
- For major phases and final verification, also run:
  - `flutter build apk --release`

## Current Repo Facts

- Flutter app on branch `main`.
- Forui is present, with app wrappers under `lib/ui/**` and theme files under `lib/theme/**`.
- Legacy UI remains in many places: `GlassPanel`, `GlassSheet`, `SovereignCard`, `GoogleFonts`, `LinearGradient`, and `BackdropFilter`.
- Supabase migrations have multiple `20260516_*` prefixes, which makes migration ordering harder to reason about.
- Models for `RepositoryResult`, `SyncStatus`, and mutation outbox already exist.
- `World.isDefault` and `Channel.isDefault` exist.
- `lib/utils/world_foundations.dart` exists and is used by `world_channel_screen.dart` as channel foundation fallback.
- Several services still return empty collections or `false` when Supabase is not configured or when mutations fail, which can hide broken wiring.

## Initial Static Audit Findings

### P0 / Core Use

- Starter world entry still needs verification. The user previously reported that entering the first starter world redirects back to Nexus.
- Nexus/world feeds previously produced Supabase `42501` permission errors. Policies and query shapes need verification against real app behavior.
- Default world/channel seed data must be complete enough for new users to land in working worlds with readable starter channels.

### P1 / Data Trust

- Local-only or cache-heavy features must be audited. `SharedPreferences` appears in theme/settings/search/onboarding/channel list/offline queue/storage, and several services return `[]` or `false` instead of surfacing authoritative persistence failures.
- Supabase fallback methods in services such as `world_service`, `post_service`, `poll_service`, `marketplace_service`, `treasury_service`, `challenge_service`, `archive_service`, and others can make broken backend features look like empty UI states.
- Outbox and offline queue both exist. Verify whether they are unified, duplicated, or competing.
- Durable persistence must cover posts, comments, reactions, bookmarks, world joins, polls, treasury, marketplace, notifications, chat, quests, alliances, events, and channel reads.

### P2 / UI Quality

Static search still shows legacy or mismatched styling in many app areas:

- `GlassPanel` / `GlassSheet` / `SovereignCard` usages remain in Nexus, world detail/settings/members, create post, onboarding gate, chat input, loading states, league, subscription, achievements, verification review, and world widgets.
- `GoogleFonts` overrides remain in world detail/settings, onboarding, subscription, journey, profile visuals, explore widgets, and share/export widgets.
- `LinearGradient` and `BackdropFilter` remain in many surfaces. Some are acceptable for generated/share/export visuals or image text scrims, but ordinary app cards should be compact minimal Forui-style surfaces.
- `lib/widgets/core/empty_state.dart` still describes and implements glass/dashed/animated empty states. The "no posts" and similar empty states should become minimal icon/title/body/CTA layouts.

### P3 / Cleanup

- `lib/theme/colors.dart` and `lib/theme/design_system.dart` contain TODOs to migrate to `VColors`, `VSpacing`, `VRadius`, etc.
- UI wrappers exist under `lib/ui/**`; prefer improving/reusing these wrappers before spreading raw Forui/Material styling everywhere.
- The audit needs to be real and maintained as fixes land.

## Target Product Direction

Vertiege should feel like a compact, clean, social/world app:

- Light theme: white or near-white surfaces, dark readable text, restrained borders.
- Dark theme: AMOLED black surfaces, white/high-contrast text.
- Accent color is allowed for world identity, rarity, semantic status, and primary actions.
- No heavy glass cards, decorative blur panels, harsh gradients, or oversized hero typography inside normal app surfaces.
- Images should remain natural. Use only subtle bottom scrims when text overlays image content.
- Mobile compactness: 16px page margins, 8-12px gaps, 12-14px body text, 44px+ tap targets, no clipped labels.
- Empty states: subtle icon, short title, useful body, optional CTA.

## Phase 0: Baseline And Report

Create `docs/audits/opencode-full-app-audit.md` before implementation.

Group findings by:

- P0: blocks core app use.
- P1: breaks persistence/data trust.
- P2: visible UX quality issue.
- P3: cleanup/refactor.

Include:

- File references.
- Root cause.
- User impact.
- Proposed fix.
- Verification command or manual acceptance step.

Do not mark findings fixed until code is changed and verified.

## Phase 1: Supabase Migration And RLS Safety

Scope:

- `supabase/migrations/**`
- `supabase/functions/**`
- Supabase-facing service/repository tests where needed.

Tasks:

- Make migration filenames deterministic and uniquely ordered. Avoid destructive rewrites for existing projects.
- Audit policies for posts, comments, reactions, bookmarks, worlds, memberships, channels, channel reads, polls, marketplace, treasury, notifications, chat, storage, and media.
- Verify authenticated users can read permitted feed rows without 42501.
- Verify denied rows stay denied.
- Add missing indexes/constraints where needed:
  - one membership per user/world,
  - one bookmark per user/post,
  - one reaction per user/post/reaction type when applicable,
  - channel lookup by world/default/name,
  - post feed by world/created_at/author.
- Add or repair RPCs for atomic behavior:
  - join world,
  - create post with media,
  - react/unreact,
  - bookmark/unbookmark,
  - comment count updates,
  - poll vote.

Acceptance:

- Fresh Supabase project can apply migrations once.
- Existing project can apply new migrations without reset.
- Static SQL review explains why feed reads work.
- Authenticated user can join starter worlds, read channels, create post/comment/reaction/bookmark, refresh, and still see data.

## Phase 2: Default Worlds, Lore, And Starter Channels

Scope:

- `lib/config/tiers.dart`
- `lib/models/channel.dart`
- `lib/models/world.dart`
- `lib/services/world_service.dart`
- `lib/state/channel_provider.dart`
- `lib/screens/onboarding/**`
- `lib/screens/world_channel_screen.dart`
- `lib/utils/world_foundations.dart`
- Supabase seed/backfill migration.
- Tests under `test/config`, `test/services`, and `test/repositories`.

Tasks:

- Mark intended default starter worlds explicitly. Use `neon-district` and `crystal-shore` unless product direction changes.
- Replace onboarding hardcoded starter slug logic with `world.isDefault == true`.
- Add persistent channel foundation content for `info`, `rules`, and `roles`.
- Recommended schema:
  - `channels.foundation_markdown TEXT`
  - `channels.foundation_version TEXT NOT NULL DEFAULT 'v1'`
- Update `WorldChannel` to include `foundationMarkdown` and `foundationVersion`.
- Channel UI should load Supabase `foundationMarkdown` first, then fallback to `world_foundations.dart`.
- `WorldService.createDefaultChannels()` should seed per-world channel descriptions and foundation markdown.
- Backfill existing default channels.

Per-world content themes:

- Neon District: entry realm, ambition, first posts, social etiquette, beginner roles.
- Crystal Shore: calm newcomer realm, introductions, exploration, low-pressure participation.
- Azure Coast: coastal economy, deals, luxury culture, trade etiquette.
- Crimson Court: intrigue, status, alliances, reputation boundaries.
- Sovereign City: governance, influence, formal conduct, civic roles.
- Golden Estate: legacy, patronage, stewardship, estate etiquette.
- Aetheria: mythic apex realm, legends, prestige, ceremonial roles.
- Nova Station: frontier outpost, missions, crew protocol, exploration roles.
- Aviation Heights: pilots/aerospace, safety-first rules, squadron roles.
- Medical Nexus: healthcare knowledge, no unsafe medical advice, clinical roles.
- Financial District: market/capital discussion, no scams, no guaranteed advice, analyst roles.
- Tech Sprawl: builders/code/product, no exploit sharing, engineering roles.
- Legal Plaza: law/civic debate, no legal advice guarantees, advocate roles.
- Arts Pavilion: creative critique, attribution rules, creator roles.
- Quantum Core: research, experimental rigor, lab roles.
- Silver Page: writers/storytellers, critique etiquette, editorial roles.

Acceptance:

- 16 unique world slugs.
- Exactly intended starter worlds are default.
- Every default world has non-empty lore.
- Every default world has unique `info`, `rules`, and `roles` markdown.
- New account lands in starter worlds and can enter them.

## Phase 3: Onboarding And World Join Reliability

Scope:

- `lib/screens/onboarding/**`
- `lib/screens/world_detail_screen.dart`
- `lib/widgets/worlds/world_access_guard.dart`
- `lib/services/access_control.dart`
- `lib/state/world_provider.dart`
- `lib/repositories/world_repository.dart`
- `lib/services/world_service.dart`
- Tests.

Tasks:

- Trace starter world auto-join from onboarding completion to resident/world membership state.
- Ensure default starter memberships persist remotely when Supabase is configured.
- Ensure local starter access fallback does not get mistaken for remote success.
- Ensure default starter worlds are accessible after onboarding before tier/profession gates.
- Failed remote joins should show/log actionable failure and use retry/outbox where appropriate.

Acceptance:

- User can enter first starter world without redirect back to Nexus.
- World membership survives app restart.
- Failed non-starter joins are visible and retryable, not silently discarded.

## Phase 4: Durable Persistence And Repository Cleanup

Scope:

- `lib/repositories/**`
- `lib/services/**`
- `lib/state/**`
- `lib/models/**`
- Tests.

Tasks:

- Treat local storage as cache, preferences, drafts, and outbox only.
- Add or complete repository/service methods for authoritative Supabase persistence:
  - posts,
  - comments,
  - reactions,
  - bookmarks,
  - polls,
  - memberships,
  - notifications,
  - chat,
  - treasury,
  - marketplace,
  - quests,
  - alliances,
  - events,
  - achievements,
  - channel reads.
- Use cache-first loading followed by Supabase refresh and realtime updates.
- Ensure optimistic UI uses durable mutation outbox with temp IDs, retry/backoff, reconciliation, and visible failed states.
- Remove fake success returns from mutations when Supabase/auth is missing.
- Decide whether `offline_queue.dart` and `mutation_outbox_service.dart` should merge or have strict separate responsibilities.

Acceptance:

- Create/edit/delete/pin post, comment, react, bookmark, poll vote, join world, create listing, treasury transfer, quest progress, and alliance action survive restart and refresh.
- Offline failed actions are visible and retryable.

## Phase 5: Forui UI/UX Migration

Scope:

- All screens under `lib/screens/**`.
- All widgets under `lib/widgets/**`.
- App UI wrappers under `lib/ui/**`.
- Theme files under `lib/theme/**`.

Tasks:

- Build/standardize app wrappers on top of Forui:
  - buttons,
  - cards,
  - inputs,
  - badges,
  - tabs,
  - dialogs/sheets,
  - empty/loading/error/offline states,
  - avatar/media patterns,
  - nav controls.
- Remove ordinary app usage of:
  - `GlassPanel`,
  - `GlassSheet`,
  - `SovereignCard`,
  - hard decorative gradients,
  - heavy `BackdropFilter`,
  - screen-level `GoogleFonts` overrides.
- Preserve custom generated/share/export visuals only where they are clearly output assets, not interactive app surfaces.
- Replace "no posts" and noisy empty art with compact empty states.
- Keep image art natural. Use subtle scrims only when text overlays media.

Priority screens:

- Nexus/feed.
- Explore/world discovery.
- World detail.
- World channels.
- World settings.
- Profile/identity.
- Onboarding/auth.
- Chat.
- Notifications.
- Achievements.
- Cosmetics.
- Treasury.
- Marketplace.
- Polls.
- Quests/challenges.
- Modals/sheets.

Acceptance:

- `rg "GlassPanel|GlassSheet|SovereignCard|GoogleFonts|LinearGradient|BackdropFilter" lib` only shows intentional exceptions with comments.
- No white text on white, black text on black, clipped labels, or oversized card headings in compact mobile surfaces.
- Light and dark themes are readable at normal and enlarged text scales.

## Phase 6: Feature Completeness Audit

Audit every feature that has UI but may be incomplete, stubbed, local-only, or disconnected.

Categories:

- Buttons with no effect.
- Screens that load empty because services return `[]`.
- Mutations returning `false` without actionable UI.
- Missing loading/error/empty states.
- Missing realtime updates.
- Missing storage bucket policies.
- Missing seed data/images.
- Android back behavior.
- Keyboard overlap.
- Safe areas.
- Pull-to-refresh.
- Accessibility labels and tap targets.

Deliver:

- Update `docs/audits/opencode-full-app-audit.md`.
- Create a checklist of fixes by severity.
- Implement P0/P1 first.

## Phase 7: Verification

Required automated checks:

- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`
- `flutter build apk --release`

Recommended tests:

- World config has 16 unique slugs.
- Exactly intended starter worlds are default.
- Every default world has lore.
- Every default world has unique channel foundation markdown.
- Onboarding joins default starter worlds.
- Feed read does not produce 42501 for authenticated users.
- Post/comment/reaction/bookmark persist after provider refresh.
- Local cache is not treated as authoritative after Supabase refresh.
- UI smoke checks for Nexus, Discover, World Detail, World Channel, Profile, Composer, Comments, Settings, Auth, and empty states in light/dark themes.

Manual acceptance:

- New account completes onboarding.
- User lands in starter worlds.
- User can enter first starter world without redirecting back to Nexus.
- Nexus posts load without 42501.
- User creates post, comments, reacts, bookmarks, joins world, restarts app, and all actions remain.
- Default channels show world-specific info/rules/roles content.
- App feels compact, white/minimal in light mode and AMOLED clean in dark mode.

## Suggested PR Order

1. Supabase migration/RLS safety.
2. Default worlds and starter channel content.
3. Onboarding and world join reliability.
4. Post/feed/comment/reaction/bookmark persistence.
5. Polls/marketplace/treasury/chat/notifications persistence.
6. UI wrapper cleanup.
7. Nexus and Explore Forui pass.
8. World detail/channels/settings Forui pass.
9. Profile/auth/onboarding/chat/notifications Forui pass.
10. Final audit, APK build, and manual acceptance fixes.
