# Vertiege RN — Neobrutalism

Client visual language for `expo-app/`. Flutter keeps its own system
(`flutter-app/`, `docs/reference/design-system.md`); nothing here applies to it.

**Source of truth:** [neobrutalism.dev](https://www.neobrutalism.dev/docs/installation) —
styling registry, token names, component variant API, class signatures.
**Palette:** `yellow` (of blue · yellow · green · violet · purple · orange).
**Mode:** light only.

**Values live in one place:** [`lib/theme/tokens.ts`](../lib/theme/tokens.ts).
`tailwind.tokens.json` is generated from it (`npm run tokens`) and is what
`tailwind.config.js` reads. `npm run check` fails if the JSON is stale.
`app.json` and `app/+html.tsx` carry the ground colour as literals because they
run before any module can be imported — `test/tokens.test.ts` keeps them honest.

---

## Colour

| Token | Value | Use |
|---|---|---|
| `background` | `#FDF7C4` | app ground. **Tinted, not white.** |
| `secondary-background` | `#FFFFFF` | cards, inputs, sheets |
| `background-raised` | `#FFF6D6` | hero cards, selected rows |
| `foreground` | `#000000` | body text **and** every border |
| `main` | `#FACC00` | CTAs, active nav, progression — the one loud accent |
| `main-foreground` | `#000000` | text on `main`. **Never white on yellow.** |
| `border` / `ring` | `#000000` | 2px structural border; focus ring |
| `overlay` | `#000000` @ 0.8 | scrim — use `bg-overlay/80` |
| `secondary` | `#432DD7` | links, mentions, secondary actions |
| `muted` / `muted-foreground` | `#F1F1F1` / `#3F3F46` | input tracks / secondary text |
| `success` / `warning` / `danger` | `#16A34A` / `#D97706` / `#DC2626` | **fills only** |
| `success-ink` / `warning-ink` / `danger-ink` | `#0F7A38` / `#8A4B00` / `#B3261E` | status **text** — the fills only reach ~3:1 as text |
| `success-foreground` / `warning-foreground` / `danger-foreground` | `#000` / `#000` / `#FFF` | text on that fill |

Every text pair is AA ≥ 4.5:1, asserted in `test/tokens.test.ts`.

**Light only.** Upstream ships no dark palette, so there is no `dark:` variant,
no `useColorScheme`, no `NAV_THEME`, no `prefers-color-scheme` — anywhere.

## Type

- **`font-heading`** — Space Grotesk 700 (display, section, titles)
- **`font-base`** — Plus Jakarta Sans 500 (body, labels, buttons)
- Steps: `caption` 12 · `small` 14 · `body` 16 · `title` 20 · `section` 28 · `display` 34
- Loaded in `app/_layout.tsx`; render is blocked until they resolve.
- Family names are weight-specific (`SpaceGrotesk_700Bold`), so weights are
  chosen by **family**, not by `font-bold`.

## Shape, border, elevation

- **`rounded-base` = 5px** on everything. `rounded-full` only for avatars,
  status dots, switch thumb/track.
- Borders are structural: **`border-2 border-border`** on cards, inputs, badges,
  chips, tiles, sheets, dialogs. Never a grey hairline.
- Elevation is `shadow-shadow`: **`4px 4px 0 0 #000`, zero blur** — or RN
  `boxShadow` with the same values. No `elevation`, no opacity-elevation, no
  glass, no gradients.
  - RN `boxShadow` needs the New Architecture and Android 9+; API 24–27 renders
    without the offset rather than with a blurred fallback.
- **Press** is the signature interaction: translate `+4,+4` and drop the shadow
  (the `reverse` variant does the opposite: `-4,-4` at rest, gains the shadow).
  80 ms, `ease-out`.
- Spacing on a 4px grid: `4 / 8 / 12 / 16 / 24 / 32 / 48`.
- **Touch targets ≥ 44px** even where the visual box is smaller.

## Motion

| Class | Ceiling |
|---|---|
| press / focus state | **80 ms** |
| screen / sheet / dialog enter | **150 ms** |
| reduced motion | 0 ms (state change only) |

No parallax, no spring overshoot on chrome, no long fades.

## Do

- One loud accent per screen: `main` = do-this, `secondary` = go-there,
  green/amber/red = status only.
- Hierarchy from weight, border and colour — never from blur.
- Solid fills. Separate sections with whitespace first, borders second.
- Every state visible: default / pressed / focus / disabled / loading / error.

## Don't

gradients · `backdrop-blur` · any shadow blur · `opacity` used as elevation ·
`rounded-lg`/`xl` on chrome · two accents shouting on one screen · white text on
`main` · grey borders · `rounded-full` outside avatars/dots/thumbs · transitions
over 150 ms · any `dark:` variant or `useColorScheme` · colour literals outside
`lib/theme/` · raw hex in `className`.

## Class vocabulary

Use the upstream names so call sites read like neobrutalism.dev:

```
bg-background  bg-secondary-background  bg-background-raised  bg-main
text-foreground  text-main-foreground  text-muted-foreground  text-secondary
border-border  shadow-shadow  rounded-base  font-base  font-heading
```

## Component ports

`components/ui/*.tsx` (kebab-case) are **hand-ports** — upstream `.tsx` files are
React DOM + `@base-ui/react` and will not compile in Expo. Keep the variant
names and class semantics; translate web-only behaviour:

| upstream | RN |
|---|---|
| `hover:translate… hover:shadow-none` | press state, 80 ms |
| `focus-visible:ring-2 ring-offset-2` | `borderWidth` 2 → 3 |
| `transition-all` | `withTiming(80ms)` |
| `lucide-react` | `lucide-react-native` |
| `@base-ui/react/*` | RN primitive + `accessibilityRole`/`accessibilityState` |

Landed so far: `button`, `text`, `input`. The rest of the coverage set and the
translation table live in [`rn-rewrite-plan.md`](../rn-rewrite-plan.md) §9.1.
