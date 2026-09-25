import * as React from 'react';
import { Text, type TextProps } from 'react-native';

import { cn } from '@/lib/cn';

/** Ported from https://www.neobrutalism.dev/docs/label */
type LabelProps = TextProps & { className?: string; disabled?: boolean };

function Label({ className, disabled, ...props }: LabelProps) {
  return (
    <Text
      className={cn(
        'font-heading text-sm leading-none text-foreground',
        disabled && 'opacity-70',
        className
      )}
      {...props}
    />
  );
}

export { Label };
export type { LabelProps };
