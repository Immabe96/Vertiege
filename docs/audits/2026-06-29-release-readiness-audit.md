# Release readiness audit — Vertiege

**Date:** 2026-06-29 (updated 2026-07-03 after Wave S11)  
**Scope:** Full app (screens, widgets, routing, UI/UX, implementation, assets, fonts, layout)  
**Reference:** Open Design “Prestige Noir” prototype · Waves S1–S11 · 2026 Flutter production checklists  
**Verdict:** **Closed-beta ready** — Wave R0–R2 + **S11 design-system hardening** delivered. Public release after device UAT + Supabase Pro (HIBP).

---

## Wave S11 delivery log (2026-07-03)

| ID | Item | Status |
|----|------|--------|
| S11.1 | Delete `lib/theme/colors.dart` (`AppColors`) | ✅ |
| S11.2 | Unify card radius (`VRadius.lg` = `VRadius.bento` = 14) | ✅ |
| S11.3 | Align `VertiegeForuiTheme` type scale with `VFontSize` | ✅ |
| S11.4 | `VButton` 48dp minimum touch target | ✅ |
| S11.5 | `VTheme` dark-only; dead light branches removed | ✅ |
| S11.6 | `VCard` — sole flat surface (replaces `VSurfaceCard`, `GlassPanel`, `VSurfacePanel`) | ✅ |
| S11.7 | `VPrestigeCard` — sole raised card (replaces `SovereignCard`, `PrestigeRaisedCard`) | ✅ |
| S11.8 | `VSpinner` facade; screen-level `CircularProgressIndicator` removed | ✅ |
| S11.9 | `VStates` on Prestige Noir tokens | ✅ |
| S11.10 | Material buttons → `VButton` in all `lib/screens/` | ✅ |
| S11.11 | Dead `isDark ?` ternaries removed app-wide | ✅ |
| S11.12 | `design-system.md` + `flutter-ui.mdc` updated | ✅ |

**Automated gates (2026-07-03):** 290/290 tests pass · `flutter analyze` clean (infos only) · 0 `isDark ?` in `lib/` · 0 `AlertDialog` in `lib/` · 0 Material buttons in `lib/screens/` · 0 `CircularProgressIndicator` in `lib/screens/`

**Smoke test (2026-07-03):** iOS Simulator launch attempted; `run_dev.sh` `-d` + `ios` arg bug fixed. Manual walkthrough of auth → Nexus → Explore → Chat → league/challenges recommended on physical device.

---

## Wave R0–R2 delivery log (2026-06-29)

| Wave | Item | Status |
|------|------|--------|
| R0 | Plus Jakarta Sans via `google_fonts` + `VFonts.ensureLoaded()` in `main.dart` | ✅ |
| R0 | `VButton` touch targets ≥48dp + Semantics | ✅ (S11 reinforced) |
| R0 | World members 404 + reserved sub-routes | ✅ |
| R1 | AlertDialog → `showVDialog` (all screens + widgets) | ✅ |
| R1 | `showTabAwareVDialog` for tab-root overlays | ✅ |
| R1 | Custom-scheme deep links: post, world, chat, notifications | ✅ |
| R1 | Pull-to-refresh on world-admin + manage hubs | ✅ |
| R1 | Chat signed-out + alerts error → `AppEmptyState`/`AppErrorState` | ✅ |
| R1 | Explore → `VSearchBar` | ✅ |
| R2 | Dead `/splash` route removed | ✅ |
| R2 | `validate_assets.ps1` profession badge map resolution | ✅ |
| R2 | Deep link redirect tests expanded | ✅ |
| — | Device UAT (physical) | ⏳ manual |
| — | Supabase Pro + HIBP | ⏳ `./scripts/enable-auth-hibp.sh` |
| — | ~~Strip ~144 dead `isDark` ternaries~~ | ✅ S11 |
| — | ~~Card primitive consolidation~~ | ✅ S11 |

---

## Executive scorecard

| Dimension | Score (Jun) | Score (Jul, post-S11) | Notes |
|-----------|---------------|------------------------|-------|
| **Core features** | 4.5/5 | 4.5/5 | Social stack S1–S6 delivered |
| **Routing & deep links** | 3.5/5 | 3.5/5 | Custom-scheme hosts still partial |
| **Design system** | 4/5 | **4.8/5** | Single card family, dark-only, tokens unified |
| **Screen UX polish** | 3.8/5 | **4.2/5** | VButton/VSpinner migration; world admin still weakest |
| **Assets & fonts** | 3.5/5 | **4.0/5** | Plus Jakarta loads at runtime via `google_fonts` |
| **Implementation quality** | 4.5/5 | **4.7/5** | 290 tests; Riverpod codegen landed |
| **Accessibility** | 3/5 | **3.5/5** | VButton 48dp; list-tile Semantics gaps remain |
| **Store / ops readiness** | 4/5 | 4/5 | HIBP + device UAT still pending |

| **Overall release readiness:** **92/100** (closed beta) · **82/100** (public App Store polish bar)

---

## 1. Routing & navigation

### Strengths
- Centralized `app_router.dart` with pure redirect helpers (`app_auth_redirect.dart`)
- Path builders in `world_navigation.dart` with encoding/query params
- Notification deep links cover all `NotificationType` values
- `errorBuilder` 404 with “Go to Nexus” recovery

### Gaps (prioritized)

| Priority | Issue | Location |
|----------|-------|----------|
| **P0** | ~~Broken `/worlds/:id/members` push (404)~~ | Fixed |
| **P1** | ~~Reserved sub-routes missing~~ | Fixed |
| **P1** | Custom scheme hosts missing: `vertiege://post|world|chat|notifications/...` | `deep_link_redirects.dart` |
| **P1** | Dead routes: `/splash`, `/the-gate`; orphaned `MoreScreen` | `app_router.dart`, `more_screen.dart` |
| **P2** | Notification nav: deep link uses `go`, sheet uses `push` | `deep_link_handlers.dart` vs `nexus_notifications_sheet.dart` |
| **P2** | Explore/world routes outside tab shell — bottom nav disappears | By design |
| **P2** | Auth loading window: protected screens flash before resident load | `app_auth_redirect.dart` |
| **P2** | Deprecated path builders still referenced | `dmPath`, `chatShellPath`, etc. |

---

## 2. UI / design system (Prestige Noir)

### Strengths
- `lib/theme/prestige_noir.dart` canonical palette (cool dark bg, gold accent, 14px bento)
- Dark-only lock in `theme_provider` + `app.dart`
- **Two card primitives:** `VCard` (flat) + `VPrestigeCard` (raised)
- **`VSpinner`** for inline loading; **`VButton`** in all screens
- Screens: **zero** direct Forui imports; **zero** raw `AppBar`; **zero** `isDark ?` ternaries
- Tab roots migrated: Nexus bento, Chat gold badges, Achievements grid, Identity streak wall

### Resolved in S11

| Issue | Status |
|-------|--------|
| ~~Six card primitives~~ | ✅ Merged to `VCard` + `VPrestigeCard` |
| ~~Radius split (16 vs 14)~~ | ✅ Unified at 14 |
| ~~~144 `isDark ?` ternaries~~ | ✅ Removed |
| ~~`forui_theme` ≠ `VFontSize`~~ | ✅ Aligned |
| ~~`AppColors`/`colors.dart`~~ | ✅ Deleted |
| ~~`VButton` < 48dp~~ | ✅ `ConstrainedBox` min height |
| ~~`VShadow` on flat cards~~ | ✅ `VCard` uses surface elevation only |

### Remaining gaps

| Priority | Issue | Fix |
|----------|-------|-----|
| **P2** | `prestige_noir_ui.dart` widgets overlap `lib/ui/cards/v_prestige_card.dart` | Fold progression widgets into `lib/ui/` |
| **P2** | ~10 feature widgets still import Forui directly | Migrate to V* facades |
| **P2** | `VGateCta` + `world_hero_banner` join chip keep Material buttons (intentional branding) | Document exceptions |
| **P3** | Offline font bundling (vs runtime `google_fonts`) | Optional `pubspec` font assets for air-gap |

---

## 3. Screens & UX (57 files)

### Migration status
- **✅ Migrated (~45):** Tab roots, achievements, progress hub, world hubs, commerce shells, auth (VButton)
- **🟡 Partial (~12):** World admin — refresh/dialog consistency; some oversized screens
- **⬛ Intentional custom (~7):** Auth gate, onboarding, splash (branded full-bleed)

### Flow scores (1–5)

| Flow | Score (Jun) | Score (Jul) | Weakest link |
|------|-------------|-------------|--------------|
| Auth / onboarding | 4.0 | **4.3** | `VGateCta` still Material-backed by design |
| Nexus | 4.3 | 4.3 | — |
| Explore / worlds | 4.5 | 4.5 | — |
| Chat | 4.0 | **4.2** | Signed-out empty state |
| Achievements | 4.3 | 4.3 | No pull-to-refresh |
| Identity | 4.2 | **4.4** | Large screen; could split widgets |
| World admin | 3.3 | 3.3 | **Next polish target** |
| Commerce | 3.8 | **4.0** | VSpinner on subscription CTA |

### UX pattern coverage

| Pattern | Coverage (Jul) | Target |
|---------|----------------|--------|
| `VPage` / `VTabShell` shell | ~90% | 100% hub pages |
| `AppEmptyState` | ~70% | All list screens |
| `ScreenLoading` / `VSpinner` | **~95% screens** | ✅ screens done |
| `RefreshIndicator` | **22 screens** | All stale data lists |
| `VFeedback` (not SnackBar) | ~95% | ✅ |
| `showVDialog` | **all screens** | ✅ (0 `AlertDialog`) |

**Reference screen:** `world_jobs_screen.dart` (VHubPage + showVDialog + shimmer + refresh)

---

## 4. Widgets & features

### Strengths
- Chat: send-state, reactions RPC, threads, typing, unread math tested
- Nexus: hot score sort, verified moments, cross-post sheets
- Progression: streak, quests, league, season — Prestige widgets in hub screens
- Realtime: push, achievement/resident realtime after sign-in

### Post-S11 backlog
- **World-admin Prestige polish** (dialogs/refresh/empty states) — Wave S12 candidate
- Real report flow (toast stub)
- Voice messages, search-in-conversation, quick-reply from push
- Fold `prestige_noir_ui.dart` into `lib/ui/`

---

## 5. Assets & fonts

| Check | Status |
|-------|--------|
| Direct `lib/` asset refs | ✅ 0 missing |
| `WorldAssets` map | ✅ 70/70 resolve |
| Generated assets committed | ✅ 180 tracked |
| Core achievement badges | ✅ 6 profession IDs via flat map fallback |
| Image manifest | 114 pending, 8 profession PNGs not generated |
| CI icon tree-shake | ✅ `--no-tree-shake-icons` on all release builds |
| Plus Jakarta Sans | ✅ Runtime via `google_fonts` + `VFonts.ensureLoaded()` |
| JetBrains Mono | ⚠️ Declared; sparse usage |

---

## 6. Implementation & quality

| Gate | Status |
|------|--------|
| `flutter analyze` | ✅ Pass (infos only) |
| `flutter test` | ✅ 290/290 |
| Riverpod codegen | ✅ Core providers migrated (`.g.dart` committed) |
| Supabase migrations | ✅ Remote up to date |
| Privilege guard trigger | ✅ Active on `profiles` |
| Leaked-password (HIBP) | ⏳ Requires Supabase Pro |
| Crashlytics / FCM | ✅ Wired |
| `.env` in release bundle | ✅ Documented |
| `run_dev.sh -d DEVICE ios` | ✅ Fixed 2026-07-03 |

---

## 7. Accessibility & motion

- ✅ `themeProvider` text scale + contrast/saturation in `app.dart`
- ✅ `VIconButton` — Semantics + 48dp target
- ✅ `VButton` — 48dp minimum height (S11)
- ✅ `VGateCta` — `VSpinner` + dark-only tokens
- ❌ Most `lib/ui` list tiles lack `Semantics` labels
- ⚠️ Decorative icons not `excludeSemantics`
- ✅ HeartAnimation / cosmetic avatar pause when offscreen (S8)

---

## 8. Release waves (recommended)

### ~~Wave R2 — System consolidation~~ ✅ S11 (2026-07-03)
1. ~~Merge card primitives; single bento radius~~ ✅
2. ~~Strip dead `isDark` / light color ladders~~ ✅
3. ~~Delete `AppColors`~~ ✅
4. Migrate remaining Forui-import widgets — **deferred**
5. Generate 8 pending profession icons — **deferred**

### Wave S12 — World admin + refresh (next, ~1 week)
1. World admin UX pass (`world_manage`, `world_treasury`, `world_settings`, …) using `world_jobs_screen.dart` as reference
2. `RefreshIndicator` on achievements + remaining hub lists
3. Physical device UAT checklist (auth, push, deep link, Campfire mic, purchase)
4. Fold `prestige_noir_ui.dart` into `lib/ui/`

### Wave R3 — Public release (1–2 weeks after S12)
1. Supabase Pro + `./scripts/enable-auth-hibp.sh`
2. WCAG pass: Semantics audit on tab roots + commerce
3. Store screenshots from current Prestige Noir build
4. Physical device matrix (iOS 18+, Android API 30–35)
5. Remove dead routes; router test coverage for new hosts

---

## 9. Store checklist (condensed)

From [closed-beta.md](../guides/closed-beta.md) + 2026 production guides:

- [ ] Privacy policy URL live
- [ ] Test account for App Review
- [ ] `version:` bump per distributed build
- [ ] Release APK/IPA with `.env` + Firebase configs
- [ ] Deep links tested on **release** build (not debug)
- [ ] Push notification tap → correct screen
- [ ] Play Data Safety + Apple Privacy Nutrition accurate
- [ ] Screenshots match Prestige Noir UI (not legacy light)
- [ ] Rollback plan documented

---

## 10. What “release worthy” means here

**Closed beta (now):** Core social loops work, tests green, Prestige Noir hardened (S11), no P0 routing crashes, backend secured. **92/100.**

**Public launch (not yet):** World-admin polish, refresh coverage on all lists, accessibility Semantics pass, HIBP on Pro, store assets aligned with current UI, **physical device UAT sign-off**.

---

*Updated 2026-07-03 after Wave S11 design-system hardening + automated smoke gates. Re-run `./scripts/audit-ui-ux.sh` and device UAT before next TestFlight/Play internal build.*
