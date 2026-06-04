# Store receipt hardening (post-MVP)

Current behavior: the app calls `verify_subscription_purchase` with platform, purchase token, and optional receipt digest. The RPC dedupes tokens and grants tier — it does **not** call Apple App Store Server API or Google Play Developer API.

## Edge function (scaffold)

**Status (project `wjaphoaxalvgjnrwqjwe`):** deployed `verify-subscription-purchase` (ACTIVE), secret `STORE_RECEIPT_VERIFY_MODE=stub`, health `GET` returns `"mode":"stub"`.

Deploy / rotate:

```bash
supabase login   # paste sbp_… token in terminal only — never in chat
supabase functions deploy verify-subscription-purchase
supabase secrets set STORE_RECEIPT_VERIFY_MODE=stub
```

Details: [supabase/functions/verify-subscription-purchase/README.md](../../supabase/functions/verify-subscription-purchase/README.md).

Health (uses `.env` anon key):

```bash
curl -sS "$SUPABASE_URL/functions/v1/verify-subscription-purchase" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

## Before production subscriptions

1. Implement **live** path in the edge function (Apple App Store Server API + Google Play `purchases.subscriptionsv2.get`).
2. Set secrets listed in the function README (`APPLE_*`, `GOOGLE_PLAY_*`).
3. Set `STORE_RECEIPT_VERIFY_MODE=live` and enable client flag `receipt_edge_verify` (Remote Config) or `--dart-define=RECEIPT_EDGE_VERIFY=true`.
4. On store API success, call `verify_subscription_purchase` (dedupe on `purchase_token`).
5. **Sandbox** — TestFlight / Play internal testing before prod keys.

## Client (already shipped)

- Default: direct RPC via `SubscriptionService.verifyPurchase`.
- Optional: edge function when `FeatureFlags.receiptEdgeVerify` is true.
- Restore purchases loops `StoreService.restorePurchasesAndWait()` then verifies each subscription.

## Dashboard (manual)

- Supabase **Pro**: enable leaked-password protection (HIBP) under Auth settings.
