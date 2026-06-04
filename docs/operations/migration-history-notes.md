# Migration history notes

## `20260604142207` vs `20260604143000`

Both filenames exist in the repo history:

| Migration | Role |
|-----------|------|
| `20260604142207_governance_job_rank_and_profile_label.sql` | Placeholder scaffold (no-op body) |
| `20260604143000_governance_job_rank_and_profile_label.sql` | **Authoritative** — profile labels, job/rank governance |

If your remote database applied **only** `20260604142207` from an older push, ensure `20260604143000` is also applied (`supabase migration list`). Re-running the placeholder is safe; logic lives in `143000`.

## Wave 21 platform batch

`20260621120000_platform_scheduled_prefs_indexes.sql` adds:

- `scheduled_posts` + `publish_due_scheduled_posts()` (+ pg_cron when available)
- `notification_preferences` + get/upsert RPCs
- `list_posts_cursor` keyset RPC
- `create_post` scheduling (future `p_scheduled_for`)
- Composite indexes on `world_members` and `posts`

Push to **staging** first per [staging-environment.md](staging-environment.md).
