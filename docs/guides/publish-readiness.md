# Publish readiness — operator checklist

Code gates for closed beta → public store. Complete the **operator** rows before App Store / Play submission.

## Shipped in app (S10.21)

| Item | Status |
|------|--------|
| Account deletion Edge Function (`delete-account`) | ✅ **deployed** to project `wjaphoaxalvgjnrwqjwe` |
| Settings → Privacy / Terms / Licenses hub | ✅ |
| Login + signup ToS / Privacy links | ✅ |
| iOS `voip` background mode removed (no CallKit) | ✅ |
| Campfire / economy / IAP purchases off by default | ✅ |
| Hosted legal URLs via RC `privacy_policy_url` / `terms_of_service_url` | ✅ live at https://veritage.web.app/privacy.html + terms.html |

## Operator (blocks public listing)

- [x] `supabase functions deploy delete-account --no-verify-jwt` (done 2026-07-16)
- [x] Host Privacy Policy + Terms (Firebase Hosting `veritage.web.app`, 2026-07-16)
- [ ] App Store Connect / Play Console: privacy nutrition / Data Safety, screenshots, age rating
- [ ] App Review test account + notes (UGC reporting path, account deletion steps)
- [ ] Device UAT: `docs/guides/device-uat.md` + `docs/operations/uat/api30-release-smoke.md` signed
- [ ] Enable `receipt_edge_verify` + live store APIs only after sandbox IAP passes
- [ ] Enable `campfire_enabled` only after voice UAT

## Closed beta vs public

**Closed beta:** ship TestFlight / Play internal with current flags.

**Public 1.0:** complete operator checklist; do not flip IAP/Campfire without verification.
