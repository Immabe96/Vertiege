# Vertiege → React Native rebuild (from scratch)

**Decision:** 2026-09-18 — rebuild the Vertiege client **from scratch** in **React Native + Expo + TypeScript**.
**Design decision:** 2026-09-25 — the new app's visual language is **Neobrutalism**, sourced from **[neobrutalism.dev](https://www.neobrutalism.dev/docs/installation)**, **`yellow` palette**, **light-only**. It replaces both `DESIGN.md` (warm gold / Fraunces) and Prestige Noir (cool graphite / `#C9A227`) as the *client* direction. NativeWindUI is dropped as the UI kit (§3, §9).
**Scope:** everything is new — code, architecture, and visual design. No Flutter code, no Renewal theme carryover. The only things taken from the Flutter app are **keys and logins** (§4) and the **backend contract** (§5).
**Design note:** `DESIGN.md`, `docs/design/s12-renewal/`, and the Prestige Noir system remain valid *Flutter* artifacts. They are **not** applied to the RN client. See §7.

### Status (2026-09-25)

| Phase | State | Evidence |
|---|---|---|
| Repo restructure (Phases 0–6) | ✅ done | commit `c345539` (`flutter-app/`, `expo-app/`) |
| ✅ **P0 — Design identity — DONE (2026-09-25)** | ✅ done | `lib/theme/tokens.ts` + `tailwind.tokens.json` + `scripts/gen-tokens.mjs` (prettier-formatted output; `npm run tokens` / `tokens:check`) · NativeWindUI kit deleted · `useColorScheme`/`NAV_THEME` removed · `docs/design.md` written · `test/tokens.test.ts` (contrast AA, light-only, hex-scrape, platform-config sync) |
| ✅ **P1 — Primitive kit + shell — DONE (2026-09-25)** | ✅ done | 23 primitives in `components/ui/` · `/design` dev route · `you` → `identity` tab · `lib/router/resolve-redirect.ts` (chain + single-hop) · jest infra (`test/setup.ts` + mocks) |
| P2 — Data layer | ⬜ next | |

**Gates at this point:** `npm run check` = `tokens:check` + `tsc --noEmit` + eslint + prettier + jest → **7 suites / 107 tests green**; `npx expo export --platform ios` smoke also green.

**P1 details worth carrying into the next session:**
- `@testing-library/react-native` v14 — `render`, `rerender`, `fireEvent` are **async** (must be awaited); `screen` throws if `render` wasn't awaited. Destructured renders must be awaited too.
- Role queries only match *accessibility elements*: a `View` with `accessibilityRole` also needs `accessible` (Text / Pressable / Switch pass without it). Fixed on `Progress`, `DropdownMenu`, `AlertDialog`, `Tabs`.
- `jest.mock()` factories may contain only `require()` calls — the Nativewind Babel preset rewrites `React.createElement`, so any JSX or out-of-scope reference in a factory fails.
- `lucide-react-native` is ESM → `moduleNameMapper` points it at its CJS build; `react-native-reanimated/mock` needs native worklets → `test/mocks/react-native-reanimated.ts`.
- Reanimated `shared.value` writes inside hook callbacks trip `react-hooks/immutability`; `components/ui/sheet.tsx` routes them through the module-scope `writeDrag()`.
- Upstream registry is `https://neobrutalism.dev/r/<name>.json` (docs at `/docs/<name>`); **`nbutton` and `separator` do not exist upstream** — `separator` is our own (same rule as Flutter's `VDivider`), `nbutton` was dropped from §9.1.

---

## 1. Strategy

- Fresh folder `expo-app/` (scaffolded: `rn-new --nativewindui`, i.e. Expo Router + NativeWind + Reanimated on Expo SDK 56 / RN 0.85). The scaffold's NativeWindUI kit is **kept only as scaffolding** — its components are deleted in P0 and replaced by the neobrutalism.dev port (§9). NativeWind (the styling engine) stays.
- The Flutter app keeps shipping the closed beta (Play + TestFlight) until the new app passes review on both stores; then it is archived as `legacy-flutter/`.
- Supabase/Firebase are the only shared runtime; backend tables, RLS, storage buckets, and edge functions are reused as-is.

## 2. Repo layout

```
Vertiege/
  flutter-app/…                # Flutter app — untouched until cutover (shipping beta)
  expo-app/                    # NEW: fresh Expo app (Expo Router)
  supabase/                    # backend source of truth (migrations, functions) — unchanged
  docs/design/s12-renewal/     # design exploration history (not applied)
```

Paths below are repo-root relative (`expo-app/…`) unless noted.

## 3. Stack (user choices + "Choosing the Right React Native Stack in 2026", Simon Grimm)

| Concern | Choice | Notes |
|---------|--------|-------|
| Framework | Expo SDK 56 + TypeScript + Expo Router | scaffolded; typed routes on |
| Styling | **NativeWind v4 + Tailwind 3.4** | tokens live in `tailwind.config.js` + `global.css`. **NativeWind v5** is CSS-first `@theme` — not adopted. |
| UI kit | **[neobrutalism.dev](https://www.neobrutalism.dev/docs/installation) — hand-ported to RN** | Tokens + variant API + class signatures are the source of truth; each component is reimplemented on RN primitives with NativeWind + CVA (see §9). **NativeWindUI is dropped** — `components/nativewindui/` is deleted in P0. |
| Animation/gesture | Reanimated 4 + Gesture Handler (worklets plugin) | installed |
| Client state | Zustand | persists via MMKV |
| Server state | **TanStack Query — the only server-state owner** | `useQuery`/`useMutation`; zero direct `supabase.from()` in components |
| Local data | **Drizzle + expo-sqlite — local-only** | drafts, outbox, message search index. **Not** a server mirror. |
| Key-value | MMKV (not AsyncStorage) | prefs, feature flags, onboarding state; SecureStore stays for auth tokens |
| Forms | React Hook Form + Zod | typed, validated |
| Lists | FlashList | installed, currently unused |
| Backend | Supabase (Postgres + Auth + Realtime + Storage + Edge Functions) | existing project reused |
| Auth | **Supabase Auth** (not Clerk) | RLS uses `auth.uid()`; keeps logins + `vertiege://auth/callback` |
| Build/ship | EAS | `eas.json` still to be created (P11) |
| Monitoring | Sentry · PostHog · Crashlytics | P11 |
| IAP | RevenueCat | only if S10.21 unpauses IAP |

**State-ownership rule (non-negotiable):** TanStack Query → server. Drizzle → local. MMKV → prefs. Zustand → ephemeral UI/session state. Anything else is a bug.

## 4. Keys & logins (extracted from the Flutter app)

| Item | Value | New home |
|------|-------|----------|
| Supabase URL | `https://wjaphoaxalvgjnrwqjwe.supabase.co` | `expo-app/.env` → `EXPO_PUBLIC_SUPABASE_URL` ✅ |
| Supabase anon key | from Flutter `.env` (public, RLS-protected) | `EXPO_PUBLIC_SUPABASE_ANON_KEY` ✅ |
| App identity | name Vertiege, scheme `vertiege`, android/iOS `com.vertiege` | `expo-app/app.json` ✅ |
| OAuth redirect | `vertiege://auth/callback` | Supabase Auth config (unchanged) + Expo scheme |
| Firebase project | `veritage` · sender `92526224561` | `expo-app/config/firebase.ts` (P11) |
| Firebase Android | apiKey `AIzaSyBZTPAlGRd_kMw743Fe0qJkVHNeeJySU80`, appId `1:92526224561:android:7b7a9f6f448f61ca7cae90` | same |
| Firebase iOS | apiKey `AIzaSyDlrYB-KZskQuktszLXHMZ5NGLpp2fJQIY`, appId `1:92526224561:ios:29b2459028dca5757cae90` | same |
| Google OAuth clients | android `…-d4q4ecq0b6v1kfd4sh2l8im2t27pedce…`, ios `…-oq7m8j0fgqmbqadcluhvc1h6lqvq7709…` | expo-auth-session (P3) |
| Storage buckets | avatars, post-media, world-banners, world-icons, marketplace-media, chat-attachments, verification-proofs (private) | backend, unchanged |

`expo-app/.env` is gitignored; `EXPO_PUBLIC_*` are build-time embedded (anon key is public by design — security is RLS).

## 5. Backend contract (reused as-is)

- **Supabase:** auth (email + Google + Apple, redirect `vertiege://auth/callback`), Postgres + RLS (source of truth), Realtime, the 7 storage buckets, Edge Functions: `send-push`, `livekit-token`, `verify-subscription-purchase`, `delete-account`, `moderate-content`.
- **Firebase:** FCM push (via `send-push`), Crashlytics, Analytics, Remote Config, App Check.
- **Rules:** no `service_role` and no Firebase service-account JSON in the client, ever. CI gate: `expo-app/scripts/check_no_service_role_in_app.sh` (P2).

### 5a. Contract gaps to close before/during the rebuild

| # | Gap | Where |
|---|-----|-------|
| 1 | Repo has **126 `CREATE TABLE` statements across `supabase/migrations/` + `migrations_archive/`**; the baseline lives in `migrations_archive/fresh_project_only/`. Replaying migrations is not guaranteed reproducible. | Pull the **live** schema instead: `supabase db diff` / `gen types typescript` against project `wjaphoaxalvgjnrwqjwe`. |
| 2 | Realtime publication membership is split across active + archived migrations. Flutter subscribes to **10 tables** (`posts`, `chat_messages`, `channel_messages`, `dm_rooms`, `dm_reads`, `dm_typing`, `notifications`, `profiles`, `user_achievements`, `verification_submissions`) across **14 channels**. | Verify publication membership on the **live** project before writing the realtime manager. |
| 3 | `dm_rooms` / `dm_reads` / `notifications` publication membership unconfirmed. | Live check; add migration if missing. |
| 4 | Edge functions `generate-totp` / `verify-totp` / `enroll-totp` referenced by client code **do not exist** in `supabase/functions/`. | P7 identity work — either create them or drop the client path. |
| 5 | `verification-proofs` storage path convention mismatch between client and RLS policies. | P7 — confirm policy, match builder. |
| 6 | 5 remote-only tables with no client mirror: `world_streaks`, `spotlight_history`, `sanctuary_moods`, `sanctuary_gratitude`, `debug_logs`. | Read via TanStack Query only. |
| 7 | `delete-account` edge function references a non-existent `dm_messages` table (live table is `chat_messages`). | Fix in `supabase/functions/delete-account/` (backend, not client). |
| 8 | `receipt_edge_verify` prod value unverified. | P9 — confirm before RevenueCat work. |
| 9 | `create_post` RPC returns HTTP 300. | P2 typed wrapper must handle non-2xx → typed error. |
| 10 | No `eas.json`, no App Check `X-Firebase-AppCheck` header wiring. | P11. |
| 11 | No `service_role` scanner for `expo-app/`. | Add `expo-app/scripts/check_no_service_role_in_app.sh` in P2, wire into `npm run check`. |

> Backend scale reference: ~70 tables (live), ~58 RPC names, 14 realtime channels, 7 storage buckets, 5 edge functions.

## 6. Product pillars

1. **Home feed** — Nexus moments/feed with streak, quests, tier visibility.
2. **Worlds** — discovery, world detail with channels and 13 sub-pages.
3. **Chat** — DMs, world channels, threads, reactions, typing, presence, voice.
4. **Profile/You** — identity, stats, tier progress, achievements, connections, settings.
5. **Progression & economy** — quests, season, leagues, streaks, shop, subscription.

Backend tables/RLS not used by a pillar simply stay dormant.

---

## 7. Design system — Neobrutalism (P0)

**Source of truth:** [neobrutalism.dev](https://www.neobrutalism.dev/docs/installation) — its styling registry, token names, component variant API, and class signatures. **Palette: `yellow`** (of blue · yellow · green · violet · purple · orange).
**Why:** the library's gold `main` (`#FACC00`) is continuous with Vertiege's shipped brand (`#C9A227`); the system is token-cheap, disciplined (hard borders, zero blur), and its CVA variant API maps cleanly onto RN.
**⚠️ Constraint:** the upstream `.tsx` components are **React DOM + `@base-ui/react` + Tailwind-web** (`hover:`, `focus-visible:ring`, `@container`, `data-[size=]`). They **cannot run in Expo/RN** — `shadcn add` would drop uncompilable files. We therefore **hand-port**: same tokens, same variant names, same class semantics, RN primitives. Full rules in §9.

### 7.1 Upstream tokens → our tokens

Verbatim from `https://neobrutalism.dev/r/styling/yellow.json` (`cssVars.light` + `cssVars.theme`). Master file: `expo-app/lib/theme/tokens.ts` → consumed by `tailwind.config.js` + `global.css`. Every literal appears exactly once.

| Upstream token | Value | Maps to |
|---|---|---|
| `--background` | `hsl(54,92%,88%)` = `#FDF7C4` | `bg-background` — app ground. **Tinted, not white.** |
| `--secondary-background` | `#FFFFFF` | `bg-secondary-background` — cards, inputs, sheets |
| `--main` | `hsl(49,100%,49%)` = `#FACC00` | `bg-main` — CTAs, active nav, progression |
| `--main-foreground` | `#000000` | `text-main-foreground` — **never** white on yellow |
| `--foreground` | `#000000` | `text-foreground` — ink: text *and* borders |
| `--border` | `#000000` | `border-border` — 2px, always ink |
| `--ring` | `#000000` | focus outline |
| `--shadow` | `4px 4px 0 0 var(--border)` | `shadow-shadow` — hard, **zero blur**, always matches border |
| `--overlay` | `rgb(0 0 0 / 0.8)` | scrim behind sheets/dialogs |
| `radius-base` | `5px` | `rounded-base` |
| `font-weight-base` | `500` | `font-base` |
| `font-weight-heading` | `700` | `font-heading` |
| `spacing-boxShadowX/Y` | `4px` / `4px` | press = translate(4,4) + shadow off |
| `spacing-reverseBoxShadowX/Y` | `-4px` / `-4px` | `reverse` variant = translate(-4,-4) + shadow on |

**Vertiege additions (not upstream)** — the library ships a single `main`; a social app needs status and reference colour:

```
--secondary          #432DD7   violet — links/mentions (continuity with shipped #7C3AED)
--success            #16A34A
--warning            #D97706
--danger             #DC2626
--muted              #F1F1F1   input tracks, disabled fills
--muted-foreground   #3F3F46   secondary text (AA ≥ 4.5:1 on #FFFFFF)
--background-raised  #FFF6D6   hero cards / selected rows — one step up from ground
```

### 7.2 Light-only (dark mode dropped)

Upstream `cssVars` exposes **`light` only — there is no dark palette.** Decision: **light-only, drop dark entirely.** Delete `ThemeToggle`, `useColorScheme`, `NAV_THEME` system theming; a single token set; **no `dark:` variants anywhere**. Faithful to source, halves the design surface, removes a whole class of contrast bugs.

### 7.3 Type

- **Display / headings / buttons:** Space Grotesk **700** (`font-heading`) — matches `font-weight-heading: 700`. **To install.**
- **Body / UI:** Plus Jakarta Sans **500** (`font-base`), 600 for emphasis — matches `font-weight-base: 500`. Already installed.
- Load with `useFonts` in `app/_layout.tsx` and block render — weight *is* the design; a fallback flash reads as broken.
- **Four steps:** 12 (caption) · 14 (small) · 16 (body) · 20 (title) · 28 (section); 34 reserved for hero/empty-state display.
- No thin weights, no optical-size tricks. Tabular numerals where stats stack.

### 7.4 Shape, border, elevation

- `rounded-base` = **5px** on everything. **Exceptions (`rounded-full`):** avatars, status dots, switch thumb — and the switch track, which upstream itself rounds.
- Borders: `2px solid var(--border)` on every card, input, badge, chip, tile, sheet, dialog. Never a muted hairline.
- Elevation = `shadow-shadow` only — `4px 4px 0 0 #000`, **zero blur**. No opacity-elevation, no glass, no gradients, anywhere.
- **Press** (the signature interaction): translate by `boxShadowX/Y` (4px, 4px) and drop the shadow → the element reads as physically depressed. **80ms `ease-out`.** The `reverse` variant inverts this.
- Spacing: 4px base — `4 / 8 / 12 / 16 / 24 / 32 / 48`. Borders eat room, so padding runs generous (cards `24` per upstream `--card-spacing`, rows `12`).
- **Touch targets ≥ 44px** even where the visual box is smaller — thick borders shrink perceived hit area.

### 7.5 Motion

| Class | Duration | Easing |
|---|---|---|
| Press / focus state | ≤ 80ms | `ease-out` |
| Screen / sheet / dialog enter | ≤ 150ms | `ease-out` |
| Everything else | ≤ 150ms ceiling | — |
| Reduced motion | 0ms (state change only, no transform) | — |

No parallax, no spring overshoot on chrome, no long fades. Motion confirms; it never decorates.

### 7.6 Written rules (goes in `expo-app/docs/design.md`, written in P0)

**Do**
- One loud accent doing heavy lifting per screen: `main` yellow = do-this, violet = go-there (link/mention), green/amber/red = status only.
- Hierarchy from **weight, border, and colour** — never from shadow blur.
- Solid fills only. Separate sections with whitespace first, borders second.
- Every state change is visible (default / pressed / focus / disabled / loading / error).

**Don't (anti-patterns — review checklist)**
- gradients · `backdrop-blur` / `box-shadow` blur · `opacity` as elevation · `rounded-lg`/`xl` on chrome · more than one accent shouting per screen · white text on `main` · grey/muted borders · `rounded-full` outside avatars/dots/thumbs · transitions > 150ms · **any `dark:` variant or `useColorScheme` branch** (see 7.2) · `nativewindui` imports.

**Accent discipline:** yellow = action. Violet = reference (our addition, not a second brand accent). Green/amber/red = status only.

---

## 8. Page inventory

Flutter source of truth: `flutter-app/lib/router/` (12 files, 1,730 lines). Tabs are **Nexus `/` · Worlds `/worlds` · Chat `/chat` · You `/identity`** — note Expo currently has `you` as a tab and no `identity`; **rename in P1**.

### 8.1 Tab roots (4)

| Route | Flutter screen | Expo | Phase |
|---|---|---|---|
| `/` | `NexusScreen` | `app/(tabs)/index.tsx` ✅ placeholder | P4 |
| `/worlds` | `ExploreScreen` | `app/(tabs)/worlds.tsx` ✅ placeholder | P5 |
| `/chat` | `ChatListScreen` | `app/(tabs)/chat.tsx` ✅ placeholder | P6 |
| `/identity` | `YouScreen` | → rename `you.tsx` → `identity.tsx` | P7 |

### 8.2 Auth & entry (7)

`/login` · `/signup` · `/onboarding` · `/auth/callback` · `/subscription` · `/invite/:code` · `/the-gate`

→ **P3.** `/the-gate` is `TheGateScreen` (debug/entry spike) — **dropped**; `/debug/ui-spike` **dropped**; `/splash_screen.dart` has no RN equivalent (Expo boots to `/`). `/admin/verifications` → **redirect alias** to `/verifier/review`.

### 8.3 Feed / Nexus (7)

`/` feed · `/post/:postId` · `/post/:postId/comments` · `/search` · `/following` · `/notifications` · `/notifications/:id` → **P4** (notifications also P10)

### 8.4 Worlds (16 + 13 sub-pages) → **P5**

Top: `/explore` · `/explore/discover` · `/explore/:worldId` · `/create-world` · `/campfire/:channelId` · `/audit-log/:worldId`

Sub-pages under `/explore/:worldId/`: `settings` · `members` · `marketplace` · `polls` · `treasury` · `challenges` · `jobs` · `archive` · `academy` · `sanctuary` · `manage` · `governance` · `:channelName`

Plus `world_route_redirects.dart` segment mapping (`/explore/$worldId/$segment`) → pure `resolveWorldSegment()` helper.

### 8.5 Chat (5) → **P6**

`/chat/:roomId` · `/dm/:roomId` · `/thread/:messageId` · plus tab `/chat`. Campfire channels route here behind `FeatureFlags.campfireEnabled`.

### 8.6 Profile & identity (7) → **P7**

`/you` · `/more` · `/residents/:id` · `/allies` · `/settings` · `/identity` (tab) · `/twin-seal`

### 8.7 Achievements & progression (9) → **P8**

`/achievements` · `/achievements/submit` · `/achievements/:category` · `/progress` · `/season` · `/challenges` · `/daily-quests` · `/leagues` · `/hall-of-ascension` · `/ascension-path`

### 8.8 Economy, admin, verifier (7) → **P9**

`/shop` · `/coin-history` · `/subscription` · `/verifier/login` · `/verifier/review` · `/more` (hub) · `/audit-log/:worldId`

### 8.9 Redirect aliases to preserve (8)

`/admin/verifications` → `/verifier/review` · bare `/explore` → `/worlds` · `/?panel=discover` → `/explore/discover` · `/?world=<id>` → `/explore/<id>` · host deep links `auth|verifier|invite|residents|post|world|chat|notifications` (`deep_link_redirects.dart`).

### 8.10 Not ported

`/the-gate`, `/debug/ui-spike`, splash screen. Everything else carries over — **zero feature removal**, per the S12 target.

**Total: ~47 top-level routes + 13 world sub-pages ≈ 60 URL shapes → ~50 real screens.**

---

## 9. Widget / primitive inventory

### 9.1 Port rules — neobrutalism.dev (web) → RN

Upstream source: `https://neobrutalism.dev/r/<name>.json` (shadcn registry items) + the `/docs/<name>` pages. **Files are copied as reference, not imported** — they are React DOM + `@base-ui/react` and will not compile in Expo. Each is rewritten against the same class signature.

**Translation table (applies to every ported component):**

| Upstream (web) | RN equivalent |
|---|---|
| `<div>` / `<span>` | `View` |
| `<button>` | `Pressable` + `accessibilityRole="button"` |
| `<input>` / `<textarea>` | `TextInput` (`multiline`) |
| `hover:translate-x-boxShadowX hover:translate-y-boxShadowY hover:shadow-none` | `pressed` state → `translate(4,4)` + shadow off (Reanimated, 80ms) |
| `focus-visible:ring-2 ring-offset-2` | `focused` state → `borderWidth: 3` (2→3) — no ring/offset on RN |
| `transition-all` / `transition-colors` | Reanimated `withTiming(…, {duration: 80})` |
| `disabled:opacity-50` | `disabled` prop → opacity 0.5 |
| `data-checked:` / `data-disabled:` | explicit boolean props on our component API |
| `shadow-shadow` | `boxShadow: '4px 4px 0px 0px #000'` (RN 0.76+) + `elevation` on Android |
| `rounded-base` | `5px` via `tailwind.config.js` |
| `whitespace-nowrap` | `numberOfLines={1}` |
| `[&_svg]:size-4`, `@container/…`, `selection:`, `file:`, `::-webkit-…` | dropped (not applicable) |
| `lucide-react` | `lucide-react-native` (same icon names) |
| `class-variance-authority` + `cn()` | **keep** — CVA works fine in RN |
| `@base-ui/react/*` primitive | RN primitive + our own a11y wiring (`accessibilityRole`, `accessibilityState`, `accessibilityLabel`) |

**Naming:** upstream files are kebab-case (`components/ui/button.tsx`) — match it, so future registry pulls line up.

**Coverage set to port first** (needed by §8, in this order): `button` · `button-group` · `card` · `input` · `textarea` · `select` · `switch` · `checkbox` · `badge` · `avatar` · `dialog` (+ `alert-dialog`) · `sheet` · `toast` · `tabs` · `progress` · `skeleton` · `empty` · `label` · `tooltip` · `dropdown-menu` · **`separator`** (our own — no upstream counterpart, same call as Flutter's `VDivider`). The originally planned `nbutton` does not exist upstream (404 on registry and docs) and was dropped — `Button` covers it. Everything else (`calendar`, `data-table`, `carousel`, `combobox`, `command`, `chart`, `marquee`, `sidebar`, …) is deferred until a screen needs it. **All of the above are ported (23 files in `components/ui/`) and covered by `test/ui.test.tsx` (49 tests).**

**Out of scope by nature:** `hover-card`, `popover`, `context-menu`, `resizable`, `scroll-area`, `navigation-menu`, `breadcrumb`, `marquee`, `table` (use FlashList) — pointer/hover/keyboard concepts that don't map to touch.

### 9.2 Coverage requirement — Flutter facade → RN

`flutter-app/lib/ui/` is **39 files / 3,874 lines** across 10 folders. Not copied — it defines *what the kit must be able to express*. Every row below must be satisfiable from the §9.1 coverage set (composing where needed):

| Flutter `lib/ui/` | files / lines | RN shape |
|---|---|---|
| `buttons/` | 3 / 318 | `Button` (variants × sizes), `IconButton`, `GateCta` |
| `cards/` | 2 / 181 | `Card`, `Card` w/ `--background-raised` → `HeroCard` |
| `feedback/` | 6 / 514 | `Badge`, `Alert`, `Toast`+`Feedback`, `EmptyState`/`ErrorState`/`LoadingState`, `SyncBadge`, `WorldBadge` |
| `icons/` | 1 / 292 | `Icon` — **lucide-react-native** (replaces Ionicons) |
| `inputs/` | 5 / 430 | `Input`, `SearchBar`, `Select`, `Switch`, `FormField` (textarea folds in) |
| `lists/` | 5 / 464 | `SectionList` (FlashList), `Tile`, `SwitchTile`, `PerkTile`; `ChannelTile`/`AchievementCategoryTile` **not ported** (single-use, inline) |
| `media/` | 2 / 247 | `Avatar`, `Image` |
| `navigation/` | 4 / 643 | `BottomNav`, `Tabs`, `WorldRail`, `WorldSwitcherSheet` |
| `overlays/` | 3 / 334 | `Sheet`, `Dialog`, `ContextMenu` |
| `shell/` | 7 / 413 | `Header`, `HeaderAction`, `NestedHeader`, `Page`, `Scaffold`; `VTabShell`/`VOverlappingPanels` **not ported** (Expo Router owns shells) |

**Reuse rank to design for:** `VButton` (231 references — the most-used primitive in the app), `VCard` (45), `VSectionList` (20), then the feedback trio (empty/error/loading) and toast.

### 9.3 Shared widgets → `components/features/<domain>/`

`flutter-app/lib/widgets/` = **202 files / 34,471 lines**. Not ported wholesale — only what screens actually compose. Domain split for sizing:

| Domain | Flutter LOC | RN home |
|---|---|---|
| worlds | ~9,700 | `features/worlds/` |
| chat | ~5,200 | `features/chat/` |
| feed | ~4,200 | `features/feed/` |
| core | ~3,400 | `lib/` + `components/ui/` |
| profile | ~3,200 | `features/profile/` |
| achievements | ~2,500 | `features/progression/` |
| nexus | ~2,700 | `features/feed/` |

Priority pulls from `widgets/core/` (cross-domain, high reuse): `empty_state`, `error_banner`, `loading_state`, `shimmer`, `offline_banner`, `sync_warning_banner`, `mutation_outbox_sync_banner`, `notification_bell`, `tier_badge`, `status_dot`, `image_viewer`, `v_dialog`, `v_feedback`, `xp_toast`, `glass_sheet` (→ rebuilt as a bordered sheet, no blur).

**Not ported (orphans / superseded):** `VTabShell`, `VOverlappingPanels`, `VInput`, `VImage`, `VBadge`, `VDotBadge`, `VWorldBadge`, `VSyncStatusBadge`, `VChannelTile`, `VAchievementCategoryTile`, `VContextMenu`, `VAlert`, `bento_grid`, `nexus_notifications_sheet`, `splash_screen`.

### 9.4 Overlay scale

~35 sheet + ~40 dialog call sites in Flutter → the RN `Sheet`/`Dialog` primitives must be correct on **first** try; they are load-bearing for P4–P9. Both get drag-to-dismiss, keyboard avoidance, `--overlay` scrim at `rgb(0 0 0 / 0.8)`, `2px` border, and `shadow-shadow`.

---

## 10. Build phases

`npm run check` (`tsc --noEmit` + eslint + prettier + jest) must be green at the end of **every** phase.

| Phase | Scope | Exit |
|---|---|---|
| **P0 — Design identity** | `lib/theme/tokens.ts` (yellow palette, §7.1) + `tailwind.config.js` (`main`, `background`, `secondary-background`, `foreground`, `border`, `ring`, `overlay`, `rounded-base: 5px`, `shadow-shadow`, `font-base/heading`) + `global.css` · install Space Grotesk + `lucide-react-native`, load both with `useFonts` (block render) · **delete `components/nativewindui/`** (`Button`, `Text`, `Icon`, `ThemeToggle`) and repoint its 6 importers (`app/index`, `app/+not-found`, `app/(auth)/login`, `app/(tabs)/{index,chat,worlds,you}.tsx`) · **remove all `useColorScheme`/`NAV_THEME` dark-mode machinery** (§7.2) · `expo-app/docs/design.md` with §7 rules + anti-patterns | Tokens render on screen; contrast-checked (black on `#FDF7C4` ≥ 4.5:1, `#000` on `#FACC00` ≥ 4.5:1); no `dark:` variant or `useColorScheme` left in `expo-app/`; `npm run check` green | **Met:** `test/tokens.test.ts` (contrast + light-only + hex-scrape) · two documented hex exceptions (`app.json`, `app/+html.tsx`) asserted by the same test |
| **P1 — Primitive kit + shell** | Port the §9.1 coverage set into `components/ui/*.tsx` (kebab-case) using the web→RN translation table · `/design` dev route rendering every primitive × every state · 4-tab shell with `identity` rename · 3 transition families (tabs = `animation: 'shift'`, push = root `Stack` `slide_from_right`, sheet = `Sheet`/`Dialog` Reanimated enters) · `resolveRedirect()` **pure function** ported from `app_router.dart` + `deep_link_redirects.dart` + `app_auth_redirect.dart` with unit tests (Flutter backlog S9-A7) | **Met:** `test/ui.test.tsx` 49/49 (per-state component tests) · `test/redirect.test.ts` 26/26 · `test/tokens.test.ts` · coverage rows in §9.2 satisfiable |
| **P2 — Data layer** | `supabase gen types typescript` → `lib/api/generated.ts` · `queryKeys` + typed hooks for every table/RPC · typed RPC wrappers incl. `create_post` HTTP-300 handling · **one realtime manager** for all 14 channels (single reconnect/backoff owner) · Drizzle tables `drafts`, `outbox`, `message_index` · Remote Config flag reader (incl. `campfireEnabled`) · storage path builders · `check_no_service_role_in_app.sh` in `npm run check` | Read paths live against real data; security gate wired |
| **P3 — Auth** | login · signup · onboarding · password reset · Google + Apple OAuth (`vertiege://auth/callback`) · `/auth/callback` · subscription entry · invite deep links | Full auth surface; cold start → correct route |
| **P4 — Feed / Nexus** | feed + composer (drafts via Drizzle) · post detail · comments · reactions · threads · search · `/following` | Core loop 1 end-to-end |
| **P5 — Worlds** | explore/discover · world detail · 13 sub-pages · channels · `:channelName` · create-world · campfire (behind flag) · invite · audit-log | Core loop 2 end-to-end |
| **P6 — Chat (highest risk)** | DM inbox · room · threads · reactions · typing (realtime + `dm_typing` table) · presence · read receipts (`dm_reads`) · **Drizzle outbox + retry** for send · LiveKit voice via `livekit-token` | Core loop 3 end-to-end, incl. offline send |
| **P7 — Profile & identity** | profile · `/residents/:id` · allies · more hub · settings · Identity verification flow · TOTP (blocked on gap #4) · `delete-account` (gap #7) | Identity loop complete |
| **P8 — Achievements & progression** | achievements + category + proof submit (storage) · progress · season · leagues · challenges · daily quests · hall of ascension · ascension path (tier-gated) | Progression loop complete |
| **P9 — Economy, admin, verifier** | shop · coin-history · subscription (RevenueCat if unpaused) · verifier login + review portal · twin-seal · audit-log | Economy + staff tools complete |
| **P10 — Notifications & retention** | unified inbox · FCM push via `send-push` · deep-link routing for all 10 notification types (`notification_navigation.dart`) · quiet hours · notification prefs | Push + inbox live |
| **P11 — Hardening & launch** | reduced-motion · a11y pass · empty/error/offline states audit · Sentry + PostHog + Crashlytics + Remote Config + App Check · `eas.json` · EAS builds · store beta review | Both stores green |
| **P12 — Cutover** | Flutter app archived to `legacy-flutter/`; repo docs updated | Rewrite is the shipping client |

**Sequencing constraints:** P1 before any P3–P10 UI · P2 before P3 · P6 depends on P2 + P1 (outbox, realtime) · P10 depends on P6 (chat notifications) and P4 · P11 last.

---

## 11. Testing & quality gates

- **Unit:** redirect logic (pure fn, table-driven), token contrast ratios, RPC wrappers, outbox retry.
- **Component:** every `components/ui/` primitive × states (default/pressed/focus/disabled/loading/error), plus a screenshot/`/design` route diff so a token change is visible in review.
- **Integration:** auth boot, feed load, realtime reconnect, offline send → outbox flush.
- **Repo gates (CI order):** `npm run check` · `check_no_service_role_in_app.sh` · `expo export --platform ios` smoke · existing Flutter gates untouched.
- `flutter analyze` + `flutter test` (299) keep running until P12 — the beta still ships.

## 12. Risks & mitigations

| Risk | Mitigation |
|---|---|
| **Upstream components are web-only** (React DOM + `@base-ui/react`) — a straight `shadcn add` produces files that don't compile in Expo | Hand-port per the §9.1 translation table; never import upstream files; keep the class signature + variant names identical so diffs against source stay meaningful |
| Web→RN behaviour gaps: `hover:` has no touch equivalent, `focus-visible:ring` has no ring on RN | Press ⇔ hover (translate+shadow-drop, 80ms); focus ⇔ `borderWidth` 2→3. Both are written once in the shared primitives, never re-invented per screen |
| Upstream palette/registry changes under us | Tokens are copied into `lib/theme/tokens.ts` once (§7.1); we consume our copy, not the CDN. Record the upstream commit/date in `docs/design.md` |
| Light-only drops dark mode some users expect (existing app is dark-heavy) | Deliberate (§7.2): faithful to source, halves the design surface. Revisit post-launch only with a full second token set — no per-screen `dark:` branches ever |
| Neobrutalism's loud chrome fights dense chat/feed IA | Density budget in `design.md`: 1 accent, 1 shadow depth per screen; chat rows drop the shadow, keep the 2px border |
| Realtime publication gaps (§5a #2–3) | Verify on live project in P2 before building the manager |
| Missing TOTP edge functions (§5a #4) | Flag early in P7; create functions or drop the client path |
| Firebase native modules need config | `@react-native-firebase/*` via config plugins + dev-client from day one |
| Expo Go can't run MMKV/dev-client | dev-client is the single dev target (already true) |
| Secrets in client | security gate script in `npm run check` |
| Migration replay unreproducible (§5a #1) | Generate types from live DB, never from a fresh replay |
| Chat outbox divergence from server | Drizzle outbox is local-only; conflict resolution = server wins + refetch |

## 13. Conventions (RN side)

- Structure inside `expo-app/`: `app/` routes · `components/ui/*.tsx` primitives (**kebab-case, shadcn naming**) · `components/features/<domain>/` · `lib/` services/state · `db/` Drizzle schema · `lib/theme/` tokens.
- Feature screens import **only** from `components/ui/` — never `nativewindui`, never raw colour literals. Class names come from the upstream token vocabulary: `bg-background`, `bg-secondary-background`, `bg-main`, `text-foreground`, `text-main-foreground`, `border-border`, `shadow-shadow`, `rounded-base`, `font-base`, `font-heading`.
- No hard-coded hex outside `lib/theme/`; no `isDark ?` ternaries, no `dark:` variants, no `useColorScheme` (§7.2).
- Icons: `lucide-react-native` only — same icon names as upstream.
- Press states come from the shared primitives; screens never hand-roll `pressed` translate/shadow math.
- Lexicon: world, resident, achievement, Campfire, Nexus, Identity, Ally, tier.
