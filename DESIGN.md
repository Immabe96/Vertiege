# Vertiege Design System -- Sovereign Excellence

A minimalist glassmorphism design system built on an OLED obsidian palette. The UI recedes so content competes, with glow borders reserved for tiered prestige moments.

Source spec: `docs/superpowers/specs/2026-05-06-sovereign-excellence-design.md`
Token files: `lib/theme/colors.dart`, `lib/theme/design_system.dart`

---

## Navigation Architecture

5-tab glass bottom navigation bar:

| Tab    | Icon            | Destination       |
|--------|-----------------|-------------------|
| Nexus  | Home            | Primary feed      |
| Worlds | Explore         | World discovery   |
| Create | Gold (elevated) | Post composer     |
| Chat   | Chat bubble     | Messages          |
| Profile| Person          | Identity/settings |

The Create tab uses a gold-elevated button, visually distinct from the other four tabs. The nav bar uses glassmorphism (BackdropFilter + blur) with a glass border.

---

## 1. Color Palette

All tokens live in `lib/theme/colors.dart` (class `AppColors`).

**OLED Obsidian Surface Hierarchy:**
- `canvas` (#0A0A0A) -- OLED page background
- `surface` (#141218) -- Cards, containers
- `surfaceElevated` (#1D1B20) -- Inputs, hover states
- `surfaceHigh` (#211F24) -- Modals, sheets
- `surfaceOverlay` (#2B292F) -- Dropdowns, tooltips

**Text:**
- `ink` (#E6E0E9) -- Primary text
- `inkSecondary` (#CBC4D2) -- Secondary text
- `inkMuted` (#948E9C) -- Disabled, placeholder

**Sovereign Accents (3-tier system):**
- `primary` (#CFBCFF, violet) -- CTAs, active nav, links
- `tertiary` (#E7C365, gold) -- Prestige, gold frames, tier indicators
- `hustler` (#FF6D00, orange) -- Tier III worlds

**Glass Tokens:**
- `glassBackground` -- translucent dark surface for glass cards
- `glassModalBackground` -- translucent surface for modals/sheets
- `glassBorder` -- low-opacity border for glass containers

**Glow Opacities (reserved for tiered content):**
- `glowGoldAlpha` (0.10) -- Gold-tier glow
- `glowVioletAlpha` (0.10) -- Violet-tier glow
- `glowOrangeAlpha` (0.10) -- Orange-tier glow
- `glowAlphaStrong` (0.15) -- Stronger celebration moments

**Semantic:** `error`, `success`, `warning` -- standard meanings.

**Borders:** `borderDefault` (#494551), `borderSubtle` (#36343A), `outline` (#948E9C), `outlineVariant` (#494551).

Legacy aliases (gradual migration): `accentPrimary`, `accentPrestige`, `tierColors`, etc.

---

## 2. Typography

Dual-font system defined in `lib/theme/design_system.dart`:

- **Space Grotesk** -- Headlines (display, page titles, card headers)
- **Inter** -- Body (posts, descriptions, chat messages)
- **JetBrains Mono** -- Code / numerical data

**Scale (class `FontSizes`):**
- `displayXl` (48px, 700) -- Hero names, celebrations
- `headlineLg` (32px, 600) -- Page titles
- `headlineMd` / `headingCard` (24px, 600) -- Card titles, section headers
- `bodyLg` (18px, 400) -- Lead paragraphs
- `bodyMd` / `body` (16px, 400) -- Default text, post bodies
- `labelSm` / `caption` / `micro` (12px, 600) -- Badges, chips, meta

**Related tokens:** `FontWeights` (regular/semiBold/bold), `LetterSpacing`, `LineHeight`, `Spacing` (8px base), `RadiusTokens` (architectural tight 2-12px scale), `IconSizes`, `AnimDurations`, `AnimCurves`, `TouchTargets`.

---

## 3. Glassmorphism -- Core Depth Language

Glassmorphism replaces flat surface hierarchy as the primary depth system. Implemented via `BackdropFilter` with `ImageFilter.blur`.

- **Cards, nav bar, modals:** use `AppColors.glassBackground` + `AppColors.glassBorder`
- **Radius:** use `RadiusTokens` scale (cards: `xl`/8px, featured: `full`/12px)
- **No box-shadows** on everyday UI. Glow borders are reserved:

### Glow Borders (Tiered Content)

- **Gold border** (`tertiary` at `glowGoldAlpha`) -- Prestige-tier worlds, sovereign badges
- **Violet border** (`primary` at `glowVioletAlpha`) -- Default tiered content
- **Orange border** (`hustler` at `glowOrangeAlpha`) -- Hustler-tier worlds

Glow uses `BoxShadow` with accent color and appropriate alpha, not CSS-style border glow. Only one glow element per screen -- glow is the exclamation point.

---

## 4. Ghost Inputs

Defined in `lib/widgets/core/ghost_input.dart`.

- Transparent background, no box decoration
- Bottom border only (`UnderlineInputBorder`)
- `enabledBorder`: `AppColors.glassBorder`
- `focusedBorder`: `AppColors.tertiary` (gold)
- Label rendered above in uppercase with gold color and letter spacing

---

## 5. Key Component Patterns

- **Cards:** `Container` with `glassBackground` + `glassBorder` + `RadiusTokens.card`. No shadow. No glow unless tiered.
- **Buttons:** Use Flutter built-in `FilledButton` / `OutlinedButton` with theme-provided colors.
- **Chips:** Surface-elevated background, `RadiusTokens.chip` (6px), 12% accent background when selected.
- **Avatars:** Circular with optional tier ring via `CosmeticAvatar`.
- **XP Toast:** Glass pill with gold glow overlay, positioned top-right via `Overlay`.

---

## 6. Layout Principles

- **Spacing:** 8px base unit. Chat-dense (4-8px gaps). Feed-balanced (12-16px padding).
- **Touch targets:** 44px minimum. Icon buttons 40px circular.
- **Single column** for feeds, horizontal rails for featured worlds.
- **Responsive:** Phone full-width, tablet 640px max content width, desktop centered.
- **No dividers** in feed/card areas -- surface contrast and spacing separate elements.

---

## 7. Do's and Don'ts

**Do:**
- Use `glassBackground` + `glassBorder` for card surfaces
- Reserve glow borders for tiered content only
- Use Space Grotesk for headlines, Inter for body
- Reference `AppColors` and design tokens from `lib/theme/`
- Keep the 3-tier accent system (gold/violet/orange)

**Don't:**
- Don't add box-shadows to non-tiered cards, buttons, or inputs
- Don't use glow on more than one element per screen
- Don't use pure black (#000000) -- canvas is #0A0A0A
- Don't add new accent colors -- the 3-tier palette is closed
- Don't reference the old gamification palette (streak/level/achievement/world-type accents)
- Don't skip BackdropFilter -- flat surfaces feel dead without glass