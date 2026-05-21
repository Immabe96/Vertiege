# Security advisor — 2026-05-21

**Project:** `wjaphoaxalvgjnrwqjwe`  
**Source:** Supabase MCP `get_advisors` (security)

## Summary

| Level | Count (unique issue types) |
|-------|------------------------------|
| ERROR | 0 |
| WARN | 6 categories (~70 lint rows due to per-function duplication) |

No critical ERROR-level findings. Remaining items are hardening and policy tuning.

---

## Findings

### 1. Extension in public schema

- **Issue:** `pg_net` in `public`
- **Remediation:** [Extension in public](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public)
- **Note:** Often acceptable for Edge/webhooks; move only if you do not rely on default `pg_net` placement.

### 2. Permissive RLS — `debug_logs`

- **Issue:** `debug_logs_authenticated_insert` uses `WITH CHECK (true)` for authenticated inserts
- **Remediation:** [Permissive RLS](https://supabase.com/docs/guides/database/database-linter?lint=0024_permissive_rls_policy)
- **Note:** Intentional for client diagnostics; tighten to `resident_id = auth.uid()::text` when push debugging is stable.

### 3. Public bucket listing — `avatars`, `post-media`

- **Issue:** Broad SELECT policies allow listing all objects in bucket
- **Remediation:** [Public bucket listing](https://supabase.com/docs/guides/database/database-linter?lint=0025_public_bucket_allows_listing)
- **Repo:** Partially addressed in `20260520130000_security_corrective.sql` (on remote). Re-run advisor after next storage policy migration if still WARN.

### 4. SECURITY DEFINER callable by `anon` / `authenticated`

- **Issue:** Many RPCs and helpers (e.g. `add_comment`, `create_world_full`, `is_world_member`, `toggle_reaction`, …) executable via PostgREST
- **Remediation:** [Anon DEFINER](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable) · [Authenticated DEFINER](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable)
- **Repo:** `20260520130000_security_corrective.sql` revokes **mutating** RPCs from `anon`; **RLS helper** functions (`is_world_member`, `is_superuser`, …) may still warn because policies reference them — review case-by-case before revoking.
- **Next migration:** Revoke `anon` on remaining mutators; grant `authenticated` only; keep helpers as `SECURITY DEFINER` with fixed `search_path` but restrict `EXECUTE` to `authenticated` + `service_role` where possible.

### 5. Leaked password protection disabled

- **Issue:** HaveIBeenPwned check off for Auth
- **Remediation:** [Password security](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)
- **Manual:** Dashboard → Authentication → Settings → enable leaked password protection.

---

## Verified healthy

- `device_tokens`: **3 rows** (push registration working as of 2026-05-21)
- `debug_logs`: 22 rows (diagnostics active)
- RLS on `device_tokens`: own-row policies (`20260520121347` on remote)

---

## Recommended order

1. Enable leaked password protection (dashboard, 2 min)
2. New migration: complete anon revoke for remaining mutating RPCs + narrow `debug_logs` insert
3. Storage policy pass for avatars/post-media (no public list)
4. Re-run `get_advisors` security after deploy
