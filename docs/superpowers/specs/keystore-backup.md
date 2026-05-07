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
