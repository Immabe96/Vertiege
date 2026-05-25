# Device UAT

**Current Android package:** `com.vertiege`. If upgrading from an older build, also run `adb uninstall com.imma96.virtual_status_worlds`.

Manual checks on **CI APK** before promoting `develop` → `main`. Owner-run; update this file as you test.

## Install latest develop APK

```powershell
# After green CI on develop — replace RUN_ID
gh run download RUN_ID -n vertiege-apk-RUN_ID -D build/ci-artifacts/latest

adb uninstall com.vertiege
adb install -r build/ci-artifacts/latest/app-release.apk
```

Requires GitHub secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY` in CI (APK embeds `.env`). Empty `.env` caused black screen on launch — fixed with `dotenv.load(isOptional: true)` + CI secrets.

For **release-signed** CI APKs (same key as local `flutter build apk --release`), also set `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, and `ANDROID_KEY_PASSWORD` — see [keystore-backup.md](superpowers/specs/keystore-backup.md).

### “App already installed” / won’t install after uninstall

**Clearing cache or storage in Settings does not remove the app.** You must **Uninstall** the app (or use `adb uninstall`). If the launcher still shows Vertiege, the package is still there.

| What you did | Effect |
|--------------|--------|
| Settings → Clear cache | App **still installed**; same package name blocks APK |
| Settings → Clear storage | Data removed, app **still installed** |
| Uninstall from app drawer | Should remove package (see adb check below) |

**Reliable install (recommended for CI APKs):**

```powershell
adb devices
adb uninstall com.vertiege
adb shell pm list packages | findstr virtual_status
# (no output = gone)

adb install -r C:\path\to\app-release.apk
# If install still fails:
adb install -r -d C:\path\to\app-release.apk   # allow version downgrade
```

**Why the phone installer can still fail after “uninstall”:**

1. **Package not fully removed** — work profile, second user, or installer UI glitch. `adb uninstall` is definitive.
2. **Different signing key** — CI uses the **release** keystore when Android secrets are configured; otherwise it falls back to **debug** signing. A local release APK and a CI debug APK are **different signatures** — full uninstall then install is required when switching.
3. **Same error text, different cause** — “conflicting with existing app” often means the old package is **still registered**, not that leftover data blocks install.

**Your data:** uninstall **does** remove app data for that package. If channels/settings looked “stuck” after reinstall, that was usually an **old APK** (empty `.env` / missing `world_members`), not because Android kept old files. After `adb uninstall`, you get a clean install.

**Optional:** In Settings → Apps → Vertiege, confirm **Uninstall** (not only Clear storage). Then install via `adb` as above.

### Uninstalled from the phone, but APK still won’t install

Android **does not** block a new APK because old `SharedPreferences`, cache, or Vertiege database files were “left on disk.” Sideload install fails when the **package name is still registered** or the **APK signature / version** is incompatible — not because generic “data” remained.

If you **truly** uninstalled and install still failed, one of these is almost always true:

| Cause | What happened | Check |
|-------|----------------|-------|
| Package still installed | Drawer uninstall didn’t remove it (OEM bug, work profile, second user, “archived” app) | `adb shell pm list packages \| findstr virtual_status` |
| Signature mismatch | Old APK signed with a **different key** than the GitHub CI APK (local release keystore vs CI debug key) | `adb install` prints `INSTALL_FAILED_UPDATE_INCOMPATIBLE` |
| Version downgrade | New APK has a **lower** `versionCode` than what was installed before | `adb install -r -d ...` |
| Corrupt download | Incomplete APK from browser/GitHub | Re-download; compare file size with CI artifact |

**Why it can feel like “data survived uninstall”:**

1. **Server state** — Login uses Supabase. Worlds, posts, and profile live in the cloud. Reinstall + same account = same account data (expected).
2. **Google backup (optional)** — Some devices restore app backup on reinstall (settings, `shared_preferences`). That only runs **after** a successful install; it does not block install.
3. **Orphan files** — Photos you saved to the gallery, or rare keystore entries, can outlive the app but **do not** block installing `com.vertiege` again.

**Prove whether the package is gone (run before installing APK):**

```powershell
adb shell pm list packages | findstr virtual_status
adb shell pm path com.vertiege
```

- First command: **no line** = uninstalled for this user.
- Second command: `Package not found` = gone. Any path returned = still installed → use `adb uninstall com.vertiege`.

**If the phone says Uninstall but `pm list` still shows the app:** try Settings → Apps → Vertiege → Storage → **Clear storage**, then Uninstall again; or remove from a **work profile** / **Secure Folder** / **dual-app** clone if you use one. `adb uninstall` removes the package for the USB-connected user when the UI didn’t.

**Capture the real error (next time):**

```powershell
adb install -r path\to\app-release.apk
# Read the failure line, e.g. INSTALL_FAILED_UPDATE_INCOMPATIBLE
```

**Exact phone message:** `App not installed as package conflicts with an existing package`

Same as above: the **package is still registered** (often another user / work profile) **or** the APK is signed with a **different key** than the copy that was on the phone. Uninstall from the drawer does not always remove it for all users.

```powershell
# Remove for all users (USB debugging on)
adb shell pm uninstall --user 0 com.vertiege
adb shell pm uninstall --user 10 com.vertiege
# Or loop users from: adb shell pm list users

adb shell pm list packages | findstr virtual_status
adb install -r path\to\app-release.apk
```

**APK size check:** GitHub Release `app-release.apk` for `1.0.0-beta.4` is ~**132 MB** (~139 MB on disk). That matches the phone installer. If size is wildly different, re-download from [Releases](https://github.com/Immabe96/Vertiege/releases) or CI artifact `vertiege-apk-<run_id>`.

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
| 11 | World About (visitor) | | Not joined → lands **ABOUT**; charter teaser; locked economy tiles show reason |
| 12 | World About (member) | | Joined → lands **FEED**; ABOUT shows full charter, rep, economy unlocks |
| 13 | World About — orientation | | Get started steps open #info / #rules / #roles / #general |
| 14 | World About — news | | Tap decree/announcement → Feed highlights post |
| 15 | World About — leadership | | Sovereign + council rows; tap → resident profile |

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
adb shell am start -a android.intent.action.VIEW -d "vertiege://verifier/login" com.vertiege
```

- [ ] Sign in as verifier
- [ ] **Professions** tab loads (may be empty if no submissions)
- [ ] **Achievements** tab shows submitted rows (e.g. `edu-college`)
- [ ] Approve one test submission; status updates in Supabase
- [ ] Sign out; cannot reach main app without player login

See [VERIFIER_PORTAL.md](VERIFIER_PORTAL.md).
