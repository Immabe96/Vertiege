import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { Text as RNText, type TextProps as RNTextProps } from 'react-native';

import { cn } from '@/lib/cn';

/**
 * Type scale — four steps per docs/design.md (§7.3).
 * Family and weight are baked into the family name (see `FONT_FAMILY`
 * in `lib/theme/tokens.ts`), so there is no `font-bold` on purpose.
 */
const sizeVariants = cva('', {
  variants: {
    variant: {
      display: 'text-[34px] leading-[40px] font-heading',
      section: 'text-[28px] leading-[34px] font-heading',
      title: 'text-[20px] leading-[26px] font-heading',
      body: 'text-base leading-6',
      small: 'text-sm leading-5',
      caption: 'text-xs leading-4',
    },
  },
  defaultVariants: { variant: 'body' },
});

/**
 * Status colours are the darker `-ink` tokens — the raw `success`/`warning`/
 * `danger` fills only reach ~3:1 as text on our grounds (tokens.ts).
 */
const toneVariants = cva('', {
  variants: {
    tone: {
      default: '',
      muted: 'text-muted-foreground',
      secondary: 'text-secondary',
      success: 'text-success-ink',
      warning: 'text-warning-ink',
      danger: 'text-danger-ink',
      /** Text sitting on a `bg-main` fill. */
      onMain: 'text-main-foreground',
    },
  },
  defaultVariants: { tone: 'default' },
});

/**
 * Set by `Button` so a bare `<Text>` child inherits the control's label
 * colour and size without every call site repeating it. An explicit `tone`
 * or `className` on the child still wins.
 */
const TextClassContext = React.createContext<string | undefined>(undefined);

type TextProps = RNTextProps &
  VariantProps<typeof sizeVariants> &
  VariantProps<typeof toneVariants>;

function Text({ className, variant, tone, ...props }: TextProps) {
  const inherited = React.useContext(TextClassContext);
  return (
    <RNText
      className={cn(
        'font-base text-foreground',
        sizeVariants({ variant }),
        inherited,
        toneVariants({ tone }),
        className
      )}
      {...props}
    />
  );
}

export { Text, TextClassContext, sizeVariants, toneVariants };
export type { TextProps };
