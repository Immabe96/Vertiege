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
| 1 | **Identity → Wall of Honour** → Trophy Case → *Achievement wall* | **Expected:** unique generated badge PNGs for verified achievements. **Actual:** Material category icons (school, work, etc.) in circles. | major | open |
| 2 | **World detail** → Feed (channel shortcuts) / **Channels** / **Members** | **Expected:** channel list, feed extras, member panels. **Actual:** large grey box (empty viewport fill / broken nested scroll). | major | open |
| 3 | **Voice / Campfire** (world + Chat tab) | **Expected:** discoverable voice channel or “Campfire” entry; join voice room. **Actual:** no voice channels in default world setup; no Campfire label in world IA; mini-bar only after join. | major | open |

**Severity:** `blocker` · `major` · `minor` · `polish`

**Status:** `open` · `confirmed` · `fixed` · `wontfix`

---

## Session notes

### #1 — likely root cause (dev)

- ~104 files exist at `assets/generated/achievements/<id>.png` and `WorldAssets.coreAchievementBadgeImage()` points there for catalog ids.
- Release APK built @ `acb0613` contains **0** files under `assets/generated/achievements/` — Flutter only bundled top-level `assets/generated/*` because `pubspec.yaml` did not list the subfolder (see [Flutter assets docs](https://docs.flutter.dev/ui/assets/assets-and-images)).
- UI falls back to `achievementIconData` / category Material icons when `Image.asset` fails (`AchievementBadgeAvatar` errorBuilder).
- **Fix staged:** add `- assets/generated/achievements/` to `pubspec.yaml` — needs rebuild + reinstall to verify on emu.

### #2 — likely root cause (dev)

- Tab bodies use `_WorldDetailTabScroll` → `CustomScrollView` + `SliverToBoxAdapter` wrapping tab content.
- **Feed:** `WorldFeedTab(primaryScroll: true)` returns a nested `ListView` inside that sliver → invalid layout / grey scroll extent.
- **Channels / Members:** short `Column` content leaves unfilled `TabBarView` viewport (default Material grey below content).
- **Fix in progress:** feed → `Column` for outer scroll; tab wrapper → `SliverFillRemaining` + scaffold background color.

### #3 — product / wiring gap (not UAT tester error)

- **Built:** `CampfireScreen`, `/campfire/:channelId`, `voice_provider`, LiveKit `voice_service`, tab mini-bar when connected (`tab_layout.dart`).
- **Not in default worlds:** `createDefaultChannels` / DB seed only `info`, `rules`, `roles`, `general` (text/announcement). No `ChannelType.voice` channel created.
- **`#lounge` ≠ voice:** create-world “lounge” is a **text** channel name; hidden until world `features.lounge` (prestige ≥ 10), not Campfire.
- **`audioRooms` flag:** exists on `WorldFeatures` (prestige ≥ 25) but **no UI** reads it to add or show voice channels.
- **Routing:** `WorldChannelList` / Chat channel tiles always `worldChannelPath` → text channel screen, even for `ChannelType.voice` (campfire route unused from lists).
- **Smoke checklist** line “Campfire: Back leaves voice room” is **not testable** on stock worlds without manual voice channel + deep link.
