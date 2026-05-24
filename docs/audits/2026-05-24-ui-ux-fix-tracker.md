# UI/UX fix tracker — U01–U12 (+ ANA backlog)

Source: [2026-05-24-cursor-swarm-ui-ux-audit.md](./2026-05-24-cursor-swarm-ui-ux-audit.md) (skills-enhanced re-run, 2026-05-24)

**Swarm artifacts:** `.swarm/runs/2026-05-24T15-58-16/`

| ID | Sev | Status | Notes |
|----|-----|--------|-------|
| U01 | High | **done** | Single `MaterialApp` + splash overlay; prefs warmed in `main` |
| U02 | Med | **done** | Default `ThemeScheme.system` |
| U03 | Med | **partial** | `v_context_colors.dart`; screen migration ongoing |
| U04 | Med | **done** | Explore / Nexus / Chat → `VTabPage` + `FHeader` |
| U05 | Med | **done** | `VButton` wraps `FButton` |
| U06 | Med | **done** | `VFeedback` + `showFToast`; SnackBars removed from `lib/` |
| U07 | Med | **done** | Tab shell aligned with `VHubPage` via `VTabPage` |
| U08 | Med | **open** | Auth still Material `TextField` (buttons use `VButton`/`FButton`) |
| U09 | Low | **open** | Tier/prestige dialogs still `AlertDialog` |
| U10 | Low | **done** | `VAppBanner` / `FAlert` in `app.dart` |
| U11 | Low | **partial** | `VAccessibleHeaderAction` on tab headers |
| U12 | Low | **done** | Explore loading uses same `VTabPage` shell |

## Waves

| Wave | Focus | IDs |
|------|--------|-----|
| 1 | Theme correctness | U01, U02, U03 |
| 2 | Shell unification | U04, U07 |
| 3 | Forui controls & feedback | U05, U06, U08 |
| 4 | Polish & a11y | U09–U12 |
