# Device UAT log

Manual checks on **CI APK** before promoting `develop` → `main`. Owner-run; update this file as you test.

## Install latest develop APK

```powershell
# After green CI on develop — replace RUN_ID
gh run download RUN_ID -n vertiege-apk-RUN_ID -D build/ci-artifacts/latest

adb uninstall com.imma96.virtual_status_worlds
adb install -r build/ci-artifacts/latest/app-release.apk
```

Requires GitHub secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY` in CI (APK embeds `.env`). Empty `.env` caused black screen on launch — fixed with `dotenv.load(isOptional: true)` + CI secrets.

---

## Checklist

| # | Area | Pass? | Notes |
|---|------|-------|-------|
| 1 | Cold start / login | | No black screen; reaches main shell |
| 2 | Bottom tabs (5) | | Nexus, Discover, Chat, Identity, More |
| 3 | Chat → worlds rail | | Names readable; opens correct world |
| 4 | World channels | | Lists channels; can open a channel |
| 5 | World members | | Shows all members in joined worlds |
| 6 | Search residents | | Can find other members by name |
| 7 | Create world | | Completes or clear error |
| 8 | Subscription (tier 1) | | Tier 1 users: expect upgrade gate, not silent bounce |
| 9 | Clear app data → relaunch | | Posts/chat recover from Supabase |
| 10 | Push token | | Row in `device_tokens` after allow + login |

---

## 2026-05-22 — League tester findings (resolved / tracked)

Testers in league; **league ≠ world membership**.

| Issue | Root cause | Fix |
|-------|------------|-----|
| No channels in Neon / Crystal Shore | `joined_world_ids` on profile but no `world_members` rows; slug worlds skipped by `isRemoteWorldId` | SQL backfill for testers; code: slug IDs join Supabase; exclude client-only `nexus` |
| Search could not find Immabe | Search used `world_members` only | Still limited to shared worlds until global profile search ships |
| Members list showed only self | Same as channels — no `world_members` | Backfill + new joins |
| Subscription “missing” | Router blocks `/subscription` when `tier < 2` | Documented; UX improvement pending |
| Achievement “Pending Review” | AI stub; no staff queue in main app | **Achievements** tab in verifier portal |
| Duplicate “Verified Professional” badges | Identity showed shop `decorations`, not profession badges | Identity uses `verifiedRoles` → profession badge labels |

### Supabase backfill (testers)

Applied for `neon-district` and `crystal-shore` for Ahugaaf and ＤＡＫＩ. New signups after slug-join fix should not need manual SQL.

---

## Verifier portal smoke

```powershell
adb shell am start -a android.intent.action.VIEW -d "vertiege://verifier/login" com.imma96.virtual_status_worlds
```

- [ ] Sign in as verifier
- [ ] **Professions** tab loads (may be empty if no submissions)
- [ ] **Achievements** tab shows submitted rows (e.g. `edu-college`)
- [ ] Approve one test submission; status updates in Supabase
- [ ] Sign out; cannot reach main app without player login

See [VERIFIER_PORTAL.md](VERIFIER_PORTAL.md).
