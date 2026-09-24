---
name: Vertiege Renewal
description: >-
  Dark-only premium design system for Vertiege. Warm near-black surfaces
  with a real lightness ladder, one luminous gold accent, and an
  editorial serif voice (Fraunces display + Plus Jakarta Sans UI).
  Content-first information architecture: Home feed, Worlds gallery,
  DM-first Chat, Identity on You. Light theme: deferred.
version: 1.0.0
mode: dark
seedColor: "#9C6B1E"
tone: premium
fonts:
  display: Fraunces
  body: Plus Jakarta Sans
  mono: JetBrains Mono
tokens:
  color:
    dark:
      canvas: "#0E0C09"
      surface: "#1A1611"
      surfaceRaised: "#262019"
      ink: "#F2EEE6"
      inkMuted: "#A79F90"
      inkDim: "#84796A"
      border: "#2A2620"
      borderStrong: "#3A352C"
      accent: "#E3B84D"
      accentStrong: "#F0CC77"
      accentSoft: "#2A2312"
      onAccent: "#16130E"
      success: "#4CAF7D"
      warning: "#E0A34E"
      danger: "#E06C5F"
      online: "#4CAF7D"
  type:
    scale:
      display: { size: 32, line: 1.15, weight: 600, family: display }
      title: { size: 22, line: 1.25, weight: 600, family: display }
      heading: { size: 18, line: 1.3, weight: 600, family: body }
      body: { size: 15, line: 1.5, weight: 400, family: body }
      callout: { size: 13, line: 1.45, weight: 500, family: body }
      caption: { size: 12, line: 1.4, weight: 400, family: body }
      micro: { size: 11, line: 1.35, weight: 500, family: body }
      code: { size: 13, line: 1.5, weight: 400, family: mono }
  space:
    scale: [2, 4, 8, 12, 16, 20, 24, 32, 48]
  radius:
    sm: 8
    md: 12
    lg: 16
    xl: 20
    pill: 999
  shadow:
    raised: "0 2px 16px rgba(0,0,0,0.35)"
---

# Vertiege Renewal

**Status:** Wave S12 — active redesign direction. Supersedes the Prestige Noir
visual direction in `docs/reference/design-system.md` (that file remains the
documentation of the *shipped* baseline until migration completes).

## Why this direction

Prestige Noir failed on three craft fundamentals:

1. **Invisible surface ladder.** `bg #101114` → `chrome #14171C` → `surface
   #171A1F` are 3–6% lightness apart. Cards, chrome, and background merge into
   one charcoal slab; users cannot tell where one region ends and another
   begins.
2. **Competing accents.** Dusty gold `#C9A227` and violet fight each other,
   plus tier and achievement palettes. No single focal point survives.
3. **Dark, done badly.** A dark theme only fails when its surfaces don't
   step. Vertiege Renewal stays dark-only for beta but fixes the ladder,
   accent discipline, and type hierarchy. (Light theme is a deferred
   follow-up.)

Vertiege Renewal fixes all three: a real surface hierarchy in **one
deliberate dark theme**, **one** accent, and an editorial voice no chat app
has.

## Philosophy

- **Premium, calm, legible.** One focal point per view; hierarchy via size,
  weight, and ink strength — not borders everywhere.
- **Warm dark, never muddy charcoal.** The canvas is warm near-black; surfaces
  step up visibly in lightness, never flat.
- **Gold earns its place.** Accent only on CTAs, active nav, tier/progression
  moments, and verified marks. Never on list backgrounds or body text.
- **Serif is a voice, not a costume.** Fraunces for wordmark, screen titles,
  world names, tier names, hero numbers. Body/UI stays Plus Jakarta Sans.
- **Dark-only for now.** One deliberate dark theme; light is deferred until
  after beta. The dark ladder must visibly step: canvas → surface → raised.

## Color rules

| Token | Value | Use |
|-------|-------|-----|
| `canvas` | `#0E0C09` | App background |
| `surface` | `#1A1611` | Cards, sheets, bars |
| `surfaceRaised` | `#262019` | Hero cards, menus |
| `ink` | `#F2EEE6` | Primary text |
| `inkMuted` | `#A79F90` | Secondary text, captions (AA ≥ 4.5:1 on `surface`) |
| `inkDim` | `#84796A` | Placeholders, dim labels (non-essential) |
| `border` | `#2A2620` | Hairline separators |
| `accent` | `#E3B84D` | CTAs, active nav, progression |
| `accentSoft` | `#2A2312` | Selected chips, tinted backgrounds |
| `onAccent` | `#16130E` | Text on accent fills |

- Surfaces separate by **fill, not shadow**: `canvas` → `surface` → `surfaceRaised`.
- Hairline borders (`border`) mark card edges; never stack a border and a shadow.
- No pure `#000` or `#FFF` text; no gradients in hero CTAs.

## Typography

| Role | Size/Line | Weight | Family |
|------|-----------|--------|--------|
| `display` | 32 / 1.15 | 600 | Fraunces |
| `title` | 22 / 1.25 | 600 | Fraunces |
| `heading` | 18 / 1.3 | 600 | Jakarta |
| `body` | 15 / 1.5 | 400 | Jakarta |
| `callout` | 13 / 1.45 | 500 | Jakarta |
| `caption` | 12 / 1.4 | 400 | Jakarta |
| `micro` | 11 / 1.35 | 500 | Jakarta |
| `code` | 13 / 1.5 | 400 | JetBrains Mono |

Serif max-width guidance: serif headings stay ≤ 2 lines on mobile.

## Spacing, radius, elevation

- One scale: 2 / 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48. Page gutter 16; card
  gap 12; section gap 24–32.
- Radius ramp: chips 8, inputs 12, cards 16, sheets 20, buttons pill.
- Cards: hairline border, no drop shadow. Only `surfaceRaised` overlays
  (menus, sheets) may use `shadow.raised`.
- Touch targets ≥ 48dp.

## Motion

- Micro feedback 160ms, standard 240ms, `ease-out`. No bounce/elastic/overshoot.
- Honor `prefers-reduced-motion` / `context.motionDuration()`.

## Information architecture

Four tabs, content-first:

| Tab | Job |
|-----|-----|
| **Home** | Nexus feed first: Today strip (streak, quests, tier), composer, one feed. Notifications via bell → unified inbox. |
| **Worlds** | Gallery, not a rail: featured hero, your worlds (horizontal), trending grid. Channels live in world detail. |
| **Chat** | DM-first unified inbox: Direct + Worlds sections, presence, unread gold badges. Push quick-reply. |
| **You** | Identity hero (avatar, serif name, verified), stats, tier progress, hubs: Achievements, Allies, Identity, Settings. |

## Component rules

- One card system: `VCard` (flat `surface` + hairline) and `VRaisedCard`
  (hero/sheet `surfaceRaised`). No nested cards.
- One button family: `VButton` pill, `VIconButton`; gold fill only for the
  single primary action per view.
- Icons: consistent line set, stroke 1.75, 20–24dp. No emoji as iconography.
- Empty states: illustration-free — icon + serif line + one CTA, on `canvas`.

## Anti-patterns (do not reintroduce)

- `isDark ? … : …` ternaries — use theme tokens.
- Card inside card; border + shadow on the same surface.
- Accent-colored body text; muted text on tinted backgrounds below AA.
- More than one filled (gold) CTA visible at once.
