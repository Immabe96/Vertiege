# Gamification & Worlds Vision — Gap Audit

**Date:** 2026-05-24  
**North star:** [docs/vision/gamification-and-worlds.md](../vision/gamification-and-worlds.md)  
**Method:** Full codebase + Supabase schema review, verifier flows, prior audits, and external research (manual review UX, badge portability, game economy loops, world governance patterns).

---

## Executive summary

Vertiege has a **strong scaffold** for your vision: a large achievement catalog (~90 definitions), manual verifier portal with image preview, in-app auto-triggers for posts/streaks/worlds, tier/standing models, and world subsystems (channels, council permissions, treasury, marketplace, activity score).

**Update 2026-05-25:** G0–G2 implemented (server XP, proof specs, public profile showcase). Remaining gaps are mainly **G3/G4** (world economy loops, capability matrix, world dossier rebuild).

1. ~~**Split XP truth**~~ — Resolved in G0: verifier grant + in-app unlocks update `profiles.total_xp`; UI uses `resident.totalXp`.
2. ~~**Social profile**~~ — G2: public verified achievements + hide/show on proof sheet.
3. ~~**Proof product**~~ — G1: per-achievement proof rules, multi-image, approve/reject messages, reason codes.
4. **Worlds as mini-societies** — About dossier + economy gates shipped (G3/G4); voting loop still thin.
5. ~~**Catalog growth**~~ — `life` category + 10 seeds; 100 achievements in config.

**Overall alignment (rough):**

| Pillar | Alignment |
|--------|-----------|
| Real-life proof achievements | **Partial** (~60%) |
| In-app activity achievements | **Partial** (~55%) |
| XP → tier → capabilities | **Partial** (~45%) |
| Public profile showcase + privacy | **Weak** (~20%) |
| Worlds as growing mini-societies | **Partial** (~40%) |

---

## 1. Real-life standing (proof achievements)

### Aligned today

| Item | Evidence |
|------|----------|
| Rich categories | 12 `AchievementCategory` values; ~75 non–in-app achievements in `lib/config/achievements.dart` |
| Funny / creative tone | 10 funny + 5 creative entries (dark/naughty can extend here or new category) |
| Manual review path | `verification_review_screen.dart` → `AchievementReviewService`; RLS `achievements_verifier_*` |
| Proof upload | `AchievementProofUpload` → `achievement-proofs` storage; signed URL in `proof_uri` |
| Reject with message | Reject dialog → `ai_notes` column (stores **reviewer** text) |
| User pending UX | Proof sheet: “manual review queue” copy; rejected notes shown on list tile |
| AI removed | `ai_verification_service.dart` deleted; submit always `submitted` |

### Missing or weak

| Gap | Impact | Severity |
|-----|--------|----------|
| **No “life/misc” category** | Hard to grow “random life” achievements without overloading `funny` | Medium |
| **Single proof image** | Cannot require object + location + certificate as separate assets | High |
| **No proof spec on achievement model** | All achievements share one generic “optional photo” UX | High |
| **Approve without message** | You can congratulate on reject only; approve is silent | Medium |
| **Verifier UX minimal** | One thumbnail, no gallery, no achievement criteria panel, no resident history | Medium |
| **No resubmit flow clarity** | Rejected → user can resubmit, but no structured “what to fix” template | Low |
| **Proof URL expiry** | Signed URLs (1 year); long-term reviewer history may break | Low |
| **`proof_uri = 'manual'`** | Text-only submissions skip image in verifier UI | Low |

### Research-informed improvements

**Manual review queue (your differentiator)**  
Industry guidance for human review: show *what happened, why it’s here, evidence, next action* in one screen ([Approvals.us workflow guide](https://approvals.us/how-to-build-a-verification-workflow-with-manual-review-esca)). For Vertiege:

- **Reviewer card:** achievement title + description + proof requirements + resident tier + past rejections.
- **Reason codes** on reject (e.g. “blurry”, “wrong subject”, “needs date visible”) → map to friendly user messages.
- **Optional approve message** (congratulations) stored in same `reviewer_notes` field — users cited this as motivation in your vision.

**Growing catalog**  
Treat achievements like **content**, not code-only constants:

- `Achievement` metadata: `proofType` (none | single | multi | location), `minImages`, `hintText`, `sensitivity` (public | hidden-by-default), `reviewerChecklist[]`.
- Start **life** category in config with 5–10 seed entries; add via PRs without app releases once server-driven catalog exists (phase 2).

**Badge portability (optional later)**  
[Open Badges 3.0](https://www.imsglobal.org/spec/ob/v3p0) is overkill for beta, but the idea helps: **issuer = Vertiege**, **revocable credential**, share card with verification link. Your `achievement_share_card.dart` is a seed — link to public profile achievement slug later.

---

## 2. In-app activity achievements

### Aligned today

| Item | Evidence |
|------|----------|
| Dedicated in-app category | 15 achievements in `AchievementCategory.inApp` |
| Triggers implemented | Posts (4), joined worlds (3), streaks (8) via `post_provider` / `resident_provider` |
| Instant unlock UX | `autoAwardAchievement` + haptics + tier celebration listener |
| Titles from achievements | `config/titles.dart` maps ~20 achievement IDs → display titles |

### Missing or weak

| Gap | Impact | Severity |
|-----|--------|----------|
| **Auto-unlocks not persisted to Supabase** | `autoAwardAchievement` only updates local `StorageService` cache | **Critical** |
| **No server trigger for in-app rules** | Cheating / reinstall loses unlocks; other devices don’t see them | **Critical** |
| **Incomplete trigger coverage** | Quests (react, comment, visit worlds) don’t map to achievements | Medium |
| **No push/in-app notification on unlock** | Missed delight loop | Medium |
| **~60+ proof achievements have no in-app path** | By design — but needs clear UI “proof required” | Low |

### Research-informed improvements

**Google Play Games achievement hygiene** ([quality checklist](https://developer.android.com/games/pgs/quality)): unique names, clear descriptions, attainable, not front-loaded. You already have breadth; add **progress indicators** on locked in-app achievements (e.g. “7/10 posts”).

**Server-authoritative in-app awards**  
Add RPC `award_in_app_achievement(p_user_id, p_achievement_id)` (security: `auth.uid() = p_user_id` + idempotent insert) that:

- Upserts `user_achievements` verified
- Calls shared `recompute_profile_xp_from_achievements(user_id)` (see §3)

Wire triggers from Edge Function or client after validated events (post insert count, check-in RPC callback).

---

## 3. XP → identity → worlds (the bridge)

### Aligned today

| Item | Evidence |
|------|----------|
| XP per achievement in config | `xpValue` on each `Achievement` |
| Tier thresholds | `xpThresholds` / `getTierForXp` / 5 `ResidentTier` levels |
| Identity “Wall of Honour” | `identity_screen.dart` uses **achievement** `totalXp` for progress bar |
| Server activity XP | `award_activity_xp` RPC; `record_daily_check_in` RPC |
| Gamification guard | `profiles_guard_gamification_writes` blocks client XP tampering |
| Server reconcile on login | `applyServerGamification` + `refreshGamificationFromServer` |
| World creation gate | High Roller (500+ XP) via `AdminAccessService.canCreateWorld` |
| World rep / standing | `WorldPermissions`, rep milestones, council at 5000 rep |
| World activity growth | `activityScore`, `getWorldLevel`, boost in settings |

### Critical architecture gap: two XP systems

```
┌─────────────────────────────┐     ┌──────────────────────────────┐
│ achievementProvider.totalXp │     │ profiles.total_xp (server) │
│ = sum(verified achievements)│  ≠  │ += award_activity_xp,       │
│                             │     │   check-in, council, etc.    │
└─────────────────────────────┘     └──────────────────────────────┘
         │                                      │
         ▼                                      ▼
 Identity UI, Nexus bento tier progress    Profile tier on server,
                                            create-world gate (?)
```

**Symptoms:**

- `AchievementReviewService.approve()` only sets `status=verified` — **does not** bump `profiles.total_xp`.
- `updateTier()` in `resident_provider` is **local only** after achievement XP changes; `refreshGamificationFromServer()` can **overwrite** tier from server.
- `ResidentProfileScreen` uses `resident.tier` from profile, not achievement XP, for visitors.
- `autoAwardAchievement` never writes `user_achievements` to cloud.

**Severity: Critical** — This undermines “achievements exist to earn XP” as the single progression ladder.

### Recommended fix (single source of truth)

1. **Server function** `sync_achievement_xp(p_user_id)`:
   - `total_xp = SUM(xp from config join user_achievements WHERE verified)` + optional **activity XP ledger** if you want both.
   - Update `profiles.tier` from thresholds.
   - Run on: verifier approve, in-app RPC award, admin tools.

2. **Client** displays `profiles.total_xp` after sync; `achievementProvider` becomes a **view** of rows + celebration state, not parallel XP math.

3. **Document** whether activity XP (quests, league) **adds** to achievement XP or shares one pool — your vision says achievements → XP; recommend **one pool** with labeled sources in UI.

### Tier → world capabilities (partial)

| Capability | Tier / standing wired? |
|------------|-------------------------|
| Create dominion world | Yes (tier ≥ 2 / XP) |
| Luminary nameplate | Yes (`LuminaryNameplate`) |
| World post/comment/moderate | Rep + constitution, not global tier |
| Marketplace create listing | Member flag; unclear tier flair |
| Treasury manage | Sovereign/council flag |
| High-tier-only channels | Partial via constitution |

**Improvement:** Publish a **capability matrix** (tier × world role) in `docs/vision/` and enforce in `PermissionService` + UI tooltips so players feel XP matter in worlds.

---

## 4. Public profile (visit others)

### Aligned today

| Item | Evidence |
|------|----------|
| Route exists | `ResidentProfileScreen` `/resident/:id` |
| Avatar, nameplate, tier, profession, bio, streak | Shown |
| Badges | `BadgeDisplay` from `resident.decorations` |
| Social actions | Message, ally, follow |
| Own identity hub | Wall of Honour with achievements entry |

### Missing (vision blockers)

| Gap | Severity |
|-----|----------|
| **No achievement list on other profiles** | **High** |
| **RLS: `user_achievements` self-read only** | Visitors cannot load others’ verified badges from API |
| **No hide/show per achievement** | No schema field (`is_public`, `hidden_at`) |
| **No “featured” achievements** | No pin top 3 on profile |
| **Titles visible** | `LuminaryNameplate` shows `resident.title` — good |
| **XP on others’ avatar ring** | `totalXp: 0` when not own profile — intentional but hides standing |

### Research-informed improvements

**Social signaling** ([7BlockLabs on consumer badges](https://www.7blocklabs.com/blog/developing-social-signaling-badges-for-consumer-apps)): profiles should answer “who is this person?” in &lt;3 seconds — **tier + 3 featured achievements + title**.

**Privacy model:**

```sql
-- user_achievements additions
is_profile_visible BOOLEAN DEFAULT true,
featured_order SMALLINT NULL,
```

- RLS policy: `SELECT` where `status = 'verified' AND is_profile_visible = true` for any authenticated user (or public read).
- Owner toggles in achievement detail sheet.

**Profile sections:**

1. Header (avatar, nameplate, tier, title)  
2. Featured achievements (grid)  
3. All achievements (collapsible, respects visibility)  
4. Worlds / rep summary (future)

---

## 5. Worlds as “real-life mini worlds”

### Aligned today (infrastructure)

| Dimension | Status |
|-----------|--------|
| Communication | Channels, DMs, realtime messages |
| News | Announcements tab / sovereign posts |
| Management | `world_settings_screen` (large); sovereign/council checks |
| Knowledge | Foundation/guide content on some worlds |
| Social | Members, allies, following |
| Standing | Rep per world, standing levels, constitution rules |
| Growth signal | `activityScore` → world level in settings |
| Economy screens | `WorldMarketplaceScreen`, `WorldTreasuryScreen` + services |
| Discovery | Trending by activity score |

### Missing vs vision

| Gap | Notes | Severity |
|-----|-------|----------|
| **World info / dossier** | ~~Thin~~ **About tab dossier** (G4) | ✅ |
| **Jobs / roles** | ~~No board~~ `world_jobs` + `WorldJobsScreen` + Manage/About tiles | ✅ |
| **Economy loop** | ~~Weak~~ coin-priced listings, `purchase_listing` tax → treasury, donate RPC | ⚠️ (XP/rep rewards still partial) |
| **World grows with people** | Activity score increments exist; not clearly shown on world home | Medium |
| **Governance voting** | ~~Coming soon~~ poll preview on About + `WorldPollsScreen` + `vote_on_poll_v2` | ✅ |
| **Tier flair in world** | Global tier visible; limited per-world cosmetic unlocks | Medium |
| **Cooperation / corp standing** | Alliances widget exists; shallow | Medium |

### Research-informed improvements

**Economy loop design** ([sources/sinks/loops](https://dev.to/hiroshi_takamura_c851fe71/how-to-design-a-game-economy-sources-sinks-loops-and-balance-j05)):

- **Sources:** achievement XP, world activity, quest claim, league placement, check-in.  
- **Sinks:** marketplace tax → treasury, boost purchase, cosmetic frames, world creation fee.  
- **Loop:** earn standing in world → unlock listing tier → spend coins → treasury funds sovereign tools.

**Governance** ([Infiblue / Ludum Vitae patterns](https://docs.ludumvitae.org/docs/core-features/spheres)): start simple — **weekly council poll** on constitution snippet, not full DAO. Sticky rules match your “worlds have rules” vision.

**World level visibility:** Show level + “next milestone” on world detail hero (not only settings).

---

## 6. Cross-cutting findings

### Data model (`user_achievements`)

Current columns: `proof_uri` (single TEXT), `ai_notes` (reviewer notes), `ai_confidence` (legacy unused).

**Suggested evolution:**

| Column | Purpose |
|--------|---------|
| `proof_uris JSONB` | Multiple images |
| `reviewer_notes TEXT` | Rename from `ai_notes` |
| `reviewer_id TEXT` | Audit trail |
| `approved_at` | Already have `verified_at` |
| `is_profile_visible BOOLEAN` | Privacy |
| `proof_metadata JSONB` | Location tag, caption per image |

### Notifications & engagement

- No dedicated push type for achievement approved/rejected with reviewer message deep link.
- No email digest for pending reviews (verifier-only pain).

### Content & assets

- ~64 assets still pending per `MANUAL_REMAINING.md` — achievement icons fall back to generic.
- Unique icons per achievement improve recognition ([Play Games guideline 2.4](https://developer.android.com/games/pgs/quality)).

### Docs drift

- `docs/VERIFIER_PORTAL.md` still says “AI auto-approval … until that ships” — update to manual-only.
- `docs/PROGRESS.md` says “67 achievements” — catalog is ~90 now.

---

## 7. Prioritized roadmap (recommended)

### Phase G0 — Truth & trust **Implemented 2026-05-25 (local)**

1. ✅ `grant_verified_achievement` / `reject_achievement_submission` RPCs + `achievement_definitions` seed (`20260525200000_achievement_gamification_sync.sql`).  
2. ✅ In-app unlocks call server grant via `GamificationService`.  
3. ✅ Identity/Nexus prestige use `resident.totalXp` (server profile).  
4. ✅ Notifications `achievementApproved` / `achievementRejected` on verifier actions.  
5. ✅ Quick wins: approve message dialog, achievement description in verifier queue, **Auto** badge on in-app achievements.

**Deploy:** run `supabase db push` before testing on device.

### Phase G1 — Proof & review excellence **Implemented 2026-05-25**

1. ✅ `AchievementProofType` + `minProofImages` / `maxProofImages` / `proofHint` on `Achievement`; multi-image upload in proof sheet + submit screen (`20260525210000_g1_achievement_proof.sql`).  
2. ✅ Verifier: `ProofImageGallery`, achievement description, approve message dialog, reject reason codes (`achievement_reject_reasons.dart`).  
3. ✅ `AchievementCategory.life` + 10 seed achievements (config + migration).  
4. ✅ `proof_uris` JSONB column + backfill from `proof_uri`.

**Deploy:** `supabase db push` for `20260525210000`.

### Phase G2 — Social profile **Implemented 2026-05-25**

1. ✅ RLS `achievements_public_profile_read` + `is_profile_visible` / `featured_order` (`20260525220000_g2_profile_achievements.sql`).  
2. ✅ `ProfileAchievementShowcase` on `ResidentProfileScreen`; hide/show toggle on verified proof sheet.  
3. ⚠️ Share card still routes to category list, not per-achievement slug (deferred).

**Deploy:** `supabase db push` for `20260525220000`.

### Phase G3 — XP → world power **Implemented 2026-05-25 (core)**

1. ✅ Capability matrix: `lib/config/world_capability_matrix.dart` + `docs/vision/world-capability-matrix.md`.  
2. ✅ Marketplace listing + treasury donate gated by global tier + world standing; manage tab shows lock reasons.  
3. ✅ `WorldGrowthCard` on world detail (level/activity or prestige narrative).  
4. ✅ Daily quests: `user_daily_quests` + `claim_daily_quest` / `upsert_daily_quest_progress` RPCs; `quest_provider` syncs when Supabase configured.

**Deploy:** `supabase db push` for `20260525230000_g3_daily_quests.sql`.

**Remaining G3:** tier × role tooltips in more screens; deeper rep/XP rewards on marketplace actions.

### Post-audit world systems **Shipped 2026-05-25**

- ✅ Migration `20260525240000_post_audit_world_systems.sql` (jobs, coin listings, purchase → treasury tax, poll vote v2).  
- ✅ **Governance:** active poll preview on About; polls + vote UI; v2 results parsing.  
- ✅ **Job board:** `WorldJobsScreen`, council/sovereign post roles, standing/tier gates.  
- ✅ **Economy:** coin price on create/buy; tax rate on treasury + listing sheet; Manage tab tools.  
- ✅ **Share slug:** `/residents/:id?achievement=` highlights profile showcase + share card path.

**Verify:** `flutter test` (144 passed), `supabase db push`.

### Phase G4 — World dossier rebuild **Shipped 2026-05-25**

- ✅ **About** tab (`WorldRealmDossier`) — charter teaser/full, type lead, standing, economy gates, #info link, live news, governance alert, analytics.  
- ✅ Default tab split (About / Feed); spec: [world-realm-dossier.md](../vision/world-realm-dossier.md).  
- ✅ Orientation checklist, council leadership preview, removed dead info widgets.

---

## 8. Quick wins (can ship in days)

| Win | Effort | Status |
|-----|--------|--------|
| Approve dialog with optional congratulations note | Low | ✅ |
| Verifier: show achievement `description` under title | Low | ✅ |
| Mark in-app achievements with “Auto” badge in UI | Low | ✅ |
| Fix docs: VERIFIER_PORTAL, achievement count | Low | ✅ |
| `autoAwardAchievement` → server RPC | Medium | ✅ G0 |
| Quest claim calls `award_activity_xp` on server | Medium | ✅ G3 partial |

---

## 9. Alignment scorecard (detailed)

| Vision requirement | Status | Notes |
|--------------------|--------|-------|
| Multiple achievement categories | ✅ | 13 categories, 100 entries |
| Expand life/random/funny/dark | ✅ | `life` category + 10 seeds |
| Different proof per achievement | ✅ | `AchievementProofType` + min/max images |
| Multi-image proof | ✅ | `proof_uris` + gallery UI |
| Manual review only | ✅ | AI removed |
| Reviewer sees images | ✅ | `ProofImageGallery` |
| Approve/reject + message | ✅ | Approve + reject reason codes |
| In-app auto achievements | ✅ | Server `grant_verified_achievement` (G0) |
| Achievements → XP | ✅ | Server grant updates `profiles.total_xp` |
| XP → tier | ✅ | `resident.totalXp` on Identity/Nexus/profile |
| XP → world features | ⚠️ | Partial gates |
| Public profile achievements | ✅ | RLS + showcase widget |
| Hide/show achievements | ✅ | Proof sheet toggle + `is_profile_visible` |
| Badges & titles on profile | ⚠️ | Decorations + title yes; not full wall |
| Worlds: rules/governance | ✅ | Polls + council preview + settings |
| Worlds: economy | ⚠️ | Coin buy/tax/donate loop; more sinks needed |
| Achievement share deep link | ✅ | Profile `?achievement=` slug |
| Worlds: comms/news/knowledge | ⚠️ | Present unevenly |
| Worlds: grow with residents | ⚠️ | activityScore backend; weak UX |
| Tier-gated world creation | ✅ | |
| High-tier flair | ⚠️ | Nameplate/avatar; more needed |

**Legend:** ✅ Aligned · ⚠️ Partial · ❌ Missing

---

## 10. References

- Vision: [gamification-and-worlds.md](../vision/gamification-and-worlds.md)  
- Verifier ops: [VERIFIER_PORTAL.md](../VERIFIER_PORTAL.md)  
- Manual review UX: [Approvals.us — verification workflow](https://approvals.us/how-to-build-a-verification-workflow-with-manual-review-esca)  
- Badge credentials: [Open Badges 3.0](https://www.imsglobal.org/spec/ob/v3p0)  
- Achievement UX: [Google Play Games — achievement quality](https://developer.android.com/games/pgs/quality)  
- Economy design: [Sources, sinks, loops](https://dev.to/hiroshi_takamura_c851fe71/how-to-design-a-game-economy-sources-sinks-loops-and-balance-j05)  
- Prior audits: [2026-05-24-fix-tracker.md](./2026-05-24-fix-tracker.md), [product-gap-audit.md](./product-gap-audit.md)

---

## Codex Visual Review Needed

- **Screen:** Verifier portal → Achievements tab (pending proof card)  
- **Why:** Confirm image layout, tap-to-zoom need, and approve/reject affordances on device  
- **Reproduce:** Submit proof achievement on player build → open `vertiege://verifier/login` → Achievements tab  
- **Files:** `lib/screens/verification_review_screen.dart`, `lib/services/achievement_review_service.dart`
