# verify-subscription-purchase

Edge function scaffold for Wave 9 subscription receipts. Ships in **stub** mode: validates the caller and delegates to `verify_subscription_purchase` (no Apple/Google API calls).

## Deploy

```bash
supabase functions deploy verify-subscription-purchase --no-verify-jwt
```

JWT is validated inside the function via `auth.getUser()`. Prefer `--no-verify-jwt` only if your gateway already forwards the user `Authorization` header (default Supabase behavior).

## Environment variables

| Secret | Required | Purpose |
|--------|----------|---------|
| `STORE_RECEIPT_VERIFY_MODE` | No (default `stub`) | `stub` = RPC only; `live` = future store API path |
| `SUPABASE_URL` | Auto | Injected by Supabase |
| `SUPABASE_ANON_KEY` | Auto | Injected by Supabase |
| `APPLE_ISSUER_ID` | Live only | App Store Connect |
| `APPLE_KEY_ID` | Live only | API key id |
| `APPLE_PRIVATE_KEY` | Live only | `.p8` contents |
| `APPLE_BUNDLE_ID` | Live only | e.g. `com.vertiege` |
| `GOOGLE_PLAY_PACKAGE_NAME` | Live only | Android `applicationId` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Live only | Service account JSON |

Set secrets:

```bash
supabase secrets set STORE_RECEIPT_VERIFY_MODE=stub
```

## Rate limiting (Wave 13)

When `SUPABASE_SERVICE_ROLE_KEY` is set, each authenticated user is limited to **30** verification POSTs per hour via `assert_edge_rate_limit` (migration `20260613130000_wave13_rate_limits_rls.sql`). Returns HTTP **429** when exceeded.

---

## Health check

```bash
curl "$SUPABASE_URL/functions/v1/verify-subscription-purchase" \
  -H "apikey: $SUPABASE_ANON_KEY"
```

Returns `mode`, `live_ready`, and `env_documentation`.

## Invoke (stub)

```bash
curl -X POST "$SUPABASE_URL/functions/v1/verify-subscription-purchase" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": "subscription_patrician",
    "purchase_token": "…",
    "platform": "ios",
    "store_payload": "…"
  }'
```

## Flutter

Enable when ready:

```dart
// Remote Config key: receipt_edge_verify = true
// or --dart-define=RECEIPT_EDGE_VERIFY=true
```

See `SubscriptionService.verifyPurchase` and [store-receipt-hardening.md](../../../docs/operations/store-receipt-hardening.md).
