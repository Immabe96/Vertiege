import * as React from 'react';
import { Pressable, View, type PressableProps } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';

import { cn } from '@/lib/cn';
import { MOTION } from '@/lib/theme/tokens';

/**
 * Ported from https://www.neobrutalism.dev/docs/switch
 *
 * `data-checked:` / `data-unchecked:` → `checked` prop.
 * Thumb travel is animated with the 80ms press easing (§7.5) instead of
 * `transition-transform`. The track sits in a 44px tall touch target.
 */
type SwitchProps = Omit<PressableProps, 'onPress' | 'children'> & {
  className?: string;
  checked?: boolean;
  disabled?: boolean;
  size?: 'default' | 'sm';
  onCheckedChange?: (checked: boolean) => void;
};

// RN sizes are border-box, so travel = inner track width − thumb width.
const TRACK_TRAVEL = { default: 28, sm: 20 } as const;

function Switch({
  className,
  checked = false,
  disabled = false,
  size = 'default',
  onCheckedChange,
  ...props
}: SwitchProps) {
  const reduceMotion = useReducedMotion();
  const progress = useSharedValue(checked ? 1 : 0);

  React.useEffect(() => {
    progress.value = withTiming(checked ? 1 : 0, {
      duration: reduceMotion ? 0 : MOTION.press,
      easing: Easing.out(Easing.quad),
    });
  }, [checked, progress, reduceMotion]);

  const thumbStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: progress.value * TRACK_TRAVEL[size] }],
  }));

  const trackWidth = size === 'default' ? 'w-12' : 'w-9';
  const trackHeight = size === 'default' ? 'h-6' : 'h-5';
  const thumbBox = size === 'default' ? 'h-4 w-4' : 'h-3 w-3';

  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityState={{ checked, disabled }}
      disabled={disabled}
      hitSlop={6}
      onPress={() => onCheckedChange?.(!checked)}
      className={cn('h-11 items-center justify-center', disabled && 'opacity-50', className)}
      {...props}>
      <View
        className={cn(
          'items-start justify-start rounded-full border-2 border-border bg-secondary-background',
          trackWidth,
          trackHeight
        )}>
        <Animated.View
          className={cn(
            'mt-0.5 rounded-full border-2 border-border bg-secondary-background',
            thumbBox
          )}
          style={thumbStyle}
        />
      </View>
    </Pressable>
  );
}

export { Switch };
export type { SwitchProps };
