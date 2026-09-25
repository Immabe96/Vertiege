import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { View } from 'react-native';

import { Text } from '@/components/ui/text';
import { cn } from '@/lib/cn';

/**
 * Ported from https://www.neobrutalism.dev/docs/badge
 *
 * `w-fit whitespace-nowrap` → the label is a one-line `Text`.
 * `variant` is extended past upstream's `default | neutral` with the
 * Vertiege accents/status fills (rn-rewrite-plan.md §9.2 feedback row);
 * fills carry their own AA foregrounds from `lib/theme/tokens.ts`.
 */
const badgeVariants = cva(
  'flex-row items-center justify-center self-start rounded-base border-2 border-border px-2.5 py-0.5 gap-1',
  {
    variants: {
      variant: {
        default: 'bg-background',
        neutral: 'bg-secondary-background',
        main: 'bg-main',
        secondary: 'bg-secondary',
        success: 'bg-success',
        warning: 'bg-warning',
        danger: 'bg-danger',
      },
      size: {
        sm: 'px-2 py-0.5',
        default: 'px-2.5 py-0.5',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
);

type BadgeVariant = NonNullable<VariantProps<typeof badgeVariants>['variant']>;

/** Text colour for each fill — white only on violet/red (contrast-tested). */
const BADGE_LABEL: Record<BadgeVariant, string> = {
  default: 'text-foreground',
  neutral: 'text-foreground',
  main: 'text-main-foreground',
  secondary: 'text-secondary-foreground',
  success: 'text-success-foreground',
  warning: 'text-warning-foreground',
  danger: 'text-danger-foreground',
};

type BadgeProps = VariantProps<typeof badgeVariants> & {
  className?: string;
  children?: React.ReactNode;
  /** Number of lines kept before truncation (upstream `whitespace-nowrap`). */
  numberOfLines?: number;
};

function Badge({ className, variant = 'default', size, numberOfLines = 1, children }: BadgeProps) {
  return (
    <View className={cn(badgeVariants({ variant, size }), className)}>
      <Text
        numberOfLines={numberOfLines}
        className={cn('font-base text-xs', BADGE_LABEL[variant ?? 'default'])}>
        {children}
      </Text>
    </View>
  );
}

export { Badge, badgeVariants };
export type { BadgeProps };
