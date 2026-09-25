/**
 * Vertiege design tokens — Neobrutalism, `yellow` palette.
 *
 * SINGLE SOURCE OF TRUTH for every design literal in the app.
 * Upstream: https://neobrutalism.dev/r/styling/yellow.json (cssVars.light)
 *
 * `tailwind.tokens.json` is GENERATED from this file and is what
 * `tailwind.config.js` reads. Never edit the JSON by hand — run:
 *
 *     npm run tokens          # regenerate
 *     npm run tokens:check    # fail if the JSON is stale (wired into `npm run check`)
 */

/** Upstream palette id — the styling registry ships six. */
export const PALETTE = 'yellow' as const;

/**
 * Every colour literal in the app, as hex.
 * Key names are the upstream token names so class names line up with
 * neobrutalism.dev: `bg-background`, `text-main-foreground`, `border-border`…
 */
export const HEX = {
  /** App ground. Tinted pale yellow — deliberately NOT white. */
  background: '#FDF7C4',
  /** Cards, inputs, sheets — the surface that sits on the ground. */
  'secondary-background': '#FFFFFF',
  /** Hero cards, selected rows — one step up from `background`. (Vertiege addition) */
  'background-raised': '#FFF6D6',

  /** Ink. Body text and every border in the system. */
  foreground: '#000000',
  /** Text placed on a `main` fill. Never white — yellow can't carry it. */
  'main-foreground': '#000000',

  /** CTAs, active nav, progression. The one loud accent. */
  main: '#FACC00',

  /** Structural border colour. 2px, always this ink. */
  border: '#000000',
  /** Focus ring. */
  ring: '#000000',
  /** Scrim base — use at `OVERLAY_ALPHA`, i.e. `bg-overlay/80`. */
  overlay: '#000000',

  // ── Vertiege additions (not in the upstream registry) ───────────────
  /** Links, mentions, secondary actions. Continuity with shipped `#7C3AED`. */
  secondary: '#432DD7',
  'secondary-foreground': '#FFFFFF',
  /** Input tracks, disabled fills. */
  muted: '#F1F1F1',
  /** Secondary text. AA ≥ 4.5:1 on both `background` and `secondary-background`. */
  'muted-foreground': '#3F3F46',
  success: '#16A34A',
  'success-foreground': '#000000',
  warning: '#D97706',
  'warning-foreground': '#000000',
  danger: '#DC2626',
  'danger-foreground': '#FFFFFF',

  /**
   * Status **text** inks. The `-foreground` colours above are chosen for
   * contrast *on their own fill*; as text on the ground they only reach
   * ~3:1. These darker inks clear AA (≥ 4.5:1) on `background`,
   * `secondary-background` and `background-raised`.
   */
  'success-ink': '#0F7A38',
  'warning-ink': '#8A4B00',
  'danger-ink': '#B3261E',
} as const;

export type ColorName = keyof typeof HEX;

/** Scrim alpha for `--overlay`. Upstream: `rgb(0 0 0 / 0.8)`. */
export const OVERLAY_ALPHA = 0.8;

/** `rounded-base` — upstream `radius-base`. */
export const RADIUS = { base: 5 } as const;

/** `shadow-shadow` — upstream `4px 4px 0px 0px var(--border)`. Zero blur, always. */
export const SHADOW = { x: 4, y: 4, blur: 0, spread: 0 } as const;

/** Upstream `font-weight-base` / `font-weight-heading`. */
export const FONT_WEIGHT = { base: 500, heading: 700 } as const;

/**
 * Expo Google Fonts. Family names are weight-specific because that's how
 * `@expo-google-fonts/*` ships them — pick the family, not a weight class.
 */
export const FONT_FAMILY = {
  heading: ['SpaceGrotesk_700Bold'],
  headingSemibold: ['SpaceGrotesk_600SemiBold'],
  base: ['PlusJakartaSans_500Medium'],
  baseRegular: ['PlusJakartaSans_400Regular'],
  baseSemibold: ['PlusJakartaSans_600SemiBold'],
} as const;

/** Motion ceilings (ms). See docs/design.md § Motion. */
export const MOTION = { press: 80, enter: 150 } as const;

/** `#RRGGBB` → `"R G B"` (the `rgb(var(--x))` convention, kept for reference). */
export function toRgbTriplet(hex: string): string {
  const value = hex.replace('#', '');
  const full = value.length === 3 ? value.replace(/./g, (c) => c + c) : value;
  const int = Number.parseInt(full, 16);
  return `${(int >> 16) & 255} ${(int >> 8) & 255} ${int & 255}`;
}

/** `#RRGGBB` → `rgba(r, g, b, alpha)` — used for animated hard shadows. */
export function hexToRgba(hex: string, alpha: number): string {
  const [r, g, b] = toRgbTriplet(hex).split(' ');
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

/** Relative luminance per WCAG 2.1. */
export function relativeLuminance(hex: string): number {
  const value = hex.replace('#', '');
  const channels = [0, 2, 4].map((i) => Number.parseInt(value.slice(i, i + 2), 16) / 255);
  const linear = channels.map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  const [r, g, b] = linear;
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/** WCAG contrast ratio between two hex colours (1 → 21). */
export function contrastRatio(a: string, b: string): number {
  const [lighter, darker] = [relativeLuminance(a), relativeLuminance(b)].sort((x, y) => y - x);
  return (lighter + 0.05) / (darker + 0.05);
}
