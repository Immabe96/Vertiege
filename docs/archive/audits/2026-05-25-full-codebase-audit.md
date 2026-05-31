# Full codebase audit snapshot

**Date:** 2026-05-25 (updated 2026-05-26 post–mass-swarm)  
**Scope:** Post–gamification/worlds wave; audit backlog **implemented** (see `2026-05-26-mass-swarm-audit.md`).

## Executive summary

| Area | Status | Notes |
|------|--------|-------|
| Tests | ✅ | 178+ passing (`flutter test`) |
| Analyzer | ✅ | 0 errors on `lib/` |
| Achievement catalog | ✅ | **619** entries; hub shows count |
| World detail UI | ✅ | Contained banner, progression help |
| Progression glossary | ✅ | In-app + vision doc |
| DM push | ✅ | Migration + `send-push` deployed 2026-05-26 |
| Safety disclaimers | ✅ | All 15 preset worlds + custom fallback |
| Session sign-out | ✅ | Outbox + caches cleared (`session_reset` + `AuthService.signOut`) |
| Analytics (key flows) | ✅ | Sign in/out, world view/join, post, quest, onboarding, dossier |
| Crashlytics | ✅ | `FirebaseCrashReporter` via `FirebaseBootstrap.initializeCore` |
| Router tests | ✅ | `app_auth_redirect`, deep links, world routes, notifications |
| Feature depth | ⚠️ | Marketplace/treasury/polls still thin vs schema |
| Widget / integration tests | ⚠️ | No broad widget suite |
| APK size | ✅ | `./scripts/build_release_apk.sh` builds arm64-v8a only (~73MB); pass `--split-per-abi` for all CPUs |

## Completed (2026-05-25 – 2026-05-26)

### Product / content
- **Safety disclaimers** — `lib/utils/world_foundations.dart`: wealth, strategy, community, and profession-specific copy for every preset world; `kCommunitySafetyDisclaimer` on custom dominions.
- **Achievement catalog** — 619 entries (v4 bulk); hub shows `achievementCatalogSize`.

### Engineering
- **`app_auth_redirect.dart`** — Pure gate/onboarding redirect helpers; replaces placeholder gate test.
- **Analytics** — `signIn` / `signOut`, `worldViewed` / `worldJoined`, `postCreated`, `questCompleted`, `onboardingCompleted` / `gateCompleted` (plus existing dossier/marketplace/achievement events).
- **Crashlytics** — Documented; wired on Firebase init; `setUser` on resident load, cleared on sign-out.
- **Release build** — `scripts/build_release_apk.sh` (arm64 default); `--split-per-abi` optional.

### Backend (prior session)
- DM push migration + `send-push` redeploy on `wjaphoaxalvgjnrwqjwe`.

## Remaining (prioritized)

### P0 — device verification
1. DM push UAT (rows 33–37 in `docs/DEVICE_UAT.md`).
2. Confirm Vault `webhook_secret` + `notifications` INSERT fanout (see `docs/NOTIFICATIONS.md`).

### P1 — product / QA
1. Device UAT: world detail (banner, prestige vs growth labels).
2. Verifier portal smoke on achievement proof queue.

### P2 — engineering (deferred)
1. Adopt `VImage` / `LoadState` / `AppFailure` in hot paths.
2. Broader widget/integration tests.
3. Asset diet beyond split-per-abi.

### P3 — vision gaps
See `docs/audits/2026-05-24-gamification-vision-gap-audit.md` and `docs/vision/world-capability-matrix.md`.

## Verification commands

```bash
flutter test
flutter analyze lib
./scripts/build_release_apk.sh              # universal APK
./scripts/build_release_apk.sh   # arm64-v8a (~73MB)
```

## Related docs

- `docs/NOTIFICATIONS.md` — DM push deploy checklist
- `docs/vision/gamification-and-worlds.md` — progression glossary
- `docs/achievements/CATALOG.md` — catalog layers
- `docs/DEVICE_UAT.md` — manual test matrix
