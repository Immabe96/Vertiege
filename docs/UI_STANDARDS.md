# Vertiege UI standards (iOS + Android)

One Flutter UI — **no separate Cupertino shell**. Platform differences are limited to permissions, store billing, and native splash.

## Design system

| Layer | Location |
|-------|----------|
| Colors | `lib/theme/v_colors.dart` |
| Spacing, type, radius | `lib/theme/v_tokens.dart` |
| Material 3 theme | `lib/theme/v_theme.dart` → `AppTheme` |
| Components | `lib/ui/`, `lib/widgets/`, Forui (`FScaffold`, `FTile`, …) |

## Rules

1. **Prefer `VButton`, `FTile`, theme text styles** over raw `Material` + `InkWell` for new UI.
2. **Motion**: use `context.motionDuration()` / `VHaptics` — respects reduced motion on both OSes.
3. **Navigation pushes**: use `vGoRoute` in `app_router.dart` for full-screen routes (shared fade/slide).
4. **Auth**: `AuthSocialButtons` — Apple only on iOS/macOS; Google on all mobile.
5. **Empty states**: `AppEmptyState` with `assets/images/empty_states/` where possible.
6. **Remote tuning**: Firebase `forui_strict_mode`, `minimum_build` (+ optional `minimum_build_ios` / `minimum_build_android`).

## Version display

Settings shows `kAppVersionLabel` and `Build N · iOS|Android` from `build_info.dart` + `platform_label.dart`.

## Release parity

```bash
./scripts/build_release_all.sh   # same pubspec +N → AAB + IPA
```
