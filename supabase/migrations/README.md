# Supabase migrations

## Source of truth

**Remote project `wjaphoaxalvgjnrwqjwe`** is production. Local files here must match applied remote versions before any `db push`.

Check drift:

```bash
npx supabase migration list --linked
```

## Layout

| Path | Purpose |
|------|---------|
| `supabase/migrations/*.sql` | Migrations for the **linked remote** project |
| `supabase/migrations_archive/fresh_project_only/` | Full-schema bootstrap for **new** Supabase projects only — never apply to remote |

## Remote-only history (May 2026-05-12)

Versions `20260512070535` … `20260513144900` were applied on remote before this repo’s migration folder was realigned. They are **not** duplicated as SQL files here. On a fresh clone, use:

```bash
npx supabase migration repair --status applied --linked <version>
```

for each remote-only version listed in [docs/audits/2026-05-21-migration-reconciliation.md](../docs/audits/2026-05-21-migration-reconciliation.md).

## Rules

1. Do **not** rewrite migrations already applied on remote.
2. Add **corrective** migrations with new timestamps for fixes.
3. Do **not** run `db push` when `migration list` shows local/remote mismatch.
4. Prefer `npx supabase db pull` or recovering SQL from git when remote has a version the repo lacks.
