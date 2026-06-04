# Vertiege documentation

Start here. All docs follow [documentation standards](meta/documentation-standards.md).

## Quick links

| I want to… | Read |
|------------|------|
| Run the app locally | [getting-started/local-setup.md](getting-started/local-setup.md) |
| Branch workflow & CI APKs | [guides/development-workflow.md](guides/development-workflow.md) |
| Closed beta (Play / TestFlight) | [guides/closed-beta.md](guides/closed-beta.md) |
| Device UAT & APK from Actions | [guides/device-uat.md](guides/device-uat.md) |
| Supabase + Firebase setup | [guides/firebase-and-supabase.md](guides/firebase-and-supabase.md) |
| Design system (current) | [reference/design-system.md](reference/design-system.md) |
| Quiet UX (no clutter) | [guides/quiet-ux-principles.md](guides/quiet-ux-principles.md) |
| Product roadmap & waves | [product/roadmap.md](product/roadmap.md) · [planning/wave-status.md](product/planning/wave-status.md) |
| UAT issue log | [operations/uat/issue-log.md](operations/uat/issue-log.md) |
| Explore the codebase in Cursor | [guides/codebase-map.md](guides/codebase-map.md) |

## Structure

```
docs/
├── README.md                 ← you are here
├── meta/                     ← how we document
├── getting-started/          ← tutorials (first run)
├── guides/                   ← how-to guides
├── reference/                ← stable facts & catalogs
├── product/                  ← roadmap, vision, planning
├── operations/               ← beta testers, UAT
├── assets/                   ← image manifest, licenses (not prose guides)
└── archive/                  ← historical audits & old plans
```

## Product & planning

- [Roadmap](product/roadmap.md) — completion plan, waves 7–12, locked decisions
- [Wave status](product/planning/wave-status.md) — current wave checklist
- [Perfection backlog](product/planning/perfection-backlog.md) — polish waves 0–6
- [Manual remaining](product/planning/manual-remaining.md) — dashboard / infra tasks
- [Vision](product/vision/) — worlds, gamification, onboarding, channels

## Guides (how-to)

- [Development workflow](guides/development-workflow.md)
- [Closed beta](guides/closed-beta.md)
- [Device UAT](guides/device-uat.md)
- [Firebase & Supabase hybrid](guides/firebase-and-supabase.md)
- [Firebase console setup](guides/firebase-console-setup.md)
- [Push notifications](guides/notifications.md)
- [Verifier portal](guides/verifier-portal.md)
- [Assets & image pipeline](guides/assets-and-images.md)
- [Codebase map (Understand-Anything)](guides/codebase-map.md)

## Reference

- [Design system](reference/design-system.md)
- [Achievements catalog](reference/achievements-catalog.md)
- [Android package ID & OAuth](reference/android-package-id.md)

## Operations

- [Beta tester guide](operations/beta/tester-guide.md)
- [UAT issue log](operations/uat/issue-log.md)
- [Perfection smoke checklist](operations/uat/perfection-smoke-checklist.md)
- [Wave 4 device checklist](operations/uat/wave-4-device-checklist.md)

## Archive

Historical material only — [archive/README.md](archive/README.md).

## Repo root pointers

- [README.md](../README.md) — project entry
- [PLAN.md](../PLAN.md) → redirects to [product/roadmap.md](product/roadmap.md)
- [releases/README.md](../releases/README.md) — APK releases
