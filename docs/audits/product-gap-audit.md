# Product Gap Audit

**Date:** 2026-05-19 (original) · **Refreshed:** 2026-05-21  
**Scope:** Gaps between app vision ([PLAN.md](../../PLAN.md)) and `develop` as of baseline audit.

See also: [2026-05-21-baseline-audit.md](./2026-05-21-baseline-audit.md)

---

## Resolved or improved since 2026-05-19

| # | Was | Now (2026-05-21) |
|---|-----|------------------|
| 1 | No push fanout | Edge function + DB trigger on remote; **3 `device_tokens` rows** — verify delivery on device |
| 2 | Auth callback placeholder | `AuthCallbackScreen` loads session + resident and routes |
| 3 | No realtime | Posts + chat DM/channel subscriptions active |
| 6 | 4 bottom tabs | **5 tabs:** Nexus, Explore, Chat, Identity, More |
| 9 | Google Fonts flash | **No `GoogleFonts` in `lib/`** |
| 16 | Unapplied migrations | Remote/local tail **reconciled** — [migration-reconciliation](./2026-05-21-migration-reconciliation.md) |

---

## Critical Gaps (block production use)

### 1. Push delivery not fully verified
- Server path configured; tokens exist on remote
- **Remaining:** background notification smoke test on device
- **PLAN.md Phase 9**

### 2. ~~Auth deep-link placeholder~~ — fixed
- OAuth/magic-link callback handled in `auth_callback.dart`
- Deep links for post/world/notification targets still incomplete

### 3. Realtime partial
- Posts and chat subscribed; not all tables (notifications still FCM-first)
- **PLAN.md Phase 6**

### 4. Offline durability is partial
- `MutationOutboxService` exists; some caches still authoritative in edge paths
- Clear-app-data test still required
- **PLAN.md Phase 7**

---

## High Gaps (visible to users)

### 5. Glass/legacy UI (~25 files)
- `GlassPanel`, `GlassSheet`, `SovereignCard`; `_GlassNavBar` on `TabLayout`
- **PLAN.md Phase 3**

### 6. Deep links incomplete
- Five-tab IA done; notification/post/profile deep routes still thin
- **PLAN.md Phase 4**

### 7. World content generic for non-starter worlds
- Only `neon-district` and `crystal-shore` have full foundation content
- **PLAN.md Phase 5**

### 8. Image pipeline inconsistent
- Fallback chain and bucket policy verification ongoing
- **PLAN.md Phase 5**

### 9. ~~Google Fonts~~ — resolved

---

## Medium Gaps (feature completeness)

### 10. Feature screens not fully integrated
- Marketplace, Treasury, Polls, Challenges — partial / “coming soon” copy
- **PLAN.md Phase 10**

### 11. Search limited
- Worlds + residents; not posts/channels/tags
- **PLAN.md Phase 10**

### 12. Composer FAB-only on Nexus
- **PLAN.md Phase 10**

---

## Low Gaps (infrastructure and polish)

### 13–15. Firebase infra
- Crashlytics, Analytics, Remote Config — wiring per Phase 9

### 16. ~~Migration drift~~ — reconciled in repo (May-12 remote-only history documented)

### 17. Accessibility
- Icon tooltips partial; text-scale device test not done
- **PLAN.md Phase 12**

### 18. Test coverage
- **108 tests**; still narrow on widgets/integration/RLS
- **PLAN.md Phase 13**

---

## Not Gaps (by design)

- Anon key only in Flutter — correct
- Immabe superuser bypass — intentional
- IAP disabled in debug — intentional
- Starter worlds auto-join — intentional

---

## Summary (2026-05-21)

| Severity | Open | Notes |
|----------|------|-------|
| Critical | 3 | Push verify, realtime breadth, persistence |
| High | 4 | Glass UI, deep links, world content, images |
| Medium | 3 | Features, search, composer |
| Low | 4 | Firebase infra, a11y, tests |
