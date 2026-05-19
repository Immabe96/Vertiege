# Jules Task 06: World Discovery Gradient Cleanup

## Goal
Remove mismatched gradients/glass from world discovery and world display surfaces while preserving image clarity.

## Scope
Allowed to touch:
- `lib/screens/world_discovery_screen.dart`
- `lib/screens/tabs/explore_screen.dart`
- `lib/widgets/worlds/world_card.dart`
- `lib/widgets/worlds/world_banner.dart`
- `lib/widgets/worlds/world_hero_banner.dart`
- `lib/widgets/explore/**`
- `test/widget_test.dart`
- `docs/audits/jules-full-app-audit.md`

Do not touch data models, Supabase, onboarding, or feed logic.
Do not do broad regex replacements.

## Required Work
- Remove harsh decorative gradients that make images look strange.
- Keep only subtle bottom scrims where text overlays image content.
- Convert glass/blur panels in this scope to compact Forui-style cards or clean app wrappers.
- Ensure world images remain visible and natural.
- Keep card radius, spacing, typography compact and mobile-friendly.
- Update audit doc with exact files improved.

## Verification
Run:
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`

If visual verification is possible, include screenshots in the PR or describe what was inspected.
