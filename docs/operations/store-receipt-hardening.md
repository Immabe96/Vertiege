# Store receipt hardening (post-MVP)

Current behavior: the app calls `verify_subscription_purchase` with platform, purchase token, and optional receipt digest. The RPC dedupes tokens and grants tier — it does **not** call Apple App Store Server API or Google Play Developer API.

## Before production subscriptions

1. **Apple** — App Store Server API (or legacy verifyReceipt) in a Supabase Edge Function; store `APPLE_ISSUER_ID`, key ID, and private key as secrets.
2. **Google** — Play Developer API `purchases.subscriptionsv2.get`; service account JSON as secret.
3. **RPC** — On success from store API, then insert `subscription_purchases` and update `profiles.subscription_tier` (keep dedupe on `purchase_token`).
4. **Restore** — Client already re-verifies each restored SKU via RPC; edge function should accept restore tokens the same as purchase.
5. **Sandbox** — TestFlight / Play internal testing against staging project before prod keys.

## Client (already shipped)

- `SubscriptionService.verifyPurchase` sends `p_platform` and `p_store_payload`.
- Restore purchases loops `StoreService.restorePurchasesAndWait()` then verifies each subscription.

## Dashboard (manual)

- Supabase **Pro**: enable leaked-password protection (HIBP) under Auth settings.
