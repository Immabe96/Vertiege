import * as React from 'react';
import type { ViewProps } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';

import { cn } from '@/lib/cn';

/** Ported from https://www.neobrutalism.dev/docs/skeleton (`animate-pulse`). */
type SkeletonProps = ViewProps & {
  className?: string;
  /** Wires up a11y — skeletons are decorative, so they are hidden from AT. */
  accessible?: boolean;
};

function Skeleton({ className, accessible = false, ...props }: SkeletonProps) {
  const reduceMotion = useReducedMotion();
  const opacity = useSharedValue(1);

  React.useEffect(() => {
    if (reduceMotion) {
      opacity.value = 1;
      return;
    }
    opacity.value = withRepeat(
      withTiming(0.5, { duration: 600, easing: Easing.inOut(Easing.quad) }),
      -1,
      true
    );
  }, [opacity, reduceMotion]);

  const animatedStyle = useAnimatedStyle(() => ({ opacity: opacity.value }));

  return (
    <Animated.View
      accessible={accessible}
      importantForAccessibility={accessible ? 'auto' : 'no-hide-descendants'}
      className={cn('rounded-base border-2 border-border bg-secondary-background', className)}
      style={animatedStyle}
      {...props}
    />
  );
}

export { Skeleton };
export type { SkeletonProps };
