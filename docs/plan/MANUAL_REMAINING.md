# Vertiege audit — what you do manually

Code and Supabase migrations in the repo are applied where possible. These items need **you** (dashboard, console, or device).

---

## Supabase Free plan — what that changes

You are on the **Free** plan. Several dashboard toggles are **greyed out** (entitlement-gated). That is expected, not a misconfiguration.

| Audit item | Free plan | What to do instead |
|------------|-----------|-------------------|
| **Leaked password protection** (HaveIBeenPwned) | **Pro+ only** — toggle disabled | Use strong password rules below; accept advisor warning until upgrade |
| **Migrations / RLS / storage policies / RPC revoke** | Works on Free | Already applied remotely for this project |
| **Performance advisors** | Usually visible | Review when you have time; index fixes still apply via SQL migrations |
| **Custom SMTP, SSO, advanced Auth** | Paid | Email auth via Supabase default is fine for dev |
| **Project pause** | Free projects pause after ~7 days inactive | Open dashboard or run a query to wake before testing |

**Security advisor** may still show `auth_leaked_password_protection` on Free. Treat it as **known, accepted** until Pro, not a blocker for dev APKs.

### Free-tier Auth hardening (do these — they are not greyed out)

**Where:** [Auth → Providers → Email](https://supabase.com/dashboard/project/wjaphoaxalvgjnrwqjwe/auth/providers)

1. **Minimum password length** — 8 or higher (12+ if you can ask users).
2. **Required characters** — require digits + upper + lower + symbols.
3. Optional: tighten sign-up rate limits under **Auth → Rate limits** if exposed on your plan.

Docs: [Password security](https://supabase.com/docs/guides/auth/password-security) (HIBP section notes Pro-only).

---

## Required before production APK

### 1. ~~Leaked password protection~~ — skip on Free (Pro feature)

**Not available on Free.** Do not spend time hunting a disabled toggle.

When you upgrade to Pro, enable **Prevent use of leaked passwords** in the same Email provider screen.

---

### 2. Manual UAT on a real device

Walk through `docs/plan/2026-05-21-full-app-audit.md` → **Manual UAT checklist** (Nexus routes, world manage tabs, achievements proof, DM, league XP, sign-out).

**Why:** Many fixes are navigation/state; only a full tap-through confirms no white screens or wrong routes.

---

### 3. Firebase — verify push (Android already in repo)

**Package / bundle ID:** `com.vertiege` (Android `applicationId`, iOS/macOS bundle)

**After renaming the package you must re-register Firebase & Google OAuth:**

1. [Firebase Console](https://console.firebase.google.com/) → **veritage** → **Add app** → Android with package `com.vertiege` (and iOS with bundle `com.vertiege` if you ship iOS).
2. Download new `google-services.json` → replace `android/app/google-services.json`.
3. Run `dart run flutterfire configure` (optional) to refresh `lib/firebase_options.dart` app IDs.
4. [Google Cloud](https://console.cloud.google.com/) → OAuth → Android client with package `com.vertiege` + debug SHA-1.
5. Uninstall legacy app if present: `adb uninstall com.imma96.virtual_status_worlds` then install `com.vertiege`.

**Do (only if push/Crashlytics fail on device):** send a test FCM after step 1–2.

---

## Recommended (not blocking dev builds)

### 4. Firebase AI / Gemini (optional — not used for achievements)

Skip unless you add a **non-achievement** feature (e.g. content moderation, banner generation). Achievement proofs are **manual-only** (see §5).

---

### 5. Achievement proof review (manual only)

**Product decision:** All proof-based achievements use **manual verifier review** — no AI auto-approve path.

| Feature | What to do |
|--------|------------|
| Achievement proofs | Staff use **verifier portal** (`docs/VERIFIER_PORTAL.md`); add verifier emails in Supabase / `VERIFIER_ADMIN_EMAILS` |
| Chat/post moderation | Optional later (OpenAI Moderation, Perspective, Edge Function) — separate from achievements |

**In app today:** Submissions stay `submitted` until a verifier approves or rejects; in-app auto-unlocks apply only to configured in-app achievements (posts, streaks, etc.).

---

### 6. Asset pipeline (badges / manifest)

**Where:** `docs/assets/CODEX_START_HERE.md` and `docs/assets/image-manifest.json`.

**Do:** Promote generated assets per manifest (~64 pending) so UI stops falling back to generic icons.

---

### 7. Supabase performance advisors

**Where:** Dashboard → Database → Advisors (Performance), or MCP `get_advisors(performance)` on project `wjaphoaxalvgjnrwqjwe`.

**Do:** Review missing indexes / RLS initplan warnings in a dedicated pass (large list; not applied automatically).

---

### 8. `pg_net` in public schema (low priority)

**Where:** Supabase Database → Extensions.

**Do:** Move `pg_net` out of `public` per [Supabase linter guidance](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public) if you use it in production.

---

## Already done in repo / remote (no action)

- Phase 0–2 navigation, Identity/Nexus/More, Forui hubs, session reset, deep links
- Phase 1 RPC hardening + notifications policy (remote)
- Storage listing policies + legacy policy drops (remote)
- Achievement proof: manual review only (`AiVerificationService` removed)
- Dead widgets removed (`achievement_grid`, `world_hub_tab`, `feed_preview_card`, `achievement_card`)
- Provider errors: resident, achievements, chat DMs, post feed banner on Nexus, alerts retry banner
- RPC: write functions revoked from `PUBLIC`/`anon`; only RLS helper + trigger functions remain for anon (expected)

---

## Optional local commands

```bash
# Verify analyzer clean enough for CI
dart analyze lib

# Push any new migrations if you work offline first
supabase db push
```

Project ref: **wjaphoaxalvgjnrwqjwe**
