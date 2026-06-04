# API 30 release smoke (Android 11)

Use this after a release APK build before store submission.

## Build

```bash
./scripts/release_smoke_api30.sh
```

Install on an API 30 emulator or device:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Pass criteria

| Step | Expected |
|------|----------|
| Cold start | Splash → login or home without crash |
| Invite link (logged out) | `vertiege://invite/CODE` saves code; after gate, lands in world (not invite screen loop) |
| World feed | Posts load; post deep link opens thread |
| Voice | Campfire mini-bar shows status; leave ends session |
| Subscription | Sandbox purchase verifies; tier updates in settings |
| Season cohort | Challenges screen shows cohort banner + season challenge |
| Polls | Veteran+ creates poll; vote succeeds |

Full Wave 6 checklist: [wave-6-signoff-checklist.md](wave-6-signoff-checklist.md).

Log issues in [issue-log.md](issue-log.md).
