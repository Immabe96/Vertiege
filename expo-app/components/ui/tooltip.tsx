import * as React from 'react';
import { Pressable, View, type ViewProps } from 'react-native';

import { Text } from '@/components/ui/text';
import { cn } from '@/lib/cn';

/**
 * Ported from https://www.neobrutalism.dev/docs/tooltip
 *
 * Web → RN translation (rn-rewrite-plan.md §9.1): hover does not exist on
 * touch, so the bubble opens on **long-press** (the RN convention) and closes
 * when the trigger is pressed again, after `duration`, or on unmount.
 * `TooltipProvider`/`TooltipTrigger`/`TooltipContent` are kept as thin
 * aliases so upstream-shaped call sites still read correctly; the bubble is
 * centred over the trigger and sits `top` only (a `Positioner` needs the
 * measurement pass that a hint bubble is not worth).
 */
type TooltipProps = {
  /** Bubble body. */
  content?: React.ReactNode;
  children?: React.ReactNode;
  /** Long-press delay in ms (default 350). */
  delay?: number;
  /** Auto-dismiss after ms (default 3000, `0` = until dismissed). */
  duration?: number;
  className?: string;
};

type TooltipContentProps = ViewProps & { className?: string; children?: React.ReactNode };

function Tooltip({ content, children, delay = 350, duration = 3000, className }: TooltipProps) {
  const [visible, setVisible] = React.useState(false);
  const [size, setSize] = React.useState({ width: 0, height: 0 });
  const timer = React.useRef<ReturnType<typeof setTimeout> | null>(null);

  const close = React.useCallback(() => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = null;
    setVisible(false);
  }, []);

  const open = React.useCallback(() => {
    setVisible(true);
    if (duration > 0) {
      if (timer.current) clearTimeout(timer.current);
      timer.current = setTimeout(close, duration);
    }
  }, [close, duration]);

  React.useEffect(
    () => () => {
      if (timer.current) clearTimeout(timer.current);
    },
    []
  );

  return (
    <View className={cn('relative', className)}>
      <Pressable
        delayLongPress={delay}
        onLongPress={open}
        onPressIn={() => {
          if (visible) close();
        }}
        onLayout={(e) => setSize(e.nativeEvent.layout)}
        accessibilityHint="Long press to show a hint">
        {children}
      </Pressable>

      {visible && content ? (
        <View
          pointerEvents="none"
          accessibilityLiveRegion="polite"
          className="absolute z-50"
          style={{ left: 0, right: 0, top: -(size.height + 8) }}>
          <View className="max-w-[240px] self-center rounded-base border-2 border-border bg-secondary-background px-3 py-1.5 shadow-shadow">
            <Text variant="caption">{content}</Text>
          </View>
        </View>
      ) : null}
    </View>
  );
}

/** Upstream's content slot — use `content` on `Tooltip` instead. */
function TooltipContent({ className, children, ...props }: TooltipContentProps) {
  return (
    <View
      className={cn(
        'rounded-base border-2 border-border bg-secondary-background px-3 py-1.5 shadow-shadow',
        className
      )}
      {...props}>
      {children}
    </View>
  );
}

/** No-op on RN — upstream needs it for delay, we take it as a `Tooltip` prop. */
function TooltipProvider({ children }: { children?: React.ReactNode }) {
  return <>{children}</>;
}

/** Alias for readability at call sites that mirror the upstream shape. */
function TooltipTrigger({ children, ...props }: ViewProps) {
  return <View {...props}>{children}</View>;
}

export { Tooltip, TooltipTrigger, TooltipContent, TooltipProvider };
