# Screen rebuild plan — World, Identity, Achievements

**Date:** 2026-05-22  
**Status:** Phases A–D implemented on `develop` (Waves 1–4 + screen depth pass; device UAT in `docs/uat/WAVE-4-DEVICE-CHECKLIST.md`)  
**Reference UI:** `VHubPage` + `VSectionList` (More, Settings, Discover)

---

## What we fixed in this batch (install & verify first)

| Area | Change |
|------|--------|
| **Navigation** | `GoRouter` no longer rebuilds on every XP/profile update |
| **DM from profile** | `/dm/:roomId` top-level route (no white screen) |
| **League XP** | Standings scoped to **active season**; league loads on app start |
| **World detail scroll** | `NestedScrollView` — hero + stats + tabs scroll together |
| **Channel unread** | Own messages excluded; mark read after send |
| **DM realtime** | Subscribe all rooms when DM list loads |
| **DM alerts** | In-app notification row for recipient (DB `notifications`) |
| **Daily quests** | `/daily-quests` (not `/challenges`) |

---

## Problem summary (from UAT)

### World info (`WorldDetailScreen`)

- Banner + 4 stat cards felt **pinned** while only tab body scrolled.
- Visual language mixed **legacy glass** + new tokens; “readable but ugly.”
- **More** tab cluttered; chat preview duplicated channel entry.

### Identity tab

- Layout unlike **More / Settings** hub pattern.
- Refresh was confusing (fixed: stays on Identity).
- Many actions buried in long scroll; tier/XP/subscription not scannable.

### Achievements

- Index uses **legacy Scaffold + AppBar**, not Forui hub.
- Categories feel disconnected from **verifier proof** flow.
- User expectation: “major UX overhaul,” not small patches.

---

## Proposed phases

### Phase A — Shell parity (1–2 days)

**Goal:** All three screens use the same hub chrome as More/Settings.

| Screen | Deliverable |
|--------|-------------|
| Identity | `VHubPage` + sections: Profile, Progress, Worlds, Social, Account |
| Achievements | `VHubPage` + hero stats + category `FTile` grid |
| World detail | Keep immersive hero; stats as `FCard` row; tabs as `FHeader` segments |

**Exit criteria:** No raw `AppBar` on these flows; back navigation consistent.

### Phase B — World info UX (2–3 days)

**Goal:** One coherent “world home” that sells the world and routes to actions.

**Information architecture:**

```
[Hero: banner, name, tier, join/leave]
[Stats: members · posts · events · prestige]
[Primary actions: Feed | Channels | People | Manage]
[Optional: General chat preview — single CTA, not full composer]
[Tab content]
```

**Ideas:**

- **Sticky mini-header** after scroll (world name + join state only).
- **Sovereign row** under title (avatar + “Founded by …”).
- **Channel shortcuts** on Feed tab (General, Announcements) before posts.
- **Empty states** per tab with one clear CTA (join, post, invite).
- Move treasury/marketplace/polls behind **Manage** sub-sheet for members+.

### Phase C — Identity hub (2 days)

**Goal:** “My resident card” — status, progress, shortcuts.

**Sections (top → bottom):**

1. **Profile card** — avatar, nameplate, tier, edit, share profile  
2. **Today** — streak, daily quests link, league snippet  
3. **Progress** — XP bar, next tier, subscription badge  
4. **My worlds** — joined worlds (chips → world detail)  
5. **Social** — allies, following count → search  
6. **Vault** — trophies, cosmetics preview  
7. **Account** — settings, notifications, sign out  

**Ideas:**

- Pull-to-refresh reloads resident + posts + quests (no navigation).
- **Completion meter** (profile fields) like LinkedIn strength.
- Tap tier opens Ascension Path, not buried in More.

### Phase D — Achievements overhaul (3–4 days)

**Goal:** Browse → understand → submit proof → track verification.

**Flows:**

```
Index (categories + tier progress)
  → Category grid (locked / in-progress / verified)
    → Achievement detail (criteria, proof, status)
      → Submit (camera / gallery / manual)
```

**Ideas:**

- **Proof-first cards** — thumbnail or “manual review” badge on tile.
- **Verifier status chip** — pending / verified / rejected with reason.
- **Category progress** — “12/40 verified” per category.
- **Funny / Creative** categories visually distinct (tertiary accent).
- Profession achievements link to **verification portal** copy for staff.
- Share verified achievement as image card (existing share infra).

### Phase E — Push & polish (1 day, backend-dependent)

- FCM payload: `room_id`, `route: /dm/{id}` for DM opens.
- World channel mention notifications.
- League weekly reset banner on Monday.

---

## Design ideas (cross-cutting)

| Idea | Where | Why |
|------|--------|-----|
| **Hub sections** | Identity, Achievements index | Matches More tab mental model |
| **Immersive + hub hybrid** | World detail | Hero stays cinematic; controls feel modern |
| **Bento on Nexus only** | Not on world page | Reduces visual noise in world context |
| **Skeleton loaders** | All three | UAT called out “empty” vs “loading” confusion |
| **Error banners** | World join, achievement submit | Retry without kicking to Nexus |
| **Deep links** | `/dm/`, `/explore/:id`, `/achievements/:cat` | Notifications and share |

---

## Decisions (2026-05-22) — complete

| Topic | Choice |
|-------|--------|
| World hero | **Collapsible** — expand on pull-down |
| Rebuild order | **Parallel** — shell parity on all three, then depth per screen |
| Identity focus | **Wall of Honour** — rank, tiers, badges, worlds, achievements, perks |
| World Manage tab | **Split** — economy (treasury, marketplace, polls) in **Manage**; social extras on world **More** tab |
| Achievement proof | **In-app photo / gallery upload** |
| Visual reference | **Reddit** — community header + tabs |

---

## Questions (answered — archive)

---

## Out of scope (unless you say otherwise)

- Full verifier portal redesign (separate staff app surface).
- Nexus bento redesign (already iterated).
- New achievement definitions / DB taxonomy (UX only unless requested).

---

## Testing strategy

| When | What you do |
|------|-------------|
| **Now (optional)** | Smoke-test current `develop` APK only if you want — navigation/DM/league fixes from the pre-rebuild batch. Not required for sign-off. |
| **After Phase A–D** | **One manual device pass** on all three rebuilt screens (World, Identity, Achievements) using [DEVICE_UAT.md](../DEVICE_UAT.md) or the checklist below. |

We do **not** ask for full manual UAT after every small fix or after shell-only work — only after the **3-screen rebuild** is complete.

---

## Manual UAT checklist (after 3-screen rebuild)

### World info
- [ ] Collapsible hero expands on pull; scroll feels like one page (Reddit-style header + tabs)
- [ ] Feed / Channels / People / Manage (+ More for social) match split IA
- [ ] Join/leave, channels, members, settings still work

### Identity (Wall of Honour)
- [ ] Rank, tier, badges, worlds, achievements, perks visible without hunting
- [ ] Refresh stays on Identity; edit profile / share work
- [ ] Shortcuts (league, quests, settings) still reachable

### Achievements
- [ ] Category grid readable; proof upload (photo/gallery) works
- [ ] Pending / verified / rejected states clear
- [ ] Submit → back to category; verifier path unchanged for staff

### Regression (quick)
- [ ] Send DM / channel message — no kick to Nexus
- [ ] Search → Message — no white screen
- [ ] Nexus feed, chat, explore still usable

Report: device model, APK commit SHA, pass/fail per section.
