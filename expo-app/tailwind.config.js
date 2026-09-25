const { hairlineWidth } = require('nativewind/theme');
const tokens = require('./tailwind.tokens.json');

/**
 * Neobrutalism tokens — GENERATED from `lib/theme/tokens.ts`.
 * Do not put colour literals in this file: edit the tokens and run `npm run tokens`.
 */

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,jsx,ts,tsx}',
    './components/**/*.{js,jsx,ts,tsx}',
    './lib/**/*.{js,jsx,ts,tsx}',
  ],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        background: tokens.colors.background,
        'background-raised': tokens.colors['background-raised'],
        'secondary-background': tokens.colors['secondary-background'],
        foreground: tokens.colors.foreground,
        border: tokens.colors.border,
        ring: tokens.colors.ring,
        overlay: tokens.colors.overlay,
        main: {
          DEFAULT: tokens.colors.main,
          foreground: tokens.colors['main-foreground'],
        },
        secondary: {
          DEFAULT: tokens.colors.secondary,
          foreground: tokens.colors['secondary-foreground'],
        },
        muted: {
          DEFAULT: tokens.colors.muted,
          foreground: tokens.colors['muted-foreground'],
        },
        success: {
          DEFAULT: tokens.colors.success,
          foreground: tokens.colors['success-foreground'],
        },
        warning: {
          DEFAULT: tokens.colors.warning,
          foreground: tokens.colors['warning-foreground'],
        },
        danger: {
          DEFAULT: tokens.colors.danger,
          foreground: tokens.colors['danger-foreground'],
        },
        // Status *text* inks — AA on all three grounds (see tokens.ts).
        'success-ink': tokens.colors['success-ink'],
        'warning-ink': tokens.colors['warning-ink'],
        'danger-ink': tokens.colors['danger-ink'],
      },
      borderRadius: {
        base: `${tokens.radius.base}px`,
      },
      boxShadow: {
        shadow: `${tokens.shadow.x}px ${tokens.shadow.y}px ${tokens.shadow.blur}px ${tokens.shadow.spread}px ${tokens.colors.border}`,
        none: '0px 0px 0px 0px transparent',
      },
      fontFamily: {
        sans: tokens.fontFamily.base,
        heading: tokens.fontFamily.heading,
        'heading-semibold': tokens.fontFamily.headingSemibold,
        base: tokens.fontFamily.base,
        'base-regular': tokens.fontFamily.baseRegular,
        'base-semibold': tokens.fontFamily.baseSemibold,
      },
      fontWeight: {
        base: String(tokens.fontWeight.base),
        heading: String(tokens.fontWeight.heading),
      },
      borderWidth: {
        hairline: hairlineWidth(),
      },
    },
  },
  plugins: [],
};
