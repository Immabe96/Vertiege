# Supabase Migration Cleanup - 2026-05-19

## Remote Migration History Checked

Remote Supabase project `wjaphoaxalvgjnrwqjwe` reports these relevant applied migrations:

- `20260519144052_phase2_rls_policy_fix`
- `20260519144556_seed_default_world_channels`
- `20260519145412_chat_persistence_hardening`
- `20260519145904_grant_immabe_superuser`

The local high-risk files originally used short names such as `20260519_002_phase2_rls_policy_fix.sql`. They were renamed to match the remote migration versions so local history and remote history are easier to compare.

## Active Migration Files Kept

- `supabase/migrations/20260519144052_phase2_rls_policy_fix.sql`
- `supabase/migrations/20260519144556_seed_default_world_channels.sql`
- `supabase/migrations/20260519145412_chat_persistence_hardening.sql`
- `supabase/migrations/20260519145904_grant_immabe_superuser.sql`
- `supabase/migrations/20260519193753_fix_world_members_policy_recursion.sql`

## Known Unsafe Migration

`20260519144052_phase2_rls_policy_fix.sql` is already applied remotely but contains a recursive `world_members` SELECT policy:

- It creates `"Members can read world members"` on `public.world_members`.
- That policy queries `public.world_members` inside a `public.world_members` policy.
- This is the likely source of the installed-app error: `infinite recursion detected in policy for relation "world_members"`, code `42P17`.

Because it is already applied remotely, do not rewrite it in place. Keep it as historical context and apply a corrective migration after it.

## Corrective Migration

`supabase/migrations/20260519193753_fix_world_members_policy_recursion.sql` supersedes the unsafe policy by:

- dropping `"Members can read world members"`,
- replacing self-referential membership policies,
- adding `private.has_world_membership(world_id, resident_id)`,
- using that helper in `world_members`, `posts`, `channels`, and `channel_messages` policies.

## Follow-Up For The Implementing Agent

- `20260519193753_fix_world_members_policy_recursion.sql` has been applied to remote Supabase. Re-run the checks below before debugging Nexus or channel UI.
- Verify Nexus feed no longer returns `42P17`.
- Verify Immabe can read all worlds, channels, posts, and residents.
- Verify a regular authenticated user can read only joined-world content.
