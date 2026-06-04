# Store receipt hardening (post-MVP)

Current behavior: the app calls `verify_subscription_purchase` with platform, purchase token, and optional receipt digest. The RPC dedupes tokens and grants tier — it does **not** call Apple App Store Server API or Google Play Developer API.

## Edge function (scaffold)

Deploy stub (RPC delegate, documents env vars):

```bash
supabase functions deploy verify-subscription-purchase
supabase secrets set STORE_RECEIPT_VERIFY_MODE=stub
```

Details: [supabase/functions/verify-subscription-purchase/README.md](../../supabase/functions/verify-subscription-purchase/README.md).

Health: `GET /functions/v1/verify-subscription-purchase` returns `mode` and `env_documentation`.

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
