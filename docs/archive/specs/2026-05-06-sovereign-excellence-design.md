# Sovereign Excellence — Full UI Replacement Spec

**Date:** 2026-05-06
**Source:** Stitch project "App Interface Redesign" (6774459552779345748)
**Branch:** design-overhaul
**Status:** Approved

## Summary

Complete replacement of the Vertiege design system. Shift from the current "Dark Social Arena" (Discord + Duolingo + Spotify hybrid) to "Sovereign Excellence" (Minimalism + Glassmorphism). Every visible surface changes; models, providers, and business logic stay untouched.

---

## 1. Design System Changes

### 1.1 Color Palette — Full Replacement

Replace all `AppColors` with the Sovereign obsidian palette:

| Token | New Value | Old Value | Role |
|-------|-----------|-----------|------|
| `canvas` | `#0A0A0A` | `#121212` | OLED page background |
| `surface` | `#141218` | `#181818` | Cards, containers |
| `surfaceElevated` | `#1d1b20` | `#1f1f1f` | Inputs, hover |
| `surfaceHigh` | `#211f24` | `#252525` | Modals, sheets |
| `surfaceOverlay` | `#2b292f` | `#2a2a2a` | Dropdowns, tooltips |
| `primary` | `#cfbcff` | `#7c3aed` | CTAs, active nav |
| `tertiary` | `#e7c365` | `#d4af37` | Gold tier, prestige |
| `onSurface` | `#e6e0e9` | `#ffffff` | Primary text |
| `onSurfaceVariant` | `#cbc4d2` | `#b3b3b3` | Secondary text |
| `outline` | `#948e9c` | `#252525` | Borders |
| `outlineVariant` | `#494551` | `#1f1f1f` | Subtle borders |
| `error` | `#ffb4ab` | `#ef4444` | Destructive actions |
| `accentHustler` | `#FF6D00` | (new) | Tier III worlds |

Remove: `accentStreak`, `accentLevel`, `accentAchievement`, `accentWorldWealth`, `accentWorldProfession`, `accentWorldDominion`, legacy tier aliases.

The gamification accent palette is replaced by the 3-tier system: Gold (tertiary), Violet (primary), Orange (hustler).

### 1.2 Typography — Dual-Font System

| Token | Font | Size | Weight | Use |
|-------|------|------|--------|-----|
| `display-xl` | Space Grotesk | 48px | 700 | Hero names, celebrations |
| `headline-lg` | Space Grotesk | 32px | 600 | Page titles |
| `headline-md` | Space Grotesk | 24px | 600 | Card titles, section headers |
| `body-lg` | Inter | 18px | 400 | Lead paragraphs |
| `body-md` | Inter | 16px | 400 | Default text, post bodies |
| `label-sm` | Inter | 12px | 600 | Badges, chips, meta, uppercase tracking |

Remove: `bodySmall`, `caption`, `captionStrong`, `button`, `buttonSmall`, `micro`, `code`. Font weights 400/700 only.

### 1.3 Radius — Tight Scale

| Token | Value | Use |
|-------|-------|-----|
| `sm` | 2px | Buttons, inputs |
| `DEFAULT` | 4px | Standard containers |
| `lg` | 6px | Chips |
| `xl` | 8px | Cards |
| `full` | 12px | Modals, rounded panels |

Remove: `pill` (20px), `cardFeatured` (12px), `celebration` (14px), `circle` (9999px). The old system's large radii don't fit the architectural aesthetic.

### 1.4 Glass & Glow System

- **Glass Panel:** `rgba(18,18,18,0.6)` background + `backdrop-filter: blur(12px)` + `1px solid rgba(148,142,156,0.1)` border
- **Glass Modal:** `rgba(20,18,24,0.4)` + `backdrop-filter: blur(20px)`
- **Glow-Gold:** `1px solid rgba(231,195,101,0.2)` + `box-shadow: 0 0 15px rgba(231,195,101,0.1)`
- **Glow-Violet:** `1px solid rgba(207,188,255,0.2)` + `box-shadow: 0 0 15px rgba(207,188,255,0.1)`
- **Glow-Orange:** `1px solid rgba(255,109,0,0.2)` + `box-shadow: 0 0 15px rgba(255,109,0,0.1)`
- No traditional shadows on any element — depth from translucency + blur

### 1.5 Inputs — Ghost Style

- Transparent background, 1px bottom border in `outlineVariant`
- Focus: bottom border animates to `tertiary` (gold)
- Labels: `label-sm` uppercase, above the input
- No filled/outlined variants

---

## 2. Navigation Changes

### 2.1 Bottom Tab Bar

Replace 4-tab + FAB with 5-tab glass container:

| Tab | Icon | Label | Route |
|-----|------|-------|-------|
| Nexus | hub | NEXUS | `/` |
| Worlds | explore | WORLDS | `/explore` |
| Create | add_circle (filled, elevated, gold) | CREATE | `/create-post` |
| Chat | chat_bubble | CHAT | `/chat` |
| Identity | account_circle | IDENTITY | `/identity` |

- Glass container: `surface/90` + `backdrop-blur-2xl`, rounded top, border top
- Active: gold (`tertiary`) icon + label, scale 1.1
- Inactive: `onSurfaceVariant/60` faded
- Labels: uppercase `label-sm`
- Remove FAB — Create tab replaces it

### 2.2 Top App Bar

- Fixed, glass (`surface/80` + `backdrop-blur-xl`)
- Left: Avatar (40px circle, gold border) + "Vertiege" in gold Space Grotesk
- Right: Notification bell (filled when unread)
- No shadow, bottom border `outlineVariant/20`

### 2.3 Side Navigation (Desktop)

- Glass sidebar, fixed left, `surfaceContainerHigh` + backdrop-blur
- World icon + name header with tier label
- Nav items: World Settings, Permissions, Rank Hierarchy, Audit Log
- Active item: `secondaryContainer/30` background, gold left border

---

## 3. Component Specifications

### 3.1 World Card (Tiered)

Three tiers of cards, all glass-panel base:
- **Apex (Tier I):** Gold glow border, diamond icon, "INVITE ONLY", gold CTA button
- **Elite (Tier II):** Violet glow border, workspace_premium icon, member count, "ACCESS ASSETS" button
- **Hustler (Tier III):** Orange glow border, bolt icon, growth % bar, orange accent

### 3.2 Post Composer

- Glass panel container, rounded-xl
- World selector dropdown (glass)
- Sovereign Announcement toggle with gold highlight
- Rich toolbar: bold, italic, list, image, attachment, link
- Ghost title + body inputs
- Media grid with delete overlay on hover
- Quick-attach bar below editor

### 3.3 Achievement Card

- Glass panel base, rounded-full (12px)
- Glow border variant (gold for rare, violet for standard)
- Large icon, title, description
- Progress bar (thin, 4px, rounded)
- Locked state: `opacity-50` + blur overlay + lock icon
- "RARE" badge in gold, top-right

### 3.4 Chat Bubble

- Received: `surfaceElevated` (#1d1b20), rounded 8px with 3px bottom-left
- Sent: `primary`, rounded 8px with 3px bottom-right
- System: `accentHustler/10` left border, pink text
- Timestamps: `label-sm`, `onSurfaceVariant/40`
- Chat input: glass, bottom border orange on focus

### 3.5 States (Loading/Error/Empty)

- **Loading:** Glass panels with pulse animation (not shimmer). Translucent containers with `animate-pulse` opacity
- **Error:** Yellow/red banner below top bar, "DEGRADED" status label, glass error card with retry button + sync icon, placeholder widgets with pulse skeletons
- **Empty:** Glass panels with dashed borders, "add_circle" icon placeholder, muted text

---

## 4. Screen Mapping

| Stitch Screen | Flutter File | Action |
|---------------|-------------|--------|
| Identity: Achievements | `lib/screens/achievements/achievements_index.dart` | Rebuild |
| Nexus: Activity & Alerts | `lib/screens/tabs/nexus_screen.dart` + `alerts_screen.dart` | Rebuild both |
| Admin: World Control | `lib/screens/world_settings_screen.dart` | Rebuild |
| Nexus: Create Post | `lib/screens/tabs/create_post_screen.dart` | **New** |
| World: Digital Architects | `lib/screens/world_detail_screen.dart` | Rebuild |
| The Forge (main) | `lib/screens/world_detail_screen.dart` | Rebuild |
| The Forge (Error/Loading/Empty) | World detail states | New states |
| World Showcase Index | `lib/screens/tabs/explore_screen.dart` | Rebuild |
| The Gilded Vault | `lib/screens/world_detail_screen.dart` | Rebuild |

---

## 5. What Does NOT Change

- All models (`lib/models/`)
- All providers/state (`lib/state/`)
- Services (`lib/services/`)
- Router structure (only tab indices + new Create route)
- Supabase integration
- Business logic

---

## 6. Implementation Order

| Phase | Scope | Files |
|-------|-------|-------|
| P1 | Design tokens | `colors.dart`, `design_system.dart`, `app_theme.dart` |
| P2 | Shared widgets | `glass_panel.dart`, `glow_border.dart`, `ghost_input.dart`, `sovereign_card.dart`, `loading_state.dart`, `error_banner.dart`, `progress_bar.dart` |
| P3 | Navigation | `tab_layout.dart`, `app_router.dart`, `create_post_screen.dart` |
| P4 | Tab screens | `nexus_screen.dart`, `explore_screen.dart`, `identity_screen.dart`, `chat_list_screen.dart` |
| P5 | World screens | `world_detail_screen.dart`, `world_channel_screen.dart`, `world_settings_screen.dart` |
| P6 | Widget migration | All remaining widgets updated to glass/glow/token references |
| P7 | Polish | States (loading/error/empty), animations, cleanup |
