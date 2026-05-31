# Prestige Noir — Vertiege visual direction

Branch: `feature/prestige-noir-theme`  
Status: **Phase 1** (tokens + typography + native splash). Screen-by-screen polish continues on this branch.

## Intent

Tier-gated social worlds with proof and voice — UI should feel **premium, calm, and legible**, not “default Flutter + iOS blue.”

## Color roles

| Token | Role | Example use |
|-------|------|-------------|
| `VColors.primary` | Neutral chrome | App bars, FAB ink, borders |
| `VColors.brand` / `tertiary` | Prestige gold | CTAs, Campfire accent, splash, highlights |
| `VColors.secondary` | Violet | Worlds, creative surfaces |
| `VColors.link` / `linkDark` | Blue | URLs only (use instead of tertiary for links) |
| Tier / achievement colors | Unchanged | Progression and categories |

## Dark mode

Base surface `#0F1117` with stepped containers (`#141820` → `#2A3142`). Avoid pure `#000000` for long reading sessions.

## Typography

**Plus Jakarta Sans** via `google_fonts` in `VTheme` and Forui (`v_fonts.dart`).

## What’s next on this branch

- [ ] Nexus / world cards: left-edge tier stripe, calmer card chrome
- [ ] Replace mistaken `tertiary` link usages with `VColors.link`
- [ ] Auth: brand-neutral social icons
- [ ] Shorter splash on repeat launch

See also [UI_STANDARDS.md](UI_STANDARDS.md).
