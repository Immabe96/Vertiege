# delete-account

Authenticated Edge Function that deletes a resident's account: best-effort cleanup of user-owned rows, then removal from Supabase Auth.

`profiles.id` is **TEXT** and matches `auth.users.id` (UUID as text). The Flutter app uses `resident.id` from `profiles`, which is the same value as the signed-in user's auth id.

## Deploy

```bash
supabase functions deploy delete-account --no-verify-jwt
```

JWT is validated inside the function via `auth.getUser()`. Use `--no-verify-jwt` so the gateway forwards the caller's `Authorization: Bearer <user_jwt>` header (same pattern as `verify-subscription-purchase`).

## Environment variables

| Secret | Required | Purpose |
|--------|----------|---------|
| `SUPABASE_URL` | Auto | Injected by Supabase |
| `SUPABASE_ANON_KEY` | Auto | Injected by Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Yes | Admin deletes + `auth.admin.deleteUser` |

## Rate limiting

When `assert_edge_rate_limit` is available (migration `20260613130000_wave13_rate_limits_rls.sql`), each user is limited to **5** delete attempts per hour (`scope: delete_account`). Returns HTTP **429** when exceeded. If the RPC is missing, the limit is skipped.

## Cleanup order (best-effort)

1. `device_tokens` where `resident_id = userId`
2. `notifications` where `recipient_id = userId`
3. `profiles` where `id = userId`
4. `auth.admin.deleteUser(userId)`

Missing tables or non-fatal delete errors are logged and do not abort the request; auth deletion failure returns **500**.

## Invoke

```bash
curl -X POST "$SUPABASE_URL/functions/v1/delete-account" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json"
```

Success: `{ "success": true }`

## Flutter

Settings → **Delete My Account** calls `client.functions.invoke('delete-account')` then signs out locally.
