# Vertiege

Social world app — join realms, chat in channels, post, earn prestige, and climb tiers. Built with Flutter, Supabase, and Firebase (FCM).

**Version:** 1.1.0-beta.1

## Download

Stable APKs: **[GitHub Releases](https://github.com/Immabe96/Vertiege/releases)** (`app-release.apk`).

## How we develop

Local workflow on your PC:

1. Work on **`develop`** (or a `fix/*` / `feature/*` branch → PR into `develop`).
2. **GitHub builds the APK** — you do not need a local release build.
3. When CI passes, **`main` updates** and a new Release APK is published.

| Branch | Use |
|--------|-----|
| `develop` | Day-to-day integration |
| `fix/*`, `feature/*` | Your work branches |
| `main` | Stable releases (automation only) |

Details: **[docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md)**

## Local PC setup

**Requirements:** Flutter stable, JDK 21 (for `flutter run` — not for release APK builds)

```bash
git clone https://github.com/Immabe96/Vertiege.git
cd Vertiege
git checkout develop
cp .env.template .env
flutter pub get
flutter run
```

Before pushing (saves RAM — **no local APK build**):

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

## Stack

- **App:** Flutter, Riverpod, GoRouter, Forui
- **Backend:** Supabase (auth, data, realtime, storage, RLS)
- **Infra:** Firebase (FCM, Crashlytics, Analytics, Remote Config, App Check)

## Documentation

| Doc | Contents |
|-----|----------|
| [docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) | Local + cloud workflow, CI, APK downloads |
| [docs/FIREBASE_SUPABASE_HYBRID_SETUP.md](docs/FIREBASE_SUPABASE_HYBRID_SETUP.md) | Supabase + Firebase setup |
| [docs/DESIGN.md](docs/DESIGN.md) | UI and design system |
| [PLAN.md](PLAN.md) | Product roadmap |
| [REPORT.md](REPORT.md) | Implementation status |

## Project layout

```
lib/           # screens, widgets, services, state, models, router
supabase/      # migrations and Edge Functions
```

## License

MIT
