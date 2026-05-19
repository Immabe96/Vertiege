# Jules Task 08: Nexus Feed Forui Pass

## Goal
Make Nexus/feed UI compact, minimal, and Forui-aligned without changing data behavior.

## Scope
Allowed to touch:
- `lib/screens/tabs/nexus_screen.dart`
- `lib/widgets/feed/**`
- `lib/widgets/nexus/**`
- `lib/widgets/core/empty_state.dart`
- `test/widget_test.dart`
- `docs/audits/jules-full-app-audit.md`

Do not touch Supabase migrations, world config, onboarding, or repositories.
Do not do broad regex replacements.

## Required Work
- Clean feed cards, composer surfaces, sort/filter controls, and empty states.
- Preserve create/comment/react/bookmark/share behavior.
- Remove mismatched glass/gradient styling in this scope.
- Keep typography compact and readable in light/dark modes.
- Update audit doc with exact changes and residual risks.

## Verification
Run:
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`

Do not open PR if the feed/composer code has compile errors or broken callbacks.
