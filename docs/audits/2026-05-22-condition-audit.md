# Condition audit — 2026-05-22

**Branch:** `develop` @ `0bd9e3b`  
**Prior baseline:** [2026-05-21-baseline-audit.md](./2026-05-21-baseline-audit.md)  
**Scope:** Current app health, issue classes from device/league UAT, release readiness vs `main`.

---

## Executive summary

| Area | Status | Notes |
|------|--------|--------|
| **CI / tests** | Green (verify) | Run `26264586742`: analyze + test passed; APK build in progress at audit time |
| **Code health** | Pass | 108/108 tests locally; analyze exit 0 (info lints only) |
| **Supabase** | Reconciled | Migration drift resolved 2026-05-21; `security_followup` applied |
| **Device blockers (league)** | Mitigated in code + SQL | Slug join, `world_members` backfill; needs APK UAT on `0bd9e3b` |
| **Install / APK** | Documented | User 11 clone uninstall; CI debug signing; ~132 MB release size normal |
| **UI (Forui)** | Partial | Hub/settings/discover/world cards improved; ~27 files still legacy glass/sovereign |
| **Create world** | Fixed in code | Validation + dominion required; rate limit throws (not fake id) |
| **Verifier** | Shipped | Portal + deep link; not in Settings (by design) |
| **Push** | Unverified on device | Server path exists; `device_tokens` smoke still open |
| **Promote to `main`** | **Hold** | Owner device UAT on latest CI APK before promote |

**Verdict:** Safe to **test** on device with CI APK from `0bd9e3b`. **Not** ready to promote to `main` until [DEVICE_UAT.md](../DEVICE_UAT.md) checklist is filled for this build.

---

## Issue taxonomy (what you are dealing with)

### A. Environment / install (not app logic)

| Symptom | Typical cause | Mitigation |
|---------|----------------|------------|
| Black screen on launch | Missing `.env` in APK | CI embeds secrets; `dotenv.load(isOptional: true)` |
| “Package conflicts” after uninstall | Package still on another Android user (e.g. `system_clone` user 11) | `adb shell pm uninstall --user N com.vertiege` |
| Cannot install CI APK over local build | Different signing keys (CI debug vs local keystore) | Full uninstall, then install CI artifact |
| Data “comes back” after reinstall | Supabase account state (expected) | Not a failed uninstall |

### B. Data / membership (Supabase)

| Symptom | Root cause | Fix status |
|---------|------------|------------|
| Empty channels / members in slug worlds | `joined_world_ids` without `world_members`; slug treated as non-remote | Code: `isRemoteWorldId` + join; SQL backfill for testers |
| Search cannot find users globally | Search scoped to `world_members` in shared worlds | **Open** — product gap |
| League ≠ world access | League tables separate from `world_members` | Documented in DEVICE_UAT |

### C. Product / routing

| Symptom | Root cause | Fix status |
|---------|------------|------------|
| Create World appeared dead | Weak validation; rate limit returned `'rate_limited'` as id | **Fixed** `0bd9e3b` |
| Verifier link opened player login | Deep link `vertiege://verifier/login` mapped wrong | **Fixed** router + staff link on login |
| Subscription “missing” for tier 1 | Router blocks `/subscription` when `tier < 2` | By design; UX copy pending |
| Achievement “Pending Review” in app | AI stub; queue in verifier portal | Staff use verifier APK build |

### D. UI / Forui migration

| Symptom | Root cause | Fix status |
|---------|------------|------------|
| Pink glow / unreadable discover cards | `SovereignCard` on world list | `plainStyle` + `FCard.raw` on discover |
| Settings vs More inconsistent | Mixed legacy + Material | `VHubPage` + `VSectionList` on hub screens |
| Tab bar still “glass” feel | Custom `_AppNavBar` (renamed from glass) | Minimal surface nav; not `FBottomNavigationBar` yet |
| Create world form still legacy | Not migrated to `FTextField` / Forui form | **Open** |

### E. Release process

| Gate | Status |
|------|--------|
| `develop` CI verify | Pass on `0bd9e3b` |
| CI APK artifact | Build after verify (standard workflow) |
| Device UAT | Owner-run — checklist mostly empty |
| `main` / GitHub Release | Last success tied to `7a17470` era; wait for UAT on `0bd9e3b` |

---

## 1. Code baseline (2026-05-22)

```text
flutter test  → 108 passed (local)
CI verify job → analyze + test success (run 26264586742)
```

Legacy UI footprint (grep):

- `GlassPanel` / `GlassSheet` / `SovereignCard`: **~27 widget files** (down from ~25 screens+widgets in baseline; core renamed to `VSurfacePanel` / `VLoadingCard` in places but grep still hits `glass_*.dart` and `sovereign_*.dart`).
- Forui hub pattern: `VHubPage`, `VSectionList`, `FCard.raw`, `plainStyle` on discover — **6 areas** migrated.
- Bottom nav: `_AppNavBar` in `tab_layout.dart` — solid surface, not Forui `FBottomNavigationBar`.

Stub / placeholder services (still present):

- `ai_verification_service.dart` — TODO real vision API
- `moderation_filter.dart` — TODO real moderation API

---

## 2. Fixes landed since baseline (commit chain)

| Commit | What |
|--------|------|
| `4b71448` | Verifier portal, achievement review queue, world join |
| `1d081f0` | `localOnlyWorldIds = {nexus}` — no remote join for Nexus |
| `7a17470` | Docs: verifier, DEVICE_UAT, workflow |
| `0bd9e3b` | Forui hub/discover/settings; create-world validation; discover/world detail readability; verifier deep link on login |

---

## 3. Security & backend (unchanged risk profile)

See [2026-05-21-security-advisor.md](./2026-05-21-security-advisor.md) and [rls-audit.md](./rls-audit.md).

- 0 Security Advisor **errors**; 6 WARN categories (search_path, leaked password protection manual toggle, etc.).
- Verifier access: `app_metadata.is_verifier` + `VERIFIER_ADMIN_EMAILS`; RLS on review tables.
- **Manual:** Enable leaked-password protection in Supabase dashboard if not done.

---

## 4. Device UAT status

[DEVICE_UAT.md](../DEVICE_UAT.md) checklist: **not signed off** for build `0bd9e3b`.

**Must re-test on new APK:**

1. Cold start / login (no black screen)
2. Channels + members in `neon-district` / `crystal-shore`
3. Create world (validation messages, success path)
4. Discover / world detail readability
5. Verifier: staff link or `vertiege://verifier/login`
6. Push: `device_tokens` row after permission
7. Clear app data → posts/chat recover

**Install note for OPPO / dual-user:** If `pm list packages` still shows app after drawer uninstall, uninstall **user 11** (or loop users).

---

## 5. Prioritized backlog (updated)

### P0 — Before `main`

| ID | Item |
|----|------|
| D0 | Device UAT on CI APK `0bd9e3b` (all checklist rows) |
| D1 | Confirm create-world E2E on device (not just unit tests) |
| D2 | Verifier smoke on device (deep link + profession/achievement tabs) |

### P1 — High (user-visible)

| ID | Item |
|----|------|
| U1 | Finish Forui migration (~27 legacy files + `FBottomNavigationBar` optional) |
| U2 | Create world screen → Forui form fields |
| U3 | Global profile search (or clear UX that search is world-scoped) |
| U4 | Subscription gate UX for tier 1 (explain upgrade path) |
| P1 | Push delivery smoke on device |

### P2 — Medium

| ID | Item |
|----|------|
| R1 | Replace AI/moderation stubs or hide “pending” until real |
| R2 | Deep links for notification/post targets |
| R3 | Accessibility device pass (font scale, tap targets) |
| C1 | “Coming soon” only where truly deferred (shop, world settings, profile) |

### P3 — Product (optional)

| ID | Item |
|----|------|
| X1 | Separate verifier flavor or web console (vs second tiny APK) |

---

## 6. What is in good shape

- Five-tab IA stable; auth callback not a placeholder.
- Realtime on posts + chat; repositories for core domains.
- Migration history reconciled; security followup migration applied.
- Unit/integration tests green; CI verify job green on latest push.
- League tester issues have **documented root causes** and code/SQL mitigations.
- Verifier workflow separated from player Settings.

---

## 7. Release recommendation

1. Wait for CI **build-apk** on run `26264586742` (or latest green `develop` run).
2. Install via `adb uninstall` (all relevant users) → `adb install -r` artifact.
3. Run [DEVICE_UAT.md](../DEVICE_UAT.md); update checklist table in that file.
4. If pass → merge/promote `develop` → `main` per [DEVELOPMENT_WORKFLOW.md](../DEVELOPMENT_WORKFLOW.md).
5. If fail → log row in DEVICE_UAT + fix on `develop`; do not promote.

---

## References

- [DEVICE_UAT.md](../DEVICE_UAT.md)
- [VERIFIER_PORTAL.md](../VERIFIER_PORTAL.md)
- [DEVELOPMENT_WORKFLOW.md](../DEVELOPMENT_WORKFLOW.md)
- [product-gap-audit.md](./product-gap-audit.md)
- [2026-05-21-baseline-audit.md](./2026-05-21-baseline-audit.md)
