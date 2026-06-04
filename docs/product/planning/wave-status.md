# Wave status — 2026-06-04 (updated)

Cross-reference: [`roadmap.md`](../roadmap.md) (7–12), [`perfection-backlog.md`](perfection-backlog.md) (0–6).

**Remote migrations (linked project):**  
`20260531165805_integrations_fts_stream` (fetched from cloud),  
`20260601120000_award_activity_xp_guard`,  
`20260604143000_governance_job_rank_and_profile_label` (profile labels, job/rank governance).

---

## Waves 0–6

| Wave | Status |
|------|--------|
| 0–5 | **Done** — 191 tests green |
| 6 UAT sign-off | **In progress** — device UAT positive; formal checklist optional |

---

## Waves 7–12

| Wave | Status | Delivered |
|------|--------|-----------|
| **7** Voice / Lounge | **Done (code)** | Routing, gates, tools, LiveKit validation, channel seed |
| **8** Composer | **Done (core)** | `PostInput` + `PostCapabilities`; `create_post` RPC enforced; polls via RPC still separate |
| **9** Commerce | **Done (MVP)** | `verify_subscription_purchase`, `purchase_cosmetic_with_coins`, pay-to-win SKUs disabled in shop |
| **10** Governance | **Partial** | Council queue for treasury, role posts, rank changes; council/sovereign execute immediately |
| **11** Progression | **Partial** | `scope` on challenges, leaderboard opt-out, profile `display_title`; season cohorts not built |
| **12** Release | **Partial** | Forui create-world/shop/settings; post deep links; Campfire mini-bar; season guide collapsed |

---

## Follow-ups (product / infra)

1. **Store receipt validation** — current RPC dedupes `purchase_token` but does not call Apple/Google APIs.
2. **Job / rank approval** — RPC + council queue UI shipped; polish copy and audit log surfacing.
3. **Season challenges** — cohort tables + UI (archive league SQL exists).
4. **Poll composer** — dedicated RPC or extend `create_post` to accept polls with veteran check.
5. **Wave 6** — full device pass + Android 11 emulator.
