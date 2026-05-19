# Jules Task 02: Default Worlds And Starter Channels

## Goal
Make default starter worlds explicit and give each default world unique persisted lore and starter channel text.

## Scope
Allowed to touch:
- `lib/config/tiers.dart`
- `lib/utils/world_foundations.dart`
- `lib/models/channel.dart`
- `lib/services/world_service.dart`
- `lib/state/world_provider.dart`
- `lib/state/channel_provider.dart`
- `lib/screens/onboarding/**`
- `lib/screens/world_channel_screen.dart`
- `supabase/migrations/**`
- `test/**`
- `docs/audits/jules-full-app-audit.md`

Do not redesign UI in this task.
Do not touch unrelated feature screens.

## Required Work
- Set `isDefault: true` only for `neon-district` and `crystal-shore` in app config.
- Replace hardcoded starter slug selection with `world.isDefault == true`.
- Add world lore in config if missing.
- Add unique per-world `info`, `rules`, and `roles` markdown in `world_foundations.dart` for all 16 worlds.
- Add persistent channel starter content using:
  - `channels.foundation_markdown TEXT`
  - `channels.foundation_version TEXT NOT NULL DEFAULT 'v1'`
- Update `WorldChannel` to serialize/deserialize `foundationMarkdown` and `foundationVersion`.
- Update `WorldService.createDefaultChannels()` to seed per-world channel descriptions and foundation markdown.
- Backfill existing default channels in a safe migration.
- Channel UI should display Supabase `foundationMarkdown` first, then fallback to `world_foundations.dart`.
- Update audit doc with completed and remaining items.

## Verification
Run:
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`

Add or update tests proving:
- 16 unique world slugs exist.
- Only `neon-district` and `crystal-shore` are default starters.
- Every world has non-empty unique `info`, `rules`, and `roles` text.
- Onboarding/gate code uses `isDefault` rather than hardcoded slugs.
