import * as React from 'react';
import { View, type ViewProps } from 'react-native';

import { cn } from '@/lib/cn';

/**
 * Not an upstream neobrutalism component (`/docs/separator` is a 404) — the
 * rule is the same one Flutter's `VDivider` drew: a 2px black bar.
 */
type SeparatorProps = ViewProps & {
  className?: string;
  orientation?: 'horizontal' | 'vertical';
};

function Separator({ className, orientation = 'horizontal', ...props }: SeparatorProps) {
  return (
    <View
      accessibilityRole="none"
      className={cn(
        'bg-border',
        orientation === 'horizontal' ? 'h-[2px] w-full' : 'h-full w-[2px] self-stretch',
        className
      )}
      {...props}
    />
  );
}

export { Separator };
export type { SeparatorProps };
