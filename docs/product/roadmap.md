# Vertiege Completion Plan: Worlds, Progression, Commerce, and Social Loops

## Summary

Build Vertiege 1.0 around the core promise: real-life achievements drive XP and tier, worlds provide social/economic status, and paid features stay cosmetic or convenience-only.

Key decisions locked:
- Campfire unlocks at world prestige 25 through existing `audioRooms`; Lounge starts earlier at world prestige 10.
- Lounge is a combined high-status space: text lounge at prestige 10, voice Campfire lounge at prestige 25, both for Veteran+ residents, council, and sovereigns.
- Use one post composer with capability-gated options.
- Subscriptions launch in v1, but no XP boosts, paid progression, paid world access, or pay-to-win advantages.
- Cosmetics are purchasable with sovereign coins and real money.
- Council approval required for treasury withdrawals, job posting, rank changes, and major governance actions; poll creation is allowed for qualified high-level residents.
- Challenges should be seasonal/world/team scoped, not permanent global-only. Research supports fair cohorts, opt-out/low-pressure paths, friend/team quests, and visible streak/progress loops.
- Public profile v1 includes verified achievement wall, badges, titles, featured achievements, and equipped cosmetics.
- Invite links redirect signed-out users through login/signup and auto-accept after auth.
- Android support target: run on at least Android 11/API 30 for “5-year-old OS” UAT, while keeping current lower `minSdk` if dependencies allow; Play submission must target current Play requirements, currently Android 15/API 35+ per Google Play docs.

Research anchors:
- Duolingo leagues use weekly cohorts, similar-habit matching, tournaments, opt-out, and anti-cheat monitoring: [Duolingo Leaderboards](https://blog.duolingo.com/duolingo-leagues-leaderboards/).
- Duolingo streak research shows retention gains from commitment loops and break-protection, not raw grind: [Duolingo Streaks](https://blog.duolingo.com/how-streaks-keep-duolingo-learners-committed-to-their-language-goals/).
- Gamification research warns against simplistic leaderboards and recommends designs that support autonomy, competence, and relatedness: [Springer SDT gamification paper](https://link.springer.com/article/10.1007/s11528-024-00968-9).
- Google Play target API requirements require modern target SDKs while still allowing older runtime support: [Android target API requirements](https://developer.android.com/google/play/requirements/target-sdk).

## Already addressed (baseline — do not re-plan)

Tracked in detail: [perfection-backlog.md](planning/perfection-backlog.md) (Waves 0–6), [issue-log.md](../operations/uat/issue-log.md) (device UAT).

| Area | Status | Notes |
|------|--------|--------|
| **Waves 0–6** (polish, nav, load errors, Forui hubs, security migration, world detail shell) | **Done** on `main` | See backlog; Wave 6 full device sign-off still open |
| **UAT #1** — achievement badge PNGs | **Fixed** | `pubspec.yaml` → `assets/generated/achievements/` |
| **UAT #2** — world detail Channels/Members grey void | **Fixed** | Single inner scroll + `Column(min)`; no child `VLoadingCard` for residents; InkWell rows |
| **Brand splash** | **Done** | New mark assets + theme-aware `brandMarkAsset` |
| **Wave 7** (voice / Lounge / Campfire) | **Done (code)** — device UAT pending | Routing, gates, seed migration, tools panel, LiveKit validation |
| **Wave 8** (composer) | **Done (core)** | `PostInput` + `PostCapabilities` + `create_post` RPC |
| **Wave 9** (commerce) | **MVP done** | Receipt RPC (token dedupe), coin cosmetics; real store verify TBD |
| **Wave 10** (governance) | **Partial** | Manage hub + treasury proposals + council queue |
| **Wave 11** (progression) | **Partial** | Challenge `scope`, opt-out, `display_title`; seasons TBD |
| **Wave 12** (release) | **Partial** | Invites; Forui + API 30 smoke open |
| **Wave 12** regression | **#1 + #2 only** | Re-smoke badge PNGs and world tab layout after each release |

When implementing a wave below, **extend** these docs; do not reopen closed UAT items unless regression.

## Key Changes

### 1. Voice, Lounge, and World Status

- Keep existing unlock constants as the source of truth:
  - `lounge` at prestige 10.
  - `audioRooms` at prestige 25.
  - `marketplace` at prestige 30.
  - `treasury` at prestige 35.
  - `governance` at prestige 50.
- Define Lounge eligibility as world prestige 10 plus resident standing level 4/Veteran or higher, with sovereign/council override.
- Add a Lounge text channel for eligible residents and a Campfire voice room inside Lounge once `audioRooms` unlocks.
- Route voice channels to Campfire, never to the text channel screen.
- Add connecting, failed, disconnected, muted, deafened, and permission-denied states to voice UI.
- Validate LiveKit token requests server-side against authenticated user, world membership, channel type, and eligibility.

### 2. Unified Composer

- Consolidate `PostInput`, `PostComposer`, and `CreatePostScreen` into one canonical composer component.
- Route all compose entry points through this component: Nexus FAB, world feed composer, post reply/decree/announcement entry points.
- Add a shared post capability service for:
  - text post
  - media
  - poll
  - scheduled post
  - announcement
  - decree
  - pinned post
- Enforce the same capabilities in UI and server write path.
- Replace raw privileged post writes with a server-enforced post creation RPC so announcement/decree/pin/poll permissions cannot be bypassed.

### 3. Subscriptions and Cosmetics Without Pay-to-Win

- Ship subscriptions in v1 as cosmetic/convenience only:
  - subscription badge
  - profile frame/name treatment
  - extra cosmetic slots
  - profile analytics
  - saved drafts
  - priority support/review queue visibility, without approval advantage
- Remove or disable paid XP multipliers, paid world access, paid world boosts, paid post pin advantages, and paid world creation expansion.
- Replace current “activated” subscription UI with receipt-backed entitlement verification.
- Split store products into subscription products, coin packs, and direct cosmetic purchases.
- Move cosmetic purchase/grant logic to server-backed atomic flows:
  - purchase with sovereign coins
  - purchase/grant from real-money receipt
  - equip/unequip cosmetic
- Keep sovereign coins earnable through achievements/activity so real-life achievement remains the main game.

### 4. Worlds, Council, and Governance

- Add a world “Manage / Participate” hub that exposes Marketplace, Treasury, Polls, Jobs, Archive, Lounge, Settings, and Audit Log with visible gate reasons.
- Council approval required for:
  - treasury withdrawals
  - job postings
  - rank changes
  - major settings/governance changes
- Poll creation allowed for qualified high-level residents without council approval; council/sovereign can close or moderate polls.
- Treasury withdrawals use proposals: requested, approved, rejected, executed.
- Job postings use approval before publishing; applications keep current pending/accepted flow.
- Audit log records approvals, withdrawals, job publications, rank changes, poll moderation, and treasury actions.

### 5. Challenges, Seasons, and Retention Loops

- Replace `/challenges` global empty-world sentinel with an explicit model:
  - daily quests are personal
  - world challenges are world-scoped
  - season challenges are cohort/team scoped
- Do not use a permanent global leaderboard as the main challenge model.
- Add fair seasonal cohorts based on tier/activity band and timezone.
- Add world/team challenges that encourage cooperation, not only individual grinding.
- Add opt-out or low-pressure mode for competitive rankings while preserving daily quests and world participation.
- Add anti-abuse checks for XP spikes, repeated actions, and paid-item exclusion from rankings.
- Add streak protection through earned items or subscription convenience only if it does not affect XP/tier outcomes.

### 6. Profile, Identity, and Achievements

- Public profile v1 includes:
  - verified achievement wall
  - featured achievements
  - badges
  - titles
  - equipped cosmetics
  - visibility controls per achievement
- Add profile management for selecting title, featured achievements, badge, avatar frame, and name treatment.
- Persist title/cosmetic/profile display fields through profile service, not only local resident state.
- Keep manual achievement review as the core XP source; in-app achievements remain secondary and server-authoritative.

### 7. Invites, Deep Links, and Android UAT

- Generate full invite deep links, not just invite codes.
- Signed-out invite links redirect to login/signup, preserve the invite, and auto-accept after resident creation/auth.
- Add Android manifest handling for invite links in addition to auth/verifier links.
- Android UAT baseline:
  - primary release surface: Android release APK.
  - minimum test OS: Android 11/API 30 because that is approximately five years old in 2026.
  - keep current lower `minSdk` if Flutter/dependencies support it, but do not claim support without smoke testing.
  - target SDK must satisfy Play requirements at release time.

## Implementation Waves

### Wave 7: Truthful Voice and Lounge

- Add voice-aware channel routing and Campfire entry points.
- Add Lounge eligibility checks and UI gate reasons.
- Add LiveKit membership validation.
- Update UAT checklist for Lounge text, Campfire unlock, join failure, mini-bar, and leave behavior.

### Wave 8: One Composer

- Choose the canonical composer implementation and remove dead route drift.
- Add post capability service.
- Add server-enforced post creation path.
- Smoke test Nexus compose, world compose, polls, announcements, decrees, and pinned posts.

### Wave 9: Commerce v1 Without Pay-to-Win

- Replace subscription activation with receipt-backed entitlement.
- Rewrite subscription benefits to cosmetic/convenience only.
- Add server-backed cosmetics catalog and purchase/grant flows.
- Disable or remove paid progression features from UI copy and enforcement.

### Wave 10: Governance and World Economy

- Add world Manage/Participate hub.
- Add council approval queue for treasury withdrawals, job postings, and rank changes.
- Add poll permission model for high-level residents.
- Expand audit log to show resident names and governance actions.

### Wave 11: Progression and Seasons

- Replace global challenge sentinel with explicit daily/world/season scopes.
- Add fair cohorts and low-pressure opt-out.
- Add leaderboard anti-abuse checks.
- Finish public profile achievements, badges, titles, featured achievements, and equipped cosmetics.

### Wave 12: Release Polish and Android UAT

- Complete Forui polish on forms/dialogs most visible in commerce, verifier, create world, settings, and world management.
- Add invite deep-link auth continuation.
- Run release APK smoke on Android 11/API 30 and current Android emulator.
- Keep UAT #1 and #2 only as regression checks: achievement PNGs and no world-detail grey void.

## Public Interfaces and Data Additions

- Add `PostCapabilities` model/service used by composer UI and post provider.
- Add server post creation RPC for capability-enforced posting.
- Add voice token validation input for world/channel context.
- Add cosmetic catalog, user cosmetics, purchase receipt, and coin transaction concepts.
- Add subscription entitlement verification path.
- Add governance proposal/action model for treasury, jobs, ranks, and audit events.
- Add challenge scope field or separate models for daily, world, and season challenges.
- Add profile display fields for title, featured achievements, badge, avatar frame, and name treatment.
- Add invite continuation state for post-login auto-accept.

## Test Plan

- Voice:
  - non-eligible resident sees Lounge/Campfire gate reason.
  - eligible resident opens Lounge text.
  - prestige 25 world shows Campfire voice entry.
  - token request fails for non-member or non-voice channel.
  - mini-bar appears only after successful connection.

- Composer:
  - same composer opens from Nexus and world feed.
  - unavailable options are hidden or disabled with reasons.
  - server rejects unauthorized announcement/decree/pin/poll attempts.

- Commerce:
  - failed/canceled purchase does not activate subscription.
  - subscription benefits never alter XP, tier, world access, or rankings.
  - coin cosmetic purchase is atomic.
  - real-money cosmetic receipt grants exactly one owned cosmetic.

- Governance:
  - treasury withdrawal requires council approval.
  - job post requires approval.
  - rank change requires approval.
  - qualified resident can create poll without approval.
  - audit log records each action with readable actor names.

- Progression:
  - daily quest claim updates XP through server-authoritative path.
  - world challenge progress is world-scoped.
  - season cohort leaderboard excludes paid boosts.
  - opt-out hides competitive ranking without disabling quests.

- Profile:
  - public profile shows verified wall, featured achievements, title, badge, and cosmetics.
  - hidden achievements do not appear publicly.
  - equipped cosmetics persist after restart.

- Android:
  - release APK installs and runs on Android 11/API 30.
  - release APK also passes current emulator smoke.
  - invite link opens app, auths if needed, then auto-accepts.

## Assumptions

- “Only at certain level” maps to existing world prestige gates: Lounge at 10, Campfire/audio at 25.
- “High-level residents” maps to Veteran standing or higher in a specific world, plus sovereign/council overrides.
- “Avoid pay-to-win” means paid features must not affect XP, tier, world access, governance power, marketplace advantage, rankings, or achievement approval probability.
- “Both” for cosmetics means sovereign coins and real money can grant cosmetics, but neither path grants progression.
- “All” public profile promise includes achievements, badges, titles, featured achievements, and equipped cosmetics.
- Android 11/API 30 is the UAT floor for the “5-year-old operating systems” promise; lower Android versions may remain technically supported only if smoke-tested.
