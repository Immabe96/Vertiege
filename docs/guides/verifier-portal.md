# Verifier portal (staff only)

Staff use the **same account and app** as players. Verification review is an extra screen, not a separate app shell.

## What it does

Open **Settings → Staff review** (visible only for verifier accounts):

| Tab | Data | Action |
|-----|------|--------|
| **Professions** | `verification_submissions` (status `pending`) | Approve / reject profession proof |
| **Achievements** | `user_achievements` (status `submitted`) | Approve / reject achievement proof |
| **Flagged Posts** | Posts with `pending_review` / `flagged` | Approve / remove |

Use the back button to return to Nexus, Chat, and the rest of the app. Sign out from **Settings** like any player.

## Who can access

An account must match **one** of:

- Supabase Auth `app_metadata.is_verifier = true` (or `role = verifier`)
- Email listed in repo secret / local `.env`: `VERIFIER_ADMIN_EMAILS` (comma-separated, debug builds)

Migrations `20260522120000_verifier_portal_access.sql` and `20260522123000_verifier_achievement_access.sql` add RLS for verifiers on submission tables.

## Sign-in

| Entry | Result |
|-------|--------|
| **Player login** (`/login`) | Full app; verifiers also see Staff review in Settings |
| **Staff sign-in** (`/verifier/login` or deep link) | Same session → lands on Nexus after onboarding (not review-only) |

## Open staff review on a device (APK)

1. Sign in with a verifier account (normal login is fine).
2. **Settings → Staff review**

Optional deep link to the review screen (must already be signed in as a verifier):

```powershell
adb shell am start -a android.intent.action.VIEW -d "vertiege://verifier/review" com.vertiege
```

Staff sign-in deep link (`vertiege://verifier/login`) opens the staff login form; after sign-in you enter the main app like everyone else.

## Local development

```powershell
flutter run
```

Ensure `.env` has `VERIFIER_ADMIN_EMAILS=your@email.com` if you rely on email allowlist without Supabase metadata.

## Grant another verifier

1. Create or pick a Supabase Auth user.
2. In Dashboard → Authentication → user → App metadata:

   ```json
   { "is_verifier": true, "role": "verifier" }
   ```

3. Or add their email to `VERIFIER_ADMIN_EMAILS` in GitHub Actions secrets and local `.env`.
