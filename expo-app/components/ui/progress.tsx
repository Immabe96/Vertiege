import * as React from 'react';
import { View, type ViewProps } from 'react-native';

import { Text } from '@/components/ui/text';
import { cn } from '@/lib/cn';

/**
 * Ported from https://www.neobrutalism.dev/docs/progress
 *
 * `transition-all` on the indicator is dropped: `width` already animates with
 * the re-render, and RN has no CSS transition to inherit.
 */
type ProgressProps = ViewProps & {
  className?: string;
  /** 0 → `max` (default 100). Clamped. */
  value?: number;
  max?: number;
  children?: React.ReactNode;
  /** Renders the `ProgressLabel` slot text. */
  label?: string;
  /** Renders the `ProgressValue` slot text (e.g. `4/10`). */
  valueText?: string;
};

function Progress({
  className,
  value = 0,
  max = 100,
  label,
  valueText,
  children,
  ...props
}: ProgressProps) {
  const percent = max > 0 ? Math.min(100, Math.max(0, (value / max) * 100)) : 0;

  return (
    <View className={cn('w-full flex-col gap-2', className)} {...props}>
      {label || valueText ? (
        <View className="flex-row items-center gap-2">
          {label ? (
            <Text variant="small" className="font-heading">
              {label}
            </Text>
          ) : null}
          {valueText ? (
            <Text variant="small" className="ml-auto tabular-nums">
              {valueText}
            </Text>
          ) : null}
        </View>
      ) : null}
      {children}
      <ProgressTrack>
        <ProgressIndicator percent={percent} />
      </ProgressTrack>
    </View>
  );
}

function ProgressTrack({ className, ...props }: ViewProps & { className?: string }) {
  return (
    <View
      accessible
      accessibilityRole="progressbar"
      className={cn(
        'h-4 w-full overflow-hidden rounded-base border-2 border-border bg-secondary-background',
        className
      )}
      {...props}
    />
  );
}

function ProgressIndicator({
  className,
  percent = 0,
  ...props
}: ViewProps & { className?: string; percent?: number }) {
  return (
    <View
      className={cn('h-full border-r-2 border-border bg-main', className)}
      style={{ width: `${percent}%` }}
      {...props}
    />
  );
}

export { Progress, ProgressTrack, ProgressIndicator };
export type { ProgressProps };
