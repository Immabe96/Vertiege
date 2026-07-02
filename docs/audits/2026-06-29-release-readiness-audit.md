# Release readiness audit — Vertiege

**Date:** 2026-06-29 · **Scope:** Full app (screens, widgets, routing, UI/UX, implementation, assets, fonts, layout)  
**Reference:** Open Design “Prestige Noir” prototype · Waves S1–S10 · 2026 Flutter production checklists  
**Verdict:** **Closed-beta ready** — Wave R0–R2 delivered 2026-06-29. Public release after device UAT + Supabase Pro (HIBP).

---

## Wave R0–R2 delivery log (2026-06-29)

| Wave | Item | Status |
|------|------|--------|
| R0 | Plus Jakarta Sans via `google_fonts` + `VFonts.ensureLoaded()` in `main.dart` | ✅ |
| R0 | `VButton` glass touch targets ≥48dp + Semantics | ✅ |
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
| — | Strip ~144 dead `isDark` ternaries | 📋 deferred (cosmetic) |
| — | Card primitive consolidation | 📋 deferred |

**Tests:** 290/290 pass · **Analyze:** clean (infos only)

---

## Executive scorecard

| Dimension | Score | Notes |
|-----------|-------|-------|
| **Core features** | 4.5/5 | Social stack S1–S6 delivered; chat, nexus, achievements, worlds functional |
| **Routing & deep links** | 3.5/5 | One P0 404 fixed; custom-scheme hosts incomplete; dead routes remain |
| **Design system** | 4/5 | Prestige Noir dark-only landed; fonts + card duplication + legacy ternaries |
| **Screen UX polish** | 3.8/5 | VPage/VTabShell ~90%; AlertDialog sprawl; uneven refresh/loading |
| **Assets & fonts** | 3.5/5 | No broken refs; Plus Jakarta not shipping; manifest backlog |
| **Implementation quality** | 4.5/5 | 280 tests pass; analyze clean; Riverpod codegen in flight |
| **Accessibility** | 3/5 | Text scale wired; touch targets + Semantics gaps in VButton/list tiles |
| **Store / ops readiness** | 4/5 | Closed-beta guide exists; HIBP needs Pro; device UAT pending |

| **Overall release readiness:** **88/100** (closed beta) · **78/100** (public App Store polish bar)

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
| **P0** | ~~Broken `/worlds/:id/members` push (404)~~ | Fixed: `world_welcome_flow.dart` → `worldMembersPath` |
| **P1** | ~~Reserved sub-routes missing `academy/sanctuary/manage/governance`~~ | Fixed: `world_route_redirects.dart` |
| **P1** | Custom scheme hosts missing: `vertiege://post|world|chat|notifications/...` | `deep_link_redirects.dart` |
| **P1** | Dead routes: `/splash`, `/the-gate`; orphaned `MoreScreen` | `app_router.dart`, `more_screen.dart` |
| **P2** | Notification nav: deep link uses `go`, sheet uses `push` (inconsistent back stack) | `deep_link_handlers.dart` vs `nexus_notifications_sheet.dart` |
| **P2** | Explore/world routes outside tab shell — bottom nav disappears | By design; document or add world shell |
| **P2** | Auth loading window: protected screens flash before resident load | `app_auth_redirect.dart` |
| **P2** | Deprecated path builders still referenced | `dmPath`, `chatShellPath`, etc. |

---

## 2. UI / design system (Prestige Noir)

### Strengths
- `lib/theme/prestige_noir.dart` canonical palette (cool dark bg, gold accent, 14px bento)
- Dark-only lock in `theme_provider` + `app.dart`
- Screens: **zero** direct Forui imports; **zero** raw `AppBar` in widgets
- Tab roots migrated: Nexus bento, Chat gold badges, Achievements grid, Identity streak wall

### Gaps

| Priority | Issue | Fix |
|----------|-------|-----|
| **P0** | **Plus Jakarta Sans not shipping** — `VFont.sans` declared, `VFonts.sansFamily = 'sans-serif'` | Bundle fonts in `pubspec.yaml` or rename tokens |
| **P0** | `VButton` small/medium heights 36/44dp (< 48 WCAG) | `v_button.dart` |
| **P1** | Six card primitives (`VCard`, `VSurfaceCard`, `VPrestigeCard`, `PrestigeRaisedCard`, `SovereignCard`, `VSurfacePanel`) | Merge to 2–3 |
| **P1** | Card radius split: `VRadius.lg` (16) vs `bento` (14) | Pick one |
| **P1** | ~144 `isDark ?` ternaries in dead light branches | Strip; use `colorScheme` |
| **P1** | `forui_theme.dart` type scale ≠ `VFontSize` | Unify |
| **P2** | `AppColors`/`colors.dart` legacy layer (~198 lines) | Delete or deprecate |
| **P2** | 6 feature widgets still import Forui directly | Migrate to V* facades |
| **P2** | `VShadow` on cards vs “no shadow” Prestige rule | Remove from `VCard` |

---

## 3. Screens & UX (57 files)

### Migration status
- **✅ Migrated (~30):** Tab roots, achievements, progress hub, most world hubs, commerce shells
- **🟡 Partial (~20):** World admin (AlertDialog), identity, verification, subscription spinners
- **⬛ Intentional custom (~7):** Auth, onboarding, splash (branded full-bleed)

### Flow scores (1–5)

| Flow | Score | Weakest link |
|------|-------|--------------|
| Auth / onboarding | 4.0 | Inline spinners, no branded loader on callback |
| Nexus | 4.3 | — |
| Explore / worlds | 4.5 | Raw `TextField` in explore search |
| Chat | 4.0 | Signed-out `Center(Text)`, `isDark` ternaries |
| Achievements | 4.3 | No pull-to-refresh |
| Identity | 4.2 | Raw `AlertDialog` |
| World admin | 3.3 | **31 dialog calls across 10 screens** |
| Commerce | 3.8 | Mixed dialogs + spinners |

### UX pattern coverage

| Pattern | Coverage | Target |
|---------|----------|--------|
| `VPage` / `VTabShell` shell | ~90% | 100% hub pages |
| `AppEmptyState` | ~70% | All list screens |
| `ScreenLoading` shimmer | ~60% | Replace 5× `CircularProgressIndicator` |
| `RefreshIndicator` | 18/57 screens | All stale data lists |
| `VFeedback` (not SnackBar) | ~95% screens | 6 SnackBar refs (fallback only) |
| `showVDialog` | 4 screens | Migrate 10 screens off `AlertDialog` |

**Reference screen:** `world_jobs_screen.dart` (VHubPage + showVDialog + shimmer + refresh)

---

## 4. Widgets & features

### Strengths
- Chat: send-state, reactions RPC, threads, typing, unread math tested
- Nexus: hot score sort, verified moments, cross-post sheets
- Progression: streak, quests, league, season — Prestige widgets in hub screens
- Realtime: push, achievement/resident realtime after sign-in

### Post-S10 backlog (from PLAN.md)
- Real report flow (toast stub)
- World-admin Prestige polish (dialogs/refresh)
- Voice messages, search-in-conversation, quick-reply from push
- Consolidate `prestige_noir_ui.dart` ↔ `v_prestige_card.dart`

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
| Plus Jakarta / JetBrains Mono | ❌ Not bundled |
| `google_fonts` dependency | ⚠️ Unused dead dep |

---

## 6. Implementation & quality

| Gate | Status |
|------|--------|
| `flutter analyze` | ✅ Pass (infos only) |
| `flutter test` | ✅ 280/280 |
| Riverpod codegen | ✅ Core providers migrated |
| Supabase migrations | ✅ Remote up to date |
| Privilege guard trigger | ✅ Active on `profiles` |
| Leaked-password (HIBP) | ⏳ Requires Supabase Pro |
| Crashlytics / FCM | ✅ Wired |
| `.env` in release bundle | ✅ Documented |

---

## 7. Accessibility & motion

- ✅ `themeProvider` text scale + contrast/saturation in `app.dart`
- ✅ `VIconButton` — Semantics + 48dp target
- ❌ `VButton._GlassButton` — no Semantics, sub-48dp sizes
- ❌ Most `lib/ui` facades lack `Semantics` labels
- ⚠️ Decorative icons not `excludeSemantics`
- ✅ HeartAnimation / cosmetic avatar pause when offscreen (S8)

---

## 8. Release waves (recommended)

### Wave R0 — Ship blockers (1–2 days)
1. ~~Fix world members 404~~ ✅
2. ~~Expand reserved world sub-routes~~ ✅
3. Bundle Plus Jakarta Sans (or document intentional system font)
4. Fix `VButton` minimum touch target + Semantics
5. Device UAT: auth, push, deep link, purchase, offline

### Wave R1 — Visual consistency (3–5 days)
1. **AlertDialog → showVDialog** sweep (10 screens, biggest visual win)
2. Replace 5 full-screen `CircularProgressIndicator` with `ScreenLoading`
3. Add `RefreshIndicator` to achievements + world-admin lists
4. Replace hand-rolled `TextField` with `VSearchBar` (explore, chat, submit)
5. Custom-scheme deep link hosts (`post`, `world`, `chat`, `notifications`)

### Wave R2 — System consolidation (1 week)
1. Merge card primitives; single bento radius
2. Strip dead `isDark` / light color ladders
3. Migrate 6 Forui-import widgets
4. Generate 8 pending profession icons or de-scope
5. Fix `validate_assets.ps1` profession ID resolution

### Wave R3 — Public release (1–2 weeks)
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

**Closed beta (now):** Core social loops work, tests green, Prestige Noir on main flows, no P0 routing crashes, backend secured.

**Public launch (not yet):** Dialog/loading/refresh consistency, brand typography shipping, accessibility touch targets, HIBP on Pro, store assets aligned with current UI, device UAT sign-off.

---

*Generated from parallel codebase audit (routing, theme, screens, assets) + CI metrics + Supabase verification. Update after each release wave.*
