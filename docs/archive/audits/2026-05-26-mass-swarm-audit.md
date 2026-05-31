# Mass swarm audit — Vertiege (2026-05-26)

**Method:** Parallel swarm researchers + implementation pass (Android-focused; **iOS on hold** until Mac hardware).  
**Tests:** **182** passing · **Migrations:** `20260527150000_audit_progression_fixes.sql`, `20260527160000_world_job_applications.sql` applied · **`send-push`** redeployed

---

## Post-audit status (A-target)

| Pillar | Before | After | Notes |
|--------|--------|-------|-------|
| **UI/UX + Forui** | B− (~58%) | **A−** | Tab compose → `showAppSheet`; nav semantics; SnackBars removed; achievements loading |
| **Routing** | B | **A** | `/chats` fixed; DM → `/chat`; deep link uses `routeForNotification`; `discover` reserved |
| **Leveling** | C+ | **A−** | Server tier on activity XP; ascension RPC; XP UI unified; growth persisted; explore quest wired |
| **Permissions** | C | **A−** | `DevicePermissionService` + Settings push sheet + open settings |
| **Features** | B−/C | **A−** | RC defaults **on** for economy; governance → polls CTA |
| **Polish** | B− | **A−** | Copy/labels; stale governance text removed |

**iOS (deferred):** URL schemes, plist strings, device UAT — no Mac build host.

**Remaining for A+ device sign-off:** Full `DEVICE_UAT.md` on arm64 APK after install.

---

## Implemented fixes (2026-05-26)

### Routing
- `notification_navigation.dart` — DM → `chatShellPath`; fallback `/chat`
- `app_router.dart` — `_NotificationDeepLink` uses `routeForNotification`
- `world_route_redirects.dart` — `discover` in reserved segments
- `send-push/index.ts` — type-first `routeFor()` aligned with client
- `firebase_messaging_handlers.dart` / `local_notification_service.dart` — shell chat routes

### Leveling / gamification
- SQL `award_activity_xp` updates `tier`; profile tier backfill
- SQL `bump_world_activity_score` + `WorldService.bumpActivityScore`
- SQL `ascend_prestige` + client RPC in `ascendToPrestige`
- Achievements hub uses `resident.totalXp`; loading skeleton
- `worldCreationLimit` tier 3 → 3 worlds
- Tier messages: “promoted to” (not ascension wording)
- `onWorldVisited()` on world detail open
- Identity XP copy corrected

### Permissions
- `lib/services/device_permission_service.dart` — notifications, camera, gallery, denial sheet
- `push_token_service.dart` + `settings_screen.dart` push toggle integration

### Product / RC
- `remote_config_service.dart` — marketplace, treasury, polls, challenges **default true**
- `world_settings_screen.dart` — Growth level labels; **Manage polls** button

### Forui / polish
- `tab_layout.dart` — `FScaffold` + `FBottomNavigationBar`; compose `showAppSheet`; tab `Semantics`
- `settings_screen.dart` — 8 dialogs + reset flow → `showVDialog` / `FDialog` (`lib/widgets/core/v_dialog.dart`)
- `world_realm_dossier.dart`, `world_treasury_screen.dart` — `VFeedback`

### World jobs
- `world_job_applications` table + RPCs `apply_to_world_job`, `accept_world_job_application`
- `WorldJobsScreen` — Apply, Applicants review, accept → filled

---

## Still deferred (not blocking Android beta)

| Item | Reason |
|------|--------|
| iOS `vertiege://` URL schemes + plist | **No Mac** — on hold |
| Subscription IAP server entitlement | Monetization phase 2 |
| Applicant display names in jobs sheet (shows id today) | Polish |
| Broad widget/integration test suite | Ongoing |
| `VImage` / `LoadState` hot-path adoption | Refactor wave |

---

## P0 device checklist (you)

1. Install `app-release.apk` (arm64-v8a from `./scripts/build_release_apk.sh`)
2. DM push: background → banner → tap → `/chat/{room}`
3. Deny notifications → Settings sheet → Open Settings works
4. Achievements tier matches Identity XP
5. Join dominion world → growth level persists after restart
6. Marketplace / treasury / polls visible (RC on)
7. Verifier approve one proof

See `docs/DEVICE_UAT.md` rows 1–37.

---

## Verification

```bash
flutter test          # 182 passed
flutter analyze lib
supabase db push      # includes 20260527150000, 20260527160000
supabase functions deploy send-push --no-verify-jwt
./scripts/build_release_apk.sh
```

---

## Swarm researcher map

| Researcher | Focus |
|------------|--------|
| UI/UX + Forui | Anti-patterns, tab shell, dialogs |
| Routing | GoRouter, deep links, DM paths |
| Leveling | XP, tier, rep, growth, ascension |
| Permissions | Android manifest + runtime |
| Features | Economy RC, gaps, beta matrix |
