import * as React from 'react';
import { View, type ViewProps } from 'react-native';

import { Text } from '@/components/ui/text';
import { cn } from '@/lib/cn';

/** `View` for composed children, `Text` for a plain string (RN has no bare text nodes). */
function MaybeText({
  className,
  children,
  ...props
}: React.ComponentProps<typeof Text> & { children?: React.ReactNode }) {
  if (typeof children === 'string' || typeof children === 'number') {
    return (
      <Text className={className} {...props}>
        {children}
      </Text>
    );
  }
  return (
    <View className={className} {...props}>
      {children}
    </View>
  );
}

/**
 * Ported from https://www.neobrutalism.dev/docs/card
 *
 * `gap/padding-(--card-spacing)` → `gap-6 py-6` (sm: `gap-4 py-4`).
 * Container-level `@container`/`grid` rules do not translate to RN — the
 * header/content split is done with plain flex columns.
 */
type CardProps = ViewProps & { className?: string; size?: 'default' | 'sm' };

function Card({ className, size = 'default', ...props }: CardProps) {
  return (
    <View
      className={cn(
        'flex-col items-stretch rounded-base border-2 border-border bg-background shadow-shadow',
        size === 'default' ? 'gap-6 py-6' : 'gap-4 py-4',
        className
      )}
      {...props}
    />
  );
}

type CardSectionProps = ViewProps & { className?: string };

function CardHeader({ className, ...props }: CardSectionProps) {
  return <View className={cn('flex-col items-start gap-1.5 px-6', className)} {...props} />;
}

function CardTitle({ className, ...props }: CardSectionProps) {
  return (
    <MaybeText
      accessibilityRole="header"
      className={cn('font-heading text-lg leading-none text-foreground', className)}
      {...props}
    />
  );
}

function CardDescription({ className, ...props }: CardSectionProps) {
  return <MaybeText className={cn('flex-col font-base text-sm', className)} {...props} />;
}

function CardAction({ className, ...props }: CardSectionProps) {
  return <View className={cn('self-start', className)} {...props} />;
}

function CardContent({ className, ...props }: CardSectionProps) {
  return <View className={cn('px-6', className)} {...props} />;
}

function CardFooter({ className, ...props }: CardSectionProps) {
  return <View className={cn('flex-row items-center gap-3 px-6', className)} {...props} />;
}

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent, CardAction };
export type { CardProps };
