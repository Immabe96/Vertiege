# Jules Task 07: World Detail Forui Pass

## Goal
Make the world detail screen compact, readable, and Forui-aligned without changing behavior.

## Scope
Allowed to touch:
- `lib/screens/world_detail_screen.dart`
- `lib/widgets/worlds/world_detail_members.dart`
- `lib/widgets/worlds/world_feed_tab.dart`
- `lib/widgets/worlds/world_info_cards.dart`
- `lib/widgets/worlds/world_events_card.dart`
- `test/widget_test.dart`
- `docs/audits/jules-full-app-audit.md`

Do not touch Supabase, onboarding, world config, or unrelated world settings widgets.
Do not mechanically replace every widget. Keep the build compile-safe.

## Required Work
- Remove heavy glass/blur/gradient treatments in this scope.
- Use existing Forui/app wrappers correctly. Do not pass unsupported parameters to Forui widgets.
- Preserve route behavior, tabs, member display, feed tab, event cards, and CTA behavior.
- Keep image overlays minimal and readable.
- Update audit doc with changes and remaining UI debt.

## Verification
Run:
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`
- `flutter build apk --release` if GitHub Actions is available; otherwise document that CI will build the PR.
