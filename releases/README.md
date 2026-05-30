# Release APKs

Versioning follows **pubspec.yaml** (`version: NAME+BUILD`).

## Naming

| Artifact | Pattern |
|----------|---------|
| Release APK (arm64) | `vertiege-{NAME}+{BUILD}-arm64-release.apk` |
| Manifest | `manifest-{NAME}+{BUILD}.json` |

Example: `vertiege-1.1.0-beta.2+6-arm64-release.apk`

## Build

```bash
./scripts/build_release_apk.sh           # bump build +1, test, build, copy here
./scripts/build_release_apk.sh --no-bump # keep pubspec build number
```

APK binaries are gitignored (`/releases/*.apk`). Manifests are committed.

## Channels

| Channel | Version name example |
|---------|----------------------|
| Internal UAT | `1.1.0-beta.N` |
| Production (future) | `1.1.0` |

Bump **build number** (`+N`) for every APK you ship to testers. Bump **name** when the release notes change.
