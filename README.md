# Vertiege

Social world app — join realms, chat in channels, post, earn prestige, and climb tiers. Built with Flutter, Supabase, and Firebase (FCM).

**Version:** 1.0.0-beta.4

## Download

Stable APKs are published on **[GitHub Releases](https://github.com/Immabe96/Vertiege/releases)** (`app-release.apk`). No local build required.

## Development (cloud-friendly)

| Branch | Use |
|--------|-----|
| `develop` | Day-to-day work — branch here, open PRs here |
| `main` | Release line — updated only when `develop` passes CI |
| `cursor/*` | Short-lived agent branches → PR into `develop` |

After `develop` CI passes (analyze, tests, APK build), `main` is promoted and a new Release is published automatically.

Full branching and CI details: **[docs/CLOUD_WORKFLOW.md](docs/CLOUD_WORKFLOW.md)**

## Stack

- **App:** Flutter, Riverpod, GoRouter, Forui
- **Backend:** Supabase (auth, data, realtime, storage, RLS)
- **Infra:** Firebase (FCM, Crashlytics, Analytics, Remote Config, App Check)

## Local setup

**Requirements:** Flutter stable, JDK 21

```bash
git clone https://github.com/Immabe96/Vertiege.git
cd Vertiege
git checkout develop
cp .env.template .env   # add SUPABASE_URL and SUPABASE_ANON_KEY
flutter pub get
flutter run
```

Backend and push setup: **[docs/FIREBASE_SUPABASE_HYBRID_SETUP.md](docs/FIREBASE_SUPABASE_HYBRID_SETUP.md)**

## Verify before pushing

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release --no-tree-shake-icons
```

Same checks run in GitHub Actions on `develop`.

## Documentation

| Doc | Contents |
|-----|----------|
| [docs/CLOUD_WORKFLOW.md](docs/CLOUD_WORKFLOW.md) | Branches, CI, APK downloads |
| [docs/FIREBASE_SUPABASE_HYBRID_SETUP.md](docs/FIREBASE_SUPABASE_HYBRID_SETUP.md) | Supabase + Firebase setup |
| [docs/DESIGN.md](docs/DESIGN.md) | UI and design system |
| [PLAN.md](PLAN.md) | Product roadmap |
| [REPORT.md](REPORT.md) | Implementation status |

## Project layout

```
lib/
├── screens/      # App pages
├── widgets/      # Feature UI
├── services/     # Supabase, Firebase, domain logic
├── state/        # Riverpod providers
├── models/       # Data types
└── router/       # GoRouter routes
supabase/         # Migrations and Edge Functions
```

## License

MIT
