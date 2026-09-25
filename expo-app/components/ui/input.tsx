import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { TextInput, type TextInputProps } from 'react-native';

import { cn } from '@/lib/cn';
import { HEX, hexToRgba } from '@/lib/theme/tokens';

/**
 * Ported from https://www.neobrutalism.dev/docs/input
 *
 * Web → RN translation (rn-rewrite-plan.md §9.1):
 *   focus-visible:ring-2 ring-offset-2  →  borderWidth 2 → 3 (RN has no ring)
 *   placeholder:text-foreground/50      →  placeholderTextColor at 0.5 alpha
 *   selection:bg-main                  →  selectionColor
 *   disabled:opacity-50                →  same
 */
const inputVariants = cva(
  'rounded-base border-2 border-border bg-secondary-background px-3 py-2 text-base font-base text-foreground',
  {
    variants: {
      tone: {
        default: '',
        muted: 'bg-muted',
      },
    },
    defaultVariants: { tone: 'default' },
  }
);

type InputProps = TextInputProps & VariantProps<typeof inputVariants> & { className?: string };

function Input({ className, tone, editable = true, onFocus, onBlur, ...props }: InputProps) {
  const [focused, setFocused] = React.useState(false);

  return (
    <TextInput
      editable={editable}
      onFocus={(event) => {
        setFocused(true);
        onFocus?.(event);
      }}
      onBlur={(event) => {
        setFocused(false);
        onBlur?.(event);
      }}
      placeholderTextColor={hexToRgba(HEX.foreground, 0.5)}
      selectionColor={HEX.main}
      className={cn(
        inputVariants({ tone }),
        focused && 'border-[3px] border-ring',
        !editable && 'opacity-50',
        className
      )}
      {...props}
    />
  );
}

export { Input, inputVariants };
export type { InputProps };
