# Linux setup session — 2026-05-24

Night log for moving Vertiege dev from Windows to Arch Linux (CPH2649 / OnePlus, Android 16, 7 GB RAM).

---

## What works now

| Item | Status |
|------|--------|
| Java 21 (OpenJDK) | OK |
| Flutter 3.44.0 stable | OK |
| Supabase CLI + login | OK |
| Firebase CLI + login | OK |
| Android SDK at `/opt/android-sdk` (no Android Studio) | OK |
| Platform 35 + 36, build-tools 36 + 35, NDK 28.2 | OK |
| JDK / Android env in `~/.zshrc` | OK |
| `.env` with Supabase keys | OK |
| `google-services.json` present | OK |
| `flutter test` (110 tests) | Passed earlier |
| Debug APK builds (with reduced Gradle heap) | OK (~90s incremental) |

**Device:** `44ec8e9f` (CPH2649)

**Firebase on Linux host:** Developing on Arch with `flutter run` targeting **Android** is supported. A desktop `linux` Flutter target is **not** configured (`DefaultFirebaseOptions` rejects `TargetPlatform.linux`); Crashlytics/FCM/Remote Config run on device builds, not on Linux desktop runs.

---

## Environment notes (Arch)

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
```

- SDK is user-writable: `sudo chown -R $USER: $ANDROID_HOME` (needed because `/opt/android-sdk` is root-owned from pacman).
- Stale pacman lock once: `sudo rm /var/lib/pacman/db.lck` when no pacman/yay is running.
- **Do not run multiple `flutter run` sessions** — they fight each other and confuse install state.

### Gradle (local 7 GB RAM)

`android/gradle.properties` was tuned for this machine:

- `org.gradle.jvmargs=-Xmx1536m -XX:MaxMetaspaceSize=512m`
- `org.gradle.workers.max=2`
- `org.gradle.daemon=false`

First full Gradle build can take 5–10+ minutes; JVM crash/OOM happened at 3072m before this change.

---

## Issues seen on device (in order)

### 1. Black screen only (no Flutter splash)

**Cause:** `main()` awaited `FirebaseBootstrap.initialize()` and `Supabase.initialize()` **before** `runApp()`. User only saw native launch color `#070910` for many seconds.

**Fix:** `runApp()` runs immediately in `main.dart`; Firebase/Supabase init moved to `app.dart` after first frame.

---

### 2. “Page not found” after login / OAuth

**Cause:** Android parses `vertiege://auth/callback` as host `auth` + path `/callback`, but router only had `/auth/callback`.

**Fix:** Redirect in `lib/router/app_router.dart` (same pattern as verifier deep links). Also added `errorBuilder` with “Go to Nexus”.

---

### 3. Riverpod crash on startup

**Cause:** `ResidentNotifier.build()` called `ref.listen(residentProvider, …)` — self-dependency. Broke posts/achievements background loads.

**Fix:** `residentMilestoneListenerProvider` + `ref.watch` in `app.dart` after splash.

---

### 4. Bad world channel URLs

**Cause:** `/explore/{worldId}/channel/{uuid}` — no matching route (extra path segment).

**Fix:** Use `/explore/{worldId}/{channelName}?id={channelId}` in `world_channel_shortcuts.dart` and `world_feed_chat_teaser.dart`.

---

### 5. Gradle / SDK install failures

- NDK + build-tools could not auto-install: **SDK not writable**.
- Gradle daemon **JVM crash** on 7 GB RAM at 3072m heap.

**Fix:** `sudo sdkmanager` for NDK + build-tools; chown SDK; lower Gradle heap.

---

### 6. Splash with logo, then stuck

**Cause:** Splash waited on `loadResident()` + `loadWorlds()` (network) with only 3s timeout; logged-in profile fetch had no timeout; `ResidentState` defaulted `isLoading: true` and blocked router.

**Fix:** Splash dismisses on timer (~1.8s), loads in background; profile fetch 8s timeout; default `isLoading: false`.

---

### 7. Splash shows, then “App not responding” (ANR)

**Cause:** Still **awaiting** full Firebase + Supabase bootstrap before leaving splash, then firing **all** background loads (posts, achievements, events, quests, league, store) at once. Heavy provider/router work during splash build (`appRouterProvider`, listeners).

**Fix (in progress, not fully verified on device):**

- Splash is **lightweight** `MaterialApp` only — no Forui, no router, no Riverpod listeners.
- Bootstrap runs **in parallel** with splash timer (do not await before dismiss).
- Firebase split: `initializeCore()` then `initializeDeferred()` (App Check, Analytics, Remote Config).
- Push route listeners attached **after** splash.
- Secondary loads deferred **800ms after** login/home is shown.

---

## Code files touched tonight

| File | Change |
|------|--------|
| `lib/main.dart` | Early `runApp`, no blocking Firebase/Supabase |
| `lib/app.dart` | Post-frame bootstrap, splash timer, deferred loads, lightweight splash UI |
| `lib/services/firebase_bootstrap.dart` | `initializeCore` / `initializeDeferred` |
| `lib/services/remote_config_service.dart` | 5s timeout on fetch |
| `lib/router/app_router.dart` | Auth deep link + error page |
| `lib/state/resident_provider.dart` | Milestone listener, `isLoading` default, profile timeout |
| `lib/widgets/worlds/world_channel_shortcuts.dart` | Channel route fix |
| `lib/widgets/worlds/world_feed_chat_teaser.dart` | Channel route fix |
| `android/gradle.properties` | Lower memory for local builds |

---

## Not fixed / known leftovers

- **RenderFlex overflow** on login (logged in Crashlytics earlier) — layout bug, separate from startup.
- **FCM** `SERVICE_NOT_AVAILABLE` in logcat — push may not work until Play Services/network happy; not blocking UI.
- **Latest ANR fix** — code written; **full rebuild + device test not completed** (build interrupted before sleep).
- **`android/gradle.properties` heap** — tuned for 7 GB laptop; CI on GitHub uses more RAM (may be fine, or revert for CI-only if needed).

---

## Tomorrow — pick up here

1. **One terminal only:**

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
cd ~/Vertiege
git pull   # if you pushed; else just use local changes
flutter build apk --debug
adb devices
adb install -r build/app/outputs/flutter-apk/app-debug.apk
flutter run -d 44ec8e9f --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk
```

2. **Expected flow:** Flutter splash (~2s) → login (or home if session exists). No ANR.

3. **If ANR again:** grab logcat:

```bash
adb logcat -d | rg -i 'ANR|not responding|flutter|vertiege' | tail -80
```

4. **If black screen again:** confirm you’re on latest code (`main.dart` must not await Firebase before `runApp`).

5. **Optional:** commit the startup/router fixes when happy (not done tonight).

---

## Useful project docs

- [docs/DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md)
- [docs/DEVICE_UAT.md](DEVICE_UAT.md)
- [docs/FIREBASE_SUPABASE_HYBRID_SETUP.md](FIREBASE_SUPABASE_HYBRID_SETUP.md)

---

## Session summary

Moved from zero Linux tooling to a working build pipeline on Arch. Main pain: **startup doing too much before and during splash** on a **7 GB RAM** machine, plus **Android SDK permissions** and **OAuth deep link** routing. Core app logic is fine (tests pass); remaining work is **startup performance** and **one clean device run** to confirm ANR is gone.
