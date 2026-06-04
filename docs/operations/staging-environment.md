# Staging Supabase environment (Wave 21)

Use a **separate** Supabase project for migrations and soak tests before production.

## Setup

1. Create a new project in the Supabase dashboard (name e.g. `vertiege-staging`).
2. Store `SUPABASE_URL` and `SUPABASE_ANON_KEY` in your team password manager — not in git.
3. Link CLI when pushing migrations:

```bash
cd /Users/immabe/code/Vertiege
supabase link --project-ref <staging-ref>
supabase db push
```

4. Point a local `.env.staging` (gitignored) at staging for device QA:

```bash
SUPABASE_URL=https://<staging-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

## Soak checklist (48h gate)

- [ ] `scheduled_posts` publishes within 1 minute of `scheduled_for`
- [ ] `list_posts_cursor` on a world with 500+ posts (no timeout)
- [ ] Notification toggles round-trip via `notification_preferences`
- [ ] No regression on voice, commerce, governance RPCs

## Switching back to production

Re-link the production project ref before `db push` to prod, or use CI with explicit `SUPABASE_ACCESS_TOKEN` + project ref per environment.
