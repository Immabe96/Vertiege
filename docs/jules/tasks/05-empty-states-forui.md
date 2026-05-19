# Jules Task 05: Clean Forui Empty States

## Goal
Replace ugly/noisy empty states, especially no-posts, with compact Forui-style empty states.

## Scope
Allowed to touch:
- `lib/widgets/core/empty_state.dart`
- `lib/ui/feedback/**`
- `lib/widgets/feed/**`
- `lib/screens/tabs/nexus_screen.dart`
- `lib/screens/tabs/alerts_screen.dart`
- `lib/screens/world_channel_screen.dart`
- `test/widget_test.dart`
- `docs/audits/jules-full-app-audit.md`

Do not touch Supabase, persistence, world config, or broad screen layouts.
Do not add new raster images unless absolutely necessary.

## Required Work
- Replace image-heavy empty states with minimal icon/title/body/CTA layouts.
- Keep light theme white/minimal with dark readable text.
- Keep dark theme AMOLED-safe with high contrast.
- Ensure no text overlaps or clips at mobile widths.
- Preserve existing callbacks and routes.
- Update audit doc with before/after summary.

## Verification
Run:
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`

Add or update widget tests for empty feed/no notifications/no channel posts if feasible.
