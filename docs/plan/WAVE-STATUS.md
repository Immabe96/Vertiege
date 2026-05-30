# Wave status — 2026-05-30 (updated)

Cross-reference: [`PLAN.md`](../../PLAN.md) (7–12), [`PERFECTION-BACKLOG.md`](./PERFECTION-BACKLOG.md) (0–6).

**Apply new SQL before device testing:**  
`20260530150000_lounge_campfire_channels.sql`, `20260530160000_waves_8_11_completion.sql`

---

## Waves 0–6

| Wave | Status |
|------|--------|
| 0–5 | **Done** — 191 tests green |
| 6 UAT sign-off | **Open** — run checklists on device |

---

## Waves 7–12

| Wave | Status | Delivered |
|------|--------|-----------|
| **7** Voice / Lounge | **Done (code)** | Routing, gates, tools, LiveKit validation, channel seed |
| **8** Composer | **Done (core)** | `PostInput` + `PostCapabilities`; `create_post` RPC enforced; polls via RPC still separate |
| **9** Commerce | **Done (MVP)** | `verify_subscription_purchase`, `purchase_cosmetic_with_coins`, pay-to-win SKUs disabled in shop |
| **10** Governance | **Partial** | Manage hub, council queue UI, treasury withdrawal proposals; job/rank proposals schema only |
| **11** Progression | **Partial** | `scope` on challenges, leaderboard opt-out, profile `display_title`; season cohorts not built |
| **12** Release | **Partial** | Invite deep links; Forui gaps remain; API 30 smoke not run here |

---

## Follow-ups (product / infra)

1. **Store receipt validation** — current RPC dedupes `purchase_token` but does not call Apple/Google APIs.
2. **Job / rank approval** — extend `governance_proposals` + UI beyond treasury.
3. **Season challenges** — cohort tables + UI (archive league SQL exists).
4. **Poll composer** — dedicated RPC or extend `create_post` to accept polls with veteran check.
5. **Wave 6** — full device pass + Android 11 emulator.
