# Vertiege — Figma Design System Integration Rules

## 1. Token Definitions

### Location & Format
All design tokens live in `lib/theme/` as Dart classes with **static const** fields — no JSON/CSS variable export, no runtime transformation.

| File | Purpose |
|---|---|
| `lib/theme/colors.dart` | Color palette, semantic colors, surface hierarchy, gradients, opacities |
| `lib/theme/design_system.dart` | Spacing, radii, fonts, icon sizes, shadows, animation durations/curves |
| `lib/theme/app_theme.dart` | Material 3 `ThemeData` assembly (light + dark) with per-component defaults |

### Color System

**Primary seed**: `#5865F2` (Discord blurple) — drives Material 3 `ColorScheme.fromSeed()` auto-derivation.

**Explicit semantic colors** (`AppColors.*`):

| Token | Hex | Usage |
|---|---|---|
| `seed` | `#5865F2` | Primary brand, links, active states |
| `online` | `#23A55A` | Online presence indicator |
| `idle` | `#F0B232` | Idle/away presence |
| `dnd` | `#F23F43` | Do-not-disturb presence |
| `offline` | `#80848E` | Offline/invisible state |
| `owlGreen` | `#58CC02` | Gamification: progress bars, success states |
| `owlGreenDeep` | `#58A700` | TactileButton shadow for green |
| `streakOrange` | `#FF9600` | Streaks, urgency, highlights |
| `gemPink` | `#CE82FF` | Premium/cosmetic features |
| `brandGreen` | `#3ECF8E` | Brand gradient endpoint |
| `emerald` | `#2D8B57` | Medical profession |
| `crimson` | `#8B2252` | Legal profession |
| `dangerRed` | `#DA373C` | Destructive actions, error states |
| `gold` | `#D4A843` | Tier 3 medal |
| `silver` | `#C0C0C0` | Tier 2 medal |
| `bronze` | `#CD7F32` | Tier 1 medal |

**Dark surface hierarchy** (explicit — NOT derived from seed):

| Token | Hex | Usage |
|---|---|---|
| `darkSurfaceBase` | `#1A1B1E` | Scaffold background |
| `darkSurfaceRaised` | `#1E1F22` | Bottom nav, elevated panels |
| `darkSurfaceCard` | `#2B2D31` | Cards, list tiles |
| `darkSurfaceOverlay` | `#313338` | Dialogs, bottom sheets |
| `darkSurfaceHighest` | `#383A40` | Hovered/pressed cards |

**Gradients** (`AppColors.gradient*`):
- `gradientPrimary`: `#5865F2 → #7C6FFD` — FAB, speed dial, primary CTAs
- `gradientBrand`: `#5865F2 → #3ECF8E` — brand headers
- `gradientWarm`: `#FF9600 → #FF5764` — celebration screens
- `gradientDark`: `#1A1B1E → #2B2D31` — dark backgrounds

**Opacity presets**: `alphaHover: 0.06`, `alphaPressed: 0.12`, `alphaSelected: 0.15`, `alphaBorder: 0.15`, `alphaDisabled: 0.38`, `alphaOverlay: 0.60`

**Figma mapping**: Map Figma `surface-container*` tokens to Material 3 auto-derived colors for light mode; use `darkSurface*` explicit tokens for dark mode. When a Figma design uses a color not in `AppColors`, create a new semantic token — do NOT hardcode hex values inline.

### Spacing Scale
`4, 8, 16, 24, 32, 48` — 4px grid. Class: `Spacing.{xs, sm, md, lg, xl, xxl}`.

**Figma mapping**: Round Figma auto-layout gaps and padding to the nearest `Spacing` token.

### Radius Scale
`4, 8, 12, 16, 28, 100` — Class: `RadiusTokens.{xs, sm, md, lg, xl, round}`.

Component defaults in `AppTheme`:
- Cards: `12` (md)
- Inputs: `8` (sm)
- Buttons: `8` (sm)
- Chips/pills: `100` (round)

**Figma mapping**: Match Figma corner radius to nearest `RadiusTokens` value.

### Typography Tokens

| Token | Values |
|---|---|
| `FontSizes` | `caption: 12`, `body: 14`, `bodyLarge: 16`, `subhead: 18`, `title: 22`, `headline: 28`, `hero: 36` |
| `FontWeights` | `regular: 400`, `medium: 500`, `semibold: 600`, `bold: 700` |
| `LetterSpacing` | `tight: -0.5`, `normal: 0.0`, `wide: 0.5`, `heading: -1.5` |
| `LineHeight` | `tight: 1.1`, `normal: 1.4`, `relaxed: 1.6` |

**Font**: `google_fonts: ^6.2.1` at runtime — no bundled `.ttf` files.

**Usage pattern**: All headings/titles use `LetterSpacing.heading` (-1.5). Body text uses `LineHeight.normal` (1.4). `AppTheme` applies these via `titleTextStyle`, `headlineMedium`, `bodyLarge`, etc.

### Animation Tokens
| Token | Values (ms) |
|---|---|
| `AnimDurations` | `instant: 80`, `fast: 150`, `normal: 250`, `slow: 400`, `entrance: 500`, `dramatic: 800` |
| `AnimCurves` | `easeOut: Curves.easeOutCubic`, `easeInOut: Curves.easeInOutCubic`, `spring: Curves.elasticOut`, `bouncy: Curves.easeOutBack` |

**Specific component timings**:
- `TactileButton` press: 180ms (hardcoded, matching Duolingo)
- `ReactionChip` burst: 300ms bounce sequence
- `Shimmer` sweep: 1500ms repeating
- `StatusDot` pulse: 1500ms repeating

### Icon Size Tokens
`IconSizes.{xs: 12, sm: 14, md: 20, lg: 28, xl: 48, hero: 64}`

### Border Tokens
`BorderWidth.{thin: 0.5, normal: 1.0, thick: 2.0, accent: 3.0}`

### Shadow Tokens
`ShadowTokens` provides pre-built `List<BoxShadow>` arrays for both light and dark modes:
`xs`, `sm`, `md`, `lg`, `xl`, `glow` + `darkXs`, `darkMd`, `darkGlow`

---

## 2. Component Library

### Directory Structure
```
lib/widgets/
  core/          — Primitives: FadeIn, Shimmer/Skeleton, StatusDot, TactileButton,
                   NotificationBell, AppEmptyState, AppErrorState, ImageViewer,
                   ScreenHeader, SafeScreen, OfflineBanner, ThemedText
  feed/          — Feed domain: PostItem, PostInput, ReactionBar, CommentSheet,
                   MediaGrid, PostImage
  profile/       — Profile domain: CosmeticAvatar, NameBanner, Badge, BadgeDisplay,
                   ShareCard
  worlds/        — World domain: WorldCard, WorldBanner, WorldIcon, WorldChannelList,
                   WorldResidents, AccessGuard, WorldAccessGuard, Leaderboard
  shared/        — Cross-cutting: HapticTab, ImagePickerWidget, ProgressBar,
                   SearchBarWidget, TierIcon, ParallaxScroll
  achievements/  — Achievement domain: AchievementCard, AchievementGrid, TierCelebration
```

### Key Reusable Components

| Widget | File | Purpose | Figma Analog |
|---|---|---|---|
| `TactileButton` | `core/tactile_button.dart` | Primary CTA with 3D press animation | Duolingo-style raised button |
| `FadeIn` | `core/fade_in.dart` | Staggered entrance: opacity + slide, optional scale | List item entrance |
| `Shimmer` | `core/shimmer.dart` | Gradient-sweep skeleton loading | Skeleton/loading state |
| `ShimmerPostCard` | `core/shimmer.dart` | Post-card skeleton placeholder | Feed loading state |
| `ShimmerChatTile` | `core/shimmer.dart` | Chat-list skeleton placeholder | Chat list loading state |
| `AppEmptyState` | `core/empty_state.dart` | Animated empty state with icon, text, optional CTA | Empty/zero state |
| `AppErrorState` | `core/empty_state.dart` | Pre-configured error state with retry button | Error state |
| `ImageViewer` | `core/image_viewer.dart` | Fullscreen image with pinch-to-zoom | Media viewer |
| `CosmeticAvatar` | `profile/cosmetic_avatar.dart` | Avatar with XP-gated frame border | Profile avatar |
| `WorldBanner` | `worlds/world_banner.dart` | SVG banner loaded by worldId | World header image |
| `WorldIcon` | `worlds/world_icon.dart` | Material icon mapped by worldId | World icon |
| `ReactionBar` | `feed/reaction_bar.dart` | Horizontal emoji reaction chips with burst animation | Reaction toolbar |
| `MediaGrid` | `feed/media_grid.dart` | 2+ image grid layout | Image gallery |
| `ScreenHeader` | `core/screen_header.dart` | Safe-area-aware header with optional back + notification bell | Screen title bar |
| `StatusDot` | `core/status_dot.dart` | Discord-style presence indicator (online/idle/dnd/offline) | Presence indicator |
| `ThemedText` | `core/themed_text.dart` | Typed text widget that resolves to theme styles | Text component |
| `NotificationBell` | `core/notification_bell.dart` | Bell icon with unread badge | Notification indicator |
| `TierIcon` | `shared/tier_icon.dart` | Tier badge icon (Hustler → Apex) | Tier/rank badge |
| `TierCelebration` | `achievements/tier_celebration.dart` | Fullscreen tier-up celebration overlay | Celebration screen |

### Component Architecture

**Stateful components** use either:
- `ConsumerWidget` / `ConsumerStatefulWidget` (Riverpod) — for components that read providers
- `StatefulWidget` + `State` — for purely local animation state (e.g., `TactileButton`, `ReactionBar`)
- `StatelessWidget` — for leaf/presentational widgets (e.g., `CosmeticAvatar`, `WorldBanner`)

**GlobalTheme adherence**: Every component derives style from `Theme.of(context)`, never hardcoded values. Colors use `theme.colorScheme.*` or `AppColors.*`. Spacing uses `Spacing.*`. Radii use `RadiusTokens.*`.

**Animation pattern**: `SingleTickerProviderStateMixin` on state classes with `AnimationController` initiated in `initState` and disposed in `dispose`. Use `AnimatedBuilder` for rebuilds.

### WorldIcon Mapping
`WorldIcon` maps world IDs to Material Icons via a switch statement (NOT SVG files):

| World ID | Icon |
|---|---|
| `neon-district` | `Icons.nights_stay` |
| `azure-coast` | `Icons.beach_access` |
| `sovereign-city` | `Icons.account_balance` |
| `golden-estate` | `Icons.villa` |
| `aetheria` | `Icons.cloud` |
| `aviation-heights` | `Icons.flight` |
| `medical-nexus` | `Icons.local_hospital` |
| `financial-district` | `Icons.attach_money` |
| `tech-sprawl` | `Icons.computer` |
| `legal-plaza` | `Icons.gavel` |
| `arts-pavilion` | `Icons.palette` |
| `crystal-shore` | `Icons.diamond` |
| `quantum-core` | `Icons.science` |
| `silver-page` | `Icons.menu_book` |
| `crimson-court` | `Icons.castle` |
| `nova-station` | `Icons.rocket_launch` |
| (default) | `Icons.public` |

When adding a new world from Figma, add its entry to this switch and pick a Material Icon.

---

## 3. Styling Approach

### Theme Architecture
- **Material 3** is the foundation: `ThemeData(useMaterial3: true)`
- **`ColorScheme.fromSeed()`** auto-derives the full light/dark color palette from `AppColors.seed`
- `AppTheme.light` and `AppTheme.dark` pre-configure every Material component theme:
  `AppBarTheme`, `BottomNavigationBarTheme`, `CardTheme`, `InputDecorationTheme`,
  `FilledButtonTheme`, `OutlinedButtonTheme`, `TabBarTheme`, `ChipTheme`,
  `SnackBarTheme`, `DialogTheme`, `FloatingActionButtonTheme`, `DividerTheme`

### Dark Mode Rules
- Dark mode is **first-class** — every Figma design must have a dark variant
- Dark cards use `BorderSide` for depth instead of elevation
- Dark surface colors use the explicit `AppColors.darkSurface*` hierarchy, NOT Material 3 derived values
- Use `Theme.of(context).brightness` to branch light/dark in custom widgets
- Dark shimmer uses `AppColors.darkSurfaceCard` base with `#33FFFFFF` highlight (vs light `#E0E0E0` / `#66FFFFFF`)

### Layout Patterns
- No breakpoint system — mobile-first, full-width layouts
- `SafeArea` wraps all screen content
- Content scrolls via `SingleChildScrollView` or `ListView`
- Cards use `Container` with manual `BoxDecoration` (not Material `Card` widget) for border + shadow control
- Post items use the custom container pattern: `borderRadius: RadiusTokens.lg`, `border: 0.15 alpha outlineVariant`, subtle shadow

### ThemedText Enum Pattern
The `ThemedText` widget provides a typed text system:
```dart
ThemedText('Title', type: ThemedTextType.title)
```
Types: `hero → displayLarge`, `headline → headlineMedium`, `title → titleLarge`, `subtitle → titleMedium`, `body → bodyLarge`, `bodySmall → bodyMedium`, `caption → labelSmall`, `link → bodyLarge + primary + underline`

---

## 4. Asset Management

### Directory Structure
```
assets/
  banners/       — SVG world banners (10 files): aetheria, arts-pavilion, aviation-heights,
                   azure-coast, financial-district, golden-estate, medical-nexus,
                   neon-district, sovereign-city-banner.svg (note: inconsistent naming)
  decorations/   — SVG patterns (8 files): circle-pattern, concentric-circles,
                   crosshair-pattern, hexagon-pattern, hexagon-ripple, progress-bar,
                   ripple-pattern, target-pattern
  generated/     — Generated PNG assets: avatars (4 numbered + 3 named), badges (12),
                   profession icons (6), tier images (4), world JPEGs (17),
                   misc backgrounds (3), plus map.ts metadata
  icons/         — SVG icons (27 files): worlds, professions, notifications, tiers, UI
  images/        — App icon layers: Android adaptive (3), iOS (1), favicon, splash
```

### Asset Loading Patterns
- **SVGs**: `SvgPicture.asset('assets/banners/$worldId-banner.svg')` via `flutter_svg`
- **Network images**: `Image.network()` with `loadingBuilder` + `errorBuilder` for post images
- **Cached network images**: `cached_network_image: ^3.4.1` available as a dependency
- **Local PNGs**: Standard `AssetImage('assets/generated/...')` or `Image.asset()`
- **Image viewer**: `ImageViewer.show(context, imageUrl:)` wraps `photo_view` for fullscreen

**Naming convention**: `{category}-{identifier}.{svg|png}` — e.g., `badge-doctor.png`, `prof-artist.png`, `world-neon-district.jpg`. Exception: `sovereign-city-banner.svg` uses full suffix.

**Figma export**: Export Figma illustrations as SVG to `assets/icons/` or `assets/banners/`. Export raster images (photos, avatars) as optimized PNG to `assets/generated/`. Add new assets to `pubspec.yaml` under `flutter: assets:`.

---

## 5. Icon System

### Dual Icon Strategy
1. **Material Icons** (`Icons.*`) — **primary**. Used for all standard UI icons. The 5 tab destinations, reactions, actions, navigation all use Material Icons.
2. **Custom SVGs** (`flutter_svg`) — used for world banners, decoration patterns, and custom icons where Material doesn't have a match.

### When to use which
- **Prefer Material Icons** for: navigation, actions, status, common UI
- **Use SVG assets** for: branded world imagery, decorative patterns, tier/profession badges that need custom styling

### Icon Sizing
Always use `IconSizes.*` tokens: `Icon(Icons.example, size: IconSizes.md)`.

---

## 6. Project Structure

### Top-Level Architecture
```
lib/
  app.dart              — Root widget, splash orchestration, provider init
  main.dart             — Entry point, Supabase init
  config/               — Static configuration data
    achievements.dart   — Achievement definitions
    cosmetics.dart       — Cosmetic frames, profession cosmetics, decoration types
    seed_data.dart       — Database seed data
    tiers.dart           — Tier definitions, standing levels, prestige calc, worldsConfig
  models/               — Data classes (all with json_serializable)
  router/               — GoRouter definition with auth redirects
  screens/              — Full-screen pages organized by domain
  services/             — Business logic layer (Supabase queries, access control)
  state/                — Riverpod providers (StateNotifier + StateNotifierProvider)
  theme/                — Design tokens + ThemeData
  utils/                — Date formatting, ID generation, string helpers
  widgets/              — Reusable UI components organized by domain
```

### State Management (Riverpod)
Every data domain has a provider file in `lib/state/`:

| Provider | State Type | Purpose |
|---|---|---|
| `themeProvider` | `ThemeState` (scheme + ThemeMode) | Theme preference persistence |
| `residentProvider` | `ResidentState` (resident + loading) | Current user profile |
| `worldProvider` | `WorldState` (worlds list + loading) | All worlds data |
| `postProvider` | `PostState` (posts, bookmarks) | Feed data + interactions |
| `chatProvider` | `ChatState` (rooms, messages) | Chat data |
| `notificationProvider` | `NotificationState` | Alerts + unread counts |
| `achievementProvider` | `AchievementState` | Achievement tracking |
| `channelProvider` | `ChannelState` | World channel data |
| `eventProvider` | — | Events data |
| `questProvider` | — | Quest data |

**Pattern**: `StateNotifier<T>` + `StateNotifierProvider` for mutable state with async load methods. `Provider<T>` for derived/computed values (e.g., `appRouterProvider`).

### Model Layer
All models in `lib/models/` use `json_annotation` + `json_serializable` with `build_runner`.

### Service Layer
Business logic in `lib/services/` — Supabase queries, access control, auth, storage:
- `auth_service.dart` — Sign in/up, session management
- `access_control.dart` — World access gating
- `permission_service.dart` — Post delete, moderation checks
- `world_service.dart`, `chat_service.dart`, `post_service.dart`, `profile_service.dart`
- `storage_service.dart`, `invite_service.dart`, `backup_service.dart`

### Routing
`lib/router/app_router.dart` — Single `GoRouter` provider with:
- **Auth guard**: `redirect` function checks session + resident status
- **5 tab shell**: `StatefulShellRoute.indexedStack` (Nexus, Explore, Chats, Identity, Alerts)
- **Nested routes**: World detail → channel, settings, members
- **Standalone routes**: Auth (login, signup, callback), Onboarding, Achievements, Settings, Search, Create World, Resident profile, Invite accept

---

## 7. Figma-to-Flutter Translation Rules

### Layout Mapping
| Figma | Flutter |
|---|---|
| Auto Layout (horizontal) | `Row` with `mainAxisAlignment` + `crossAxisAlignment` |
| Auto Layout (vertical) | `Column` with `mainAxisAlignment` + `crossAxisAlignment` |
| Auto Layout gap | `SizedBox(width/height: Spacing.*)` |
| Absolute position | `Stack` + `Positioned` |
| Padding | `EdgeInsets.all(Spacing.*)` or `EdgeInsets.symmetric(horizontal: Spacing.*, vertical: Spacing.*)` |
| Fill container | `Expanded` or `double.infinity` width |
| Hug contents | `MainAxisSize.min` |
| Corner radius | `BorderRadius.circular(RadiusTokens.*)` |

### Color Mapping
| Figma | Flutter |
|---|---|
| Named variable matching `AppColors.*` | Use the `AppColors.*` token directly |
| `surface` / `surface-container` in light | Let Material 3 derive from seed |
| `surface` / `surface-container` in dark | Map to nearest `AppColors.darkSurface*` |
| Gradient (2 stops) | Map to existing `AppColors.gradient*` or create new list |
| Opacity overlay | Use `.withValues(alpha: AppColors.alpha*)` |

### Typography Mapping
| Figma | Flutter |
|---|---|
| Named text style | Use `ThemedText` with matching `ThemedTextType` |
| Font size | Round to nearest `FontSizes.*` |
| Font weight | Map to `FontWeights.*` (400/500/600/700 only) |
| Letter spacing | Map to `LetterSpacing.*` — headings ALWAYS use `heading: -1.5` |
| Line height | Map to `LineHeight.*` |
| Color | `theme.colorScheme.onSurface` or `theme.colorScheme.onSurfaceVariant` |

### Component Mapping
| Figma Component | Flutter Widget | Notes |
|---|---|---|
| Primary CTA button | `TactileButton` | Use for main actions, supports icon + label + fullWidth |
| Secondary button | `OutlinedButton` | Styled by `AppTheme.outlinedButtonTheme` |
| Text button | `TextButton` | Use for tertiary actions |
| Card | Custom `Container` with `BoxDecoration` | Do NOT use Material `Card` — use the container pattern with `RadiusTokens.lg` + border |
| Input field | `TextField` + `InputDecoration` | Styled by `AppTheme.inputDecorationTheme` |
| Avatar (framed) | `CosmeticAvatar` | XP-gated frame colors |
| Avatar (plain) | `CircleAvatar` + `NetworkImage` | Use inside `GestureDetector` for tap-to-profile |
| Tab bar | Custom pill bar in `TabLayout` | 5-tab bottom nav with animated indicator + center FAB |
| Bottom sheet | `showModalBottomSheet` | Use `RadiusTokens.xl` top corners |
| Dialog | `showDialog` + `AlertDialog` | Styled by `AppTheme.dialogTheme` |
| Chip / Badge | `InputChip` or custom `Container` | `AppTheme.chipTheme` for standard chips |
| Skeleton | `Shimmer` / `ShimmerPostCard` / `ShimmerChatTile` | Gradient-sweep loading placeholders |
| Empty state | `AppEmptyState` | Has icon, title, description, optional CTA, variant colors |
| Error state | `AppErrorState` | Pre-configured error with retry |
| Progress bar | `AnimatedProgressBar` | Duolingo-style with optional percentage label |
| World card | `WorldCard` | Banner thumbnail + icon overlay + metadata badges |
| Post card | `PostItem` | Avatar header + content + images + reactions + comments |
| Reaction chips | `ReactionBar` | Horizontal chips with burst animation + long-press menu |
| Image viewer | `ImageViewer.show()` | Fullscreen pinch-to-zoom |

### Required States for Every Component
When implementing a Figma component, ALWAYS build these 5 states:
1. **Default** — the designed happy path
2. **Loading** — use `Shimmer` / `ShimmerPostCard` / `ShimmerChatTile` skeleton
3. **Empty** — use `AppEmptyState` with contextual icon + message
4. **Error** — use `AppErrorState` with optional retry callback
5. **Disabled** — apply `AppColors.alphaDisabled` (0.38) opacity

### Animation Guidelines
- All list items get `FadeIn(delayMs: index * 60~70)` for staggered entrance
- Button presses use `HapticFeedback.lightImpact()` + brief scale animation
- Page transitions are handled by Material routing (no custom page transitions yet)
- Don't animate dark/light mode switch — it's instant via `AnimatedSwitcher` (250ms)
- Tabs use `AnimCurves.spring` for the indicator position

### Config-Driven Design
Many screens are driven by static config in `lib/config/`:
- **Tiers**: `tiers.dart` — tierNames (5 tiers), standingLevels (7 standing levels), featureUnlocks, prestige calculation, `worldsConfig` (17 worlds)
- **Cosmetics**: `cosmetics.dart` — cosmeticFrames (5 XP-gated frames), professionCosmetics (6 professions with colors + icons), decorationTypes
- **Achievements**: `achievements.dart` — achievement definitions

When Figma shows new tier/frame/world/achievement data, add it to these config files first, then the UI reads from them.
