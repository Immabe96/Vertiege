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
| Active engineering plan | [../PLAN.md](../PLAN.md) |
| Quiet UX (no clutter) | [guides/quiet-ux-principles.md](guides/quiet-ux-principles.md) |
| Archived planning (DCX, waves, backlog) | [archive/planning/](archive/planning/) |
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
└── archive/                  ← consolidated legacy plans & audits
```

## Product & planning

- [**PLAN.md**](../PLAN.md) — canonical active plan (social stack waves S1–S3)
- [Archived planning](archive/planning/) — DCX redesign, wave status, perfection backlog, waves 13–22, roadmap, UI migration
- [Legacy plans (archive)](archive/consolidated-legacy-plans.md) · [Legacy audits (archive)](archive/consolidated-legacy-audits.md)
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
- [PLAN.md](../PLAN.md) — active engineering plan (social stack)
- [releases/README.md](../releases/README.md) — APK releases
