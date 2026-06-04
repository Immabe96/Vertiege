# Wave status — 2026-06-05 (updated)

Cross-reference: [`roadmap.md`](../roadmap.md) (7–12), [`perfection-backlog.md`](perfection-backlog.md) (0–6).

**Remote migrations (linked project):**  
`20260531165805_integrations_fts_stream` (fetched from cloud),  
`20260601120000_award_activity_xp_guard`,  
`20260604143000_governance_job_rank_and_profile_label` (profile labels, job/rank governance),  
`20260605150000_subscription_verify_platform` (platform + receipt digest),  
`20260606120000_poll_rpc_season_cohorts` (create_world_poll RPC, season cohort tables).

---

## Waves 0–6

| Wave | Status |
|------|--------|
| 0–5 | **Done** — 197 tests green |
| 6 UAT sign-off | **In progress** — device UAT positive; formal checklist optional |

---

## Waves 7–12

| Wave | Status | Delivered |
|------|--------|-----------|
| **7** Voice / Lounge | **Done (code)** | Routing, gates, tools, LiveKit validation, channel seed |
| **8** Composer | **Done (core)** | `PostInput` + `PostCapabilities`; `create_post` RPC; `create_world_poll` RPC with veteran gate |
| **9** Commerce | **Done (MVP)** | `verify_subscription_purchase`, `purchase_cosmetic_with_coins`, pay-to-win SKUs disabled in shop |
| **10** Governance | **Partial** | Council queue; governance decisions in realm audit with resident names |
| **11** Progression | **Partial** | Challenge `scope`; season cohort membership + UI; council can add `scope=season` challenges |
| **12** Release | **Partial** | Forui create-world/shop/settings; post deep links; Campfire mini-bar; invite auto-redeem after auth; `scripts/release_smoke_api30.sh` |

---

## Follow-ups (product / infra)

1. **Store receipt validation** — RPC records platform + SHA-256 receipt digest and enforces token shape; Apple/Google API verify still TODO for production hardening.
2. **Job / rank approval** — immediate council execute paths could still log to audit (optional).
3. **Season challenges** — seed example `scope=season` challenges per world (ops/SQL).
4. **Poll composer** — done via `create_world_poll`; post feed still blocks inline polls.
5. **Wave 6** — full device pass + Android 11 emulator.
