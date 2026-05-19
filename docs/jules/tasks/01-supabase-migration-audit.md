# Jules Task 01: Supabase Migration Audit And Repair

## Goal
Make Supabase migrations deterministic, safe to apply, and ready for fresh/existing projects.

## Scope
Allowed to touch:
- `supabase/migrations/**`
- `docs/audits/jules-full-app-audit.md`

Do not touch Flutter/Dart files in this task.
Do not deploy to remote Supabase.
Do not require Docker.

## Required Work
- Inspect all migration filenames and fix duplicate version prefixes. Several files currently share `20260516`; every migration version prefix must be unique and ordered.
- Ensure migrations can be applied once on a fresh project without filename/version ambiguity.
- Ensure existing projects can apply any new migration safely without destructive resets.
- Audit RLS policies for posts/feed, comments, reactions, bookmarks, world memberships, channels, channel reads, polls, marketplace, treasury, notifications, and chat.
- Add or adjust migrations only where a concrete issue is found.
- Add indexes/constraints only where missing and useful:
  - unique membership per user/world,
  - unique bookmark per user/post,
  - unique reaction per user/post/reaction type where applicable,
  - channel lookup by world/default/name,
  - post feed queries by world/created_at/author.
- Update `docs/audits/jules-full-app-audit.md` with findings and fixes.

## Verification
Run:
- `npx supabase --version`
- Static SQL review of migration order and policy definitions.
- If Supabase is not linked or Docker is unavailable, document the exact commands that could not run and why.

Do not open a PR if migration filenames are still ambiguous.
