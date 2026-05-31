# Supabase audit — 2026-05-28

**Project:** `wjaphoaxalvgjnrwqjwe`  
**CLI:** `supabase db advisors --linked`

## Actions taken

| Finding | Fix |
|---------|-----|
| `upsert_dm_typing` / `prune_dm_typing` callable by `anon` | Migration `20260528130000_security_rpc_anon_revoke_sweep.sql` — re-ran DEFINER RPC revoke sweep; `prune_dm_typing` limited to `service_role` only |
| `dm_typing` table + RLS | Applied in `20260528120000_dm_typing_persistence.sql` (prior) |

## Remaining (accepted / manual)

| Level | Issue | Notes |
|-------|-------|-------|
| WARN | `auth_leaked_password_protection` | Pro+ dashboard toggle — see `docs/plan/MANUAL_REMAINING.md` |
| WARN | `extension_in_public` (`pg_net`) | Required for webhooks; accepted |
| WARN | `function_search_path_mutable` | `tier_level_from_xp`, `world_standing_level` — low priority |
| WARN | `authenticated_security_definer_function_executable` | Expected for RPCs; anon revoked on mutators |
| WARN | `anon_security_definer_function_executable` | Residual on RLS helper RPCs whitelisted in sweep |

**ERROR-level:** 0

## Client / deploy

- Hybrid typing client shipped with `typing_persistence_service.dart`
- Re-run advisors after major migration batches: `supabase db advisors --linked --type security`
