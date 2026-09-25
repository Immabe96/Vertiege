import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { Text, View, type TextProps, type ViewProps } from 'react-native';

import { cn } from '@/lib/cn';

/**
 * Ported from https://www.neobrutalism.dev/docs/empty
 *
 * `text-balance`, `md:`, and the `[&>a]` hooks do not translate to RN —
 * links are rendered as `Text link` children instead.
 */
type EmptyProps = ViewProps & { className?: string; children?: React.ReactNode };

function Empty({ className, ...props }: EmptyProps) {
  return (
    <View
      className={cn(
        'w-full flex-1 flex-col items-center justify-center gap-4 self-stretch rounded-base border-2 border-dashed border-border bg-background p-6',
        className
      )}
      {...props}
    />
  );
}

function EmptyHeader({ className, ...props }: EmptyProps) {
  return (
    <View className={cn('w-full max-w-sm flex-col items-center gap-2', className)} {...props} />
  );
}

const emptyMediaVariants = cva('mb-2 items-center justify-center', {
  variants: {
    variant: {
      default: 'bg-transparent',
      icon: 'size-10 items-center justify-center rounded-base border-2 border-border bg-secondary-background',
    },
  },
  defaultVariants: { variant: 'default' },
});

function EmptyMedia({
  className,
  variant = 'default',
  ...props
}: ViewProps & VariantProps<typeof emptyMediaVariants> & { className?: string }) {
  return <View className={cn(emptyMediaVariants({ variant }), className)} {...props} />;
}

function EmptyTitle({ className, ...props }: TextProps & { className?: string }) {
  return (
    <Text
      accessibilityRole="header"
      className={cn('font-heading text-sm tracking-tight text-foreground', className)}
      {...props}
    />
  );
}

function EmptyDescription({ className, ...props }: TextProps & { className?: string }) {
  return <Text className={cn('font-base text-sm text-foreground', className)} {...props} />;
}

function EmptyContent({ className, ...props }: EmptyProps) {
  return (
    <View className={cn('w-full max-w-sm flex-col items-center gap-2.5', className)} {...props} />
  );
}

export { Empty, EmptyHeader, EmptyTitle, EmptyDescription, EmptyContent, EmptyMedia };
