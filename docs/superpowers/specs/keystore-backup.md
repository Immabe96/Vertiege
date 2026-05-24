# Keystore Backup

The Android release keystore is at `android/upload-keystore.jks`.

## Recovery

Without this file, you cannot sign updates to the same app. Store a copy securely:
- Password manager (1Password, Bitwarden) — store the .jks file and passwords
- Encrypted cloud backup
- Offline USB drive

## Credentials

| Field | Value |
|-------|-------|
| Keystore file | android/upload-keystore.jks |
| Key alias | upload |
| Validity | 10000 days (~27 years) |
| Key algorithm | RSA 2048 |

Store passwords separately from the keystore file.

Generate locally:

```bash
./scripts/setup-android-signing.sh
```

This creates `android/upload-keystore.jks` and `android/key.properties` (gitignored).

## GitHub Actions (CI release APK)

Add these **repository secrets** (Settings → Secrets and variables → Actions):

| Secret | Value |
|--------|--------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 android/upload-keystore.jks` (Linux) |
| `ANDROID_KEYSTORE_PASSWORD` | Same as `storePassword` in `key.properties` |
| `ANDROID_KEY_PASSWORD` | Same as `keyPassword` in `key.properties` |
| `ANDROID_KEY_ALIAS` | `upload` (optional) |

CI runs `scripts/ci-setup-android-signing.sh` before `flutter build apk --release`.
If Android secrets are missing, the workflow warns and the APK is **debug-signed** (not interchangeable with release-signed installs).
