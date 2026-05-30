# UAT issue log — live session

**Tester:** Ahmed  
**Date:** 2026-05-30  
**Build:** release APK, `develop` @ `acb0613`  
**Device:** emulator-5554 (Android 16 / API 36)  
**Mode:** one screen at a time — emulator left on repro screen

---

## Issues

| # | Screen / route | What you see (expected vs actual) | Severity | Status |
|---|----------------|-----------------------------------|----------|--------|
| 1 | **Identity → Wall of Honour** → Trophy Case → *Achievement wall* | **Expected:** unique generated badge PNGs for verified achievements. **Actual:** Material category icons (school, work, etc.) in circles. | major | fixed |
| 2 | **World detail** → **Channels** / **Members** → *Residents* | **Expected:** lists only as tall as content. **Actual:** large grey scrollable void / grey panel under Residents. | major | **fixed** (verified on device) |
| 3 | **Voice / Campfire** (world + Chat tab) | **Expected:** discoverable Lounge/Campfire; voice routes to Campfire; gate reasons when locked. | major | **fixed (code)** — device verify pending |

**Severity:** `blocker` · `major` · `minor` · `polish`

**Status:** `open` · `confirmed` · `fixed` · `wontfix`

---

## Session notes

### #1 — fixed

- **Cause:** `assets/generated/achievements/` not listed in `pubspec.yaml` (Flutter does not bundle asset subfolders unless each is declared).
- **Symptom:** `AchievementBadgeAvatar` fell back to Material category icons.
- **Fix:** `pubspec.yaml` → `- assets/generated/achievements/`. Rebuild required.
- **Verify:** Wall of Honour shows PNG badges (tester confirmed).

### #2 — fixed (do not repeat)

**Same family as Identity `ExpansionTile` grey box (commit `2326bf3`):** UI reserves a large empty **surface-colored** region below real content. Fix pattern: **`Column(mainAxisSize: MainAxisSize.min)`**, no `ExpansionTile` / no full-height placeholder widgets, no `VLoadingCard` for inline lists.

#### Symptoms (world detail)

| Tab / area | What looked wrong |
|------------|-------------------|
| Channels | Grey band below channel list; could scroll “forever” through empty space |
| Members → Residents | Large grey panel, then list — felt like a second broken block |

#### Root causes (three layers — all had to be fixed)

1. **`TabBarView` + per-tab `CustomScrollView`** (`world_detail_screen.dart`)  
   Each tab got full viewport height; short content left a scrollable void.  
   **Fix:** One inner `CustomScrollView`; tab content swapped with `AnimatedBuilder` + `Column(mainAxisSize: min)`. No `TabBarView` in `NestedScrollView` body (tab bar in header still works; horizontal swipe between tabs removed).

2. **`ListTile` on short lists** (`world_channel_list.dart`)  
   Material tile chrome + height quirks in nested scroll.  
   **Fix:** Compact `InkWell` + `Row` / `Column(min)` rows (match Channels pattern everywhere).

3. **`WorldResidents` duplicate fetch + `VLoadingCard`** (`world_residents.dart`) — **Residents-only**  
   Screen already loaded members in `WorldDetailScreen`, but `WorldResidents` fetched again and showed a full **`VLoadingCard`** (`VSurfacePanel` grey block) while loading.  
   **Fix:** Pass `members` + `isLoading` from `WorldDetailMembers`; inline `Pulse` shimmers only; no second `WorldService.getMembers` call.

#### Files touched (reference)

- `lib/screens/world_detail_screen.dart` — single tab body scroll
- `lib/widgets/worlds/world_channel_list.dart` — InkWell rows
- `lib/widgets/worlds/world_residents.dart` — parent data, no VLoadingCard
- `lib/widgets/worlds/world_detail_members.dart` — pass members through
- `lib/widgets/worlds/leaderboard.dart` — compact loading, `Column(min)`

#### Prevention checklist (new world tab / list UI)

- [ ] Do **not** put a separate `CustomScrollView` per `TabBarView` child under `NestedScrollView`.
- [ ] Wrap tab section content in `Column(mainAxisSize: MainAxisSize.min)`.
- [ ] Prefer **InkWell rows** over `ListTile` for dense lists inside scrollables.
- [ ] Do **not** use `VLoadingCard` inside an already-loaded screen section — pass data from parent or use small `Pulse` rows.
- [ ] Do **not** re-fetch the same list in a child widget if the parent already has it.
- [ ] Avoid `ExpansionTile` for collapsible sections (use `InkWell` + `if (expanded)` like Identity tier perks).

**Verified:** tester confirmed Channels + Members / Residents look correct after final build.

### #3 — Wave 7 (verify on device)

- **Done in code:** `lounge` + `campfire` in `createDefaultChannels`; migration `20260530150000_lounge_campfire_channels.sql` for existing worlds; `WorldChannelAccessService` gate copy; `worldChannelDestinationPath` everywhere lists open channels; World tools → Lounge / Campfire; LiveKit token validates prestige 25 + Veteran rep.
- **Verify:** prestige ≥10 world + Veteran rep → Lounge text opens; prestige ≥25 → Campfire connects; locked resident sees reason; Chat tab voice row opens Campfire; mini-bar after join.
- **Legacy worlds:** run migration or re-seed channels if lounge/campfire missing.
