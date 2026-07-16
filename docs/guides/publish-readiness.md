# Publish readiness — operator checklist

Code gates for closed beta → public store. Complete the **operator** rows before App Store / Play submission.

## Shipped in app (S10.21+)

| Item | Status |
|------|--------|
| Account deletion Edge Function (`delete-account`) | ✅ **deployed** to project `wjaphoaxalvgjnrwqjwe` |
| Settings → Privacy / Terms / Licenses hub | ✅ |
| Login + signup ToS / Privacy links | ✅ |
| Hosted legal pages | ✅ https://veritage.web.app/privacy.html · terms.html |
| iOS `voip` background mode removed (no CallKit) | ✅ |
| Campfire / economy / IAP purchases off by default | ✅ |
| UGC report: posts, chat, comments, profiles | ✅ |
| Settings → Send feedback (mailto) | ✅ |
| Comment deep-link fetch + DM roomId null guard | ✅ |

## Operator (blocks **public** App Store / Play — not closed beta)

- [x] `supabase functions deploy delete-account`
- [x] Host Privacy Policy + Terms
- [ ] App Store Connect / Play Console: privacy nutrition / Data Safety, screenshots, age rating
- [ ] App Review test account + notes (UGC reporting path, account deletion steps)
- [ ] Device UAT: `docs/guides/device-uat.md` + `docs/operations/uat/api30-release-smoke.md` signed
- [ ] Enable `receipt_edge_verify` + live store APIs only after sandbox IAP passes
- [ ] Enable `campfire_enabled` only after voice UAT

## Closed beta vs public

**Closed beta / TestFlight / Play internal:** code + legal + deletion are ready. Run device UAT, then ship.

**Public 1.0:** complete remaining operator checklist; do not flip IAP/Campfire without verification.
