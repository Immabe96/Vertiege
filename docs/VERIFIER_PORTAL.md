# Verifier portal (staff only)

Staff use a **separate login path** from normal players. The main app **Settings** screen does not link here.

## What it does

After verifier sign-in you only see **Staff review**:

| Tab | Data | Action |
|-----|------|--------|
| **Professions** | `verification_submissions` (status `pending`) | Approve / reject profession proof |
| **Achievements** | `user_achievements` (status `submitted`) | Approve / reject achievement proof |
| **Flagged Posts** | Posts with `pending_review` / `flagged` | Approve / remove |

Sign out returns to verifier login. You cannot open Nexus, Chat, or other app routes while in **verifier session** (see below).

## Who can sign in

An account must match **one** of:

- Supabase Auth `app_metadata.is_verifier = true` (or `role = verifier`)
- Email listed in repo secret / local `.env`: `VERIFIER_ADMIN_EMAILS` (comma-separated)

Migrations `20260522120000_verifier_portal_access.sql` and `20260522123000_verifier_achievement_access.sql` add RLS for verifiers on submission tables.

## Two login modes (same account allowed)

| Entry | Route | Result |
|-------|--------|--------|
| **Player** | Normal app → Login | Full app (Nexus, Chat, …) |
| **Staff** | `vertiege://verifier/login` | Staff review only |

Use **player login** for everyday testing. Use the **deep link** when reviewing submissions.

Internally, verifier login sets `VerifierSession.active`; player login clears it.

## Open verifier login on a device (APK)

1. Enable USB debugging, install the CI APK.
2. On your PC:

   ```powershell
   adb shell am start -a android.intent.action.VIEW -d "vertiege://verifier/login" com.imma96.virtual_status_worlds
   ```

3. Sign in with a verifier account.
4. Review pending items; tap **Sign out** when done.

## Local development

```powershell
flutter run
# Then open route /verifier/login in IDE, or use the adb command above on a connected device.
```

Ensure `.env` has `VERIFIER_ADMIN_EMAILS=your@email.com` if you rely on email allowlist without Supabase metadata.

## Achievement vs profession

- **Pending Review** on Identity → **Achievements** is `user_achievements` → use **Achievements** tab here.
- Profession badge verification uses **Professions** tab (`verification_submissions`).

AI auto-approval for achievements is not implemented; staff approval is the path until that ships.

## Grant another verifier

1. Create or pick a Supabase Auth user.
2. In Dashboard → Authentication → user → App metadata:

   ```json
   { "is_verifier": true, "role": "verifier" }
   ```

3. Or add their email to `VERIFIER_ADMIN_EMAILS` in GitHub Actions secrets and local `.env`.
