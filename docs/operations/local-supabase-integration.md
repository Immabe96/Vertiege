# Local Supabase integration tests

Plan for CI and developer machines to run RPC/RLS checks against a **local** Supabase stack (Wave 13 doc; full job optional until Wave 21).

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) running  
- [Supabase CLI](https://supabase.com/docs/guides/cli) (`supabase --version`)  
- Project linked or use local-only (`supabase init` already in repo)

---

## Start local stack

```bash
cd /path/to/Vertiege
supabase start
supabase status   # copy API URL and anon key
```

Apply migrations:

```bash
supabase db reset   # destructive — local only
# or
supabase migration up
```

---

## Point the Flutter app at local

```bash
printf 'SUPABASE_URL=http://127.0.0.1:54321\nSUPABASE_ANON_KEY=<anon from supabase status>\n' > .env
flutter run
```

Use a test user from Studio → Authentication, or sign up with email (Inbucket: http://127.0.0.1:54324).

---

## Smoke scripts (remote or local)

| Script | Purpose |
|--------|---------|
| `scripts/release_smoke_api30.sh` | Device/emulator API 30 release smoke |
| `curl` health on edge functions | See [store-receipt-hardening.md](store-receipt-hardening.md) |

Suggested local RPC checks (manual until automated):

```bash
# After sign-in JWT in shell:
# verify_subscription_purchase (stub), create_world_poll, ensure_season_cohort_membership
```

---

## CI direction (Wave 21)

1. Job `integration-supabase`: `supabase start` + `supabase db reset` + `flutter test test/integration/` (folder TBD).  
2. Seed `test/fixtures/residents.sql` via service role in job setup.  
3. Do **not** use production `SUPABASE_URL` in CI for write tests.

---

## Staging project (Wave 21)

See **[staging-environment.md](staging-environment.md)** for setup, soak checklist, and env switching. Create a second Supabase project before pushing `20260621+` platform migrations.
