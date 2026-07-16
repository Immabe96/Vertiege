# Gamification & Worlds — Product Vision

**Status:** North star (authoritative intent)  
**Updated:** 2026-05-27  
**Source:** Product owner vision — treat this as the goal for phases after core app stability.

---

## Tab mapping (product IA)

| Tab | Role |
|-----|------|
| **Nexus** | Share verified **achievement** moments (standing feed) |
| **Worlds** | Discover / join realms; world detail is channels-first |
| **Chat** | Celebrate wins in worlds; channels, DMs, Campfire |
| **You** | **Government ID** → verified **tick**. Honour wall, tier/XP. Achievement proof is a separate hub — not the same as identity. |

## Two proof types (do not conflate)

| Type | What | Where | Outcome |
|------|------|-------|---------|
| **Identity verification** | Passport or national ID card | You tab | Verified resident **tick** |
| **Achievement proof** | Evidence for a catalog achievement | Achievements hub | XP, honour wall entry, tier progress |

## Two pillars

### 1. Real-life standing (achievement proof)

Residents earn credibility from **real life**, not only app usage.

- Multiple **categories** of achievements (current catalog is a good base).
- Add a **life/misc** category over time: simple → epic, funny → dark, naughty → serious — a growing library so the app stays surprising and personal.
- Different achievements need **different proof**:
  - One or **multiple images**
  - Specific object, condition, or **location** when requirements demand it
- **Manual review only** (no AI verification):
  - User submits proof → reviewer sees images in the verifier queue
  - Approve or reject with an optional **message** (congratulations, guidance, rejection reason)
  - Users stay informed and motivated to complete (or resubmit) achievements

### 2. In-app activities (auto achievements)

Measurable behavior inside Vertiege (posts, streaks, joins, etc.) unlocks achievements **without** a proof queue — server/client triggers when criteria are met.

---

## XP → identity → worlds

**Achievements exist to earn XP.**

XP is not cosmetic alone — it feeds **resident tier / standing**, which unlocks app and world capabilities.

### Public profile (visit others)

Each resident has a **profile others can visit** showing:

- Verified achievements
- Badges and **titles** earned
- User control: **hide/show** individual achievements (some are dark, secret, or private)

### Worlds as “real-life mini worlds”

Worlds are where XP and standing **matter socially and economically**:

| Dimension | Intent |
|-----------|--------|
| Rules & governance | Sovereign + council; management modules for leaders |
| Jobs & roles | Standing, responsibilities, progression inside the realm |
| Economy | Buying, selling, treasury/marketplace over time |
| Communication | Channels, DMs, cooperation |
| News | Announcements / decrees |
| Knowledge | Lore, guides, archives |
| Social | Friends, alliances, individual vs collective standing |
| Growth | Worlds **grow as residents grow** — activity and prestige lift the realm |

**Access layers:**

- **Sovereigns / council** — management modules, governance tools
- **High-tier residents** — more features and flair (visible prestige)
- **Mature residents** — eventually **create their own world**

World info / detail UI should eventually express this dossier (deferred until gamification rules stabilize).

---

## Review & data principles

- Proof submissions: `submitted` → staff **approve/reject** + optional reviewer message stored for the user.
- In-app unlocks: idempotent, criteria-driven, no proof images.
- Catalog grows incrementally (new achievements in config + migrations as needed).
- Privacy: per-achievement visibility on public profile.

---

## Mapping to current codebase (snapshot)

**Full gap audit:** [docs/audits/2026-05-24-gamification-vision-gap-audit.md](../audits/2026-05-24-gamification-vision-gap-audit.md)

| Vision piece | Today |
|--------------|--------|
| Categories (education, career, … funny, in-app) | `AchievementCategory` in `lib/models/achievement.dart` |
| 100 achievements in config | `lib/config/achievements.dart` |
| Manual proof review | Verifier portal + `user_achievements`; AI path removed |
| In-app auto-unlocks | `autoAwardAchievement` (posts, streaks, worlds, …) — **local only until server sync** |
| XP → tier | **Split:** achievement sum vs `profiles.total_xp` — needs server sync on verify |
| Public profile | `ResidentProfileScreen` — badges/titles partial; full achievement grid + hide/show **not yet** |
| Multi-image / typed proof requirements | **Not yet** — single image path today |
| Worlds as full mini-society | About dossier (G4), capability gates (G3); governance voting **coming soon** |

---

## Suggested build order (when implementing)

1. **Achievement system core** — misc/life category, proof spec per achievement (single/multi image, notes), reviewer message UX end-to-end.
2. **Profile showcase** — public achievement grid, badges, titles, per-achievement visibility.
3. **XP loops** — daily/streak/quest/league server-backed; clear XP → tier feedback.
4. **World standing** — tie tier/prestige to world permissions, flair, and management access.
5. **World info rebuild** — single “about this realm” experience once rules are stable.
6. **World creation gate** — tier-gated custom/dominion worlds for mature residents.

Do not treat marketplace/treasury/polls as “done” until they participate in this standing loop.

---

## Progression glossary (user-facing)

Use these terms consistently in UI and support docs. In-app copy lives in
`lib/config/progression_glossary.dart`; help sheet: **How progression works**.

| Term | Scope | Meaning |
|------|--------|---------|
| **XP** | You (global) | Points from verified achievements and in-app milestones. Adds on your profile. |
| **Tier** | You (global) | Rank from total XP: Hustler → High Roller → Elite → Old Money → Apex. Gates worlds and creation. |
| **Rep** | You × one world | Reputation earned inside that world (posts, trade, participation). |
| **Standing** | You × one world | Label from rep (Member, Contributor, Council at 5,000 rep, etc.). |
| **World prestige** | The world | Realm maturity **1–50**. Unlocks lounge, marketplace, treasury, governance for everyone in that world. **Not** your tier. |
| **World growth level** | User-created worlds | **1–10** from activity score (posts, joins). Raises member cap. Premade worlds use prestige instead. |
| **Ascension** | You (optional) | After Apex + 50k XP: reset tier/XP for prestige stars (Hall of Ascension). |

### XP → tier thresholds

| Tier | XP required |
|------|-------------|
| Hustler | 0 |
| High Roller | 500 |
| Elite | 2,000 |
| Old Money | 10,000 |
| Apex | 50,000 |

### UI label rules

- Never label `world.prestige` as “Level” — use **Prestige N** or **Prestige N/50**.
- Use **Growth level N** only for dominion `activityScore` levels.
- World entry gates: **Requires {Tier} tier or higher** or **Requires {Profession} verification**.
- Identity: **Your tier & XP** (global) vs **World rep** (sum across worlds).

### World roles (jobs board)

- Council/sovereign post open roles with min **standing** and **tier**.
- Eligible members tap **Apply** (optional pitch message).
- Managers open **Applicants**, **Accept** one → role `filled`, other pending applications rejected.
- Backend: `world_job_applications`, RPCs `apply_to_world_job`, `accept_world_job_application`.

### Where users learn this

- Identity tab: section headers + `?` opens focused help.
- Nexus bento: tap tier/XP card for tier help.
- World detail: profile card + growth card + “How progression works” on Home tab.
