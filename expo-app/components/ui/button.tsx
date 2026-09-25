import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { Pressable, type PressableProps } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';

import { Text, TextClassContext } from '@/components/ui/text';
import { cn } from '@/lib/cn';
import { HEX, MOTION, SHADOW, hexToRgba } from '@/lib/theme/tokens';

/**
 * Ported from https://www.neobrutalism.dev/docs/button
 *
 * Web → RN translation (rn-rewrite-plan.md §9.1):
 *   hover:translate-x-boxShadowX + hover:shadow-none  →  press state, 80ms
 *   focus-visible:ring-2 ring-offset-2                →  borderWidth 2 → 3
 *   transition-all                                    →  withTiming(80ms)
 *   disabled:opacity-50                               →  same
 *
 * The hard shadow is RN `boxShadow` (New Architecture; outset needs Android 9+).
 * No `elevation` fallback on purpose — a blurred Android elevation shadow would
 * break the neobrutalist read, so API 24–27 simply renders without the offset.
 */
const buttonVariants = cva(
  'flex-row items-center justify-center rounded-base border-2 border-border gap-2',
  {
    variants: {
      variant: {
        default: 'bg-main',
        noShadow: 'bg-main',
        neutral: 'bg-secondary-background',
        reverse: 'bg-main',
      },
      size: {
        default: 'h-10 px-4 py-2',
        xs: 'h-8 px-2.5 py-1.5 gap-1.5',
        sm: 'h-9 px-3 py-1.5',
        lg: 'h-11 px-8 py-2.5',
        icon: 'h-10 w-10',
        'icon-xs': 'h-8 w-8',
        'icon-sm': 'h-9 w-9',
        'icon-lg': 'h-11 w-11',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
);

const labelSizeVariants = cva('', {
  variants: {
    size: {
      default: 'text-sm',
      xs: 'text-xs',
      sm: 'text-sm',
      lg: 'text-sm',
      icon: '',
      'icon-xs': '',
      'icon-sm': '',
      'icon-lg': '',
    },
  },
  defaultVariants: { size: 'default' },
});

const LABEL_COLOR: Record<ButtonVariant, string> = {
  default: 'text-main-foreground',
  noShadow: 'text-main-foreground',
  neutral: 'text-foreground',
  reverse: 'text-main-foreground',
};

type ButtonVariantProps = VariantProps<typeof buttonVariants>;
type ButtonVariant = NonNullable<ButtonVariantProps['variant']>;

/** Variants that carry the hard shadow at rest (upstream `shadow-shadow`). */
const SHADOWED: ButtonVariant[] = ['default', 'neutral', 'reverse'];

type ButtonProps = PressableProps &
  Omit<ButtonVariantProps, 'variant'> & {
    variant?: ButtonVariant;
    className?: string;
  };

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

function Button({
  className,
  variant,
  size = 'default',
  disabled,
  children,
  ...props
}: ButtonProps) {
  const progress = useSharedValue(0);
  const activeVariant: ButtonVariant = variant ?? 'default';
  const reverse = activeVariant === 'reverse';
  const hasShadow = SHADOWED.includes(activeVariant);

  const animatedStyle = useAnimatedStyle(() => {
    'worklet';
    const p = progress.value;
    // default/neutral: rest → no offset, shadow on;  pressed → +4,+4, shadow off
    // reverse:         rest → -4,-4, shadow off;      pressed → no offset, shadow on
    const offset = reverse ? -SHADOW.x * (1 - p) : SHADOW.x * p;
    const alpha = hasShadow ? (reverse ? p : 1 - p) : 0;
    return {
      transform: [{ translateX: offset }, { translateY: offset }],
      boxShadow: `${SHADOW.x}px ${SHADOW.y}px ${SHADOW.blur}px ${SHADOW.spread}px ${hexToRgba(
        HEX.border,
        alpha
      )}`,
    };
  }, [hasShadow, reverse]);

  const labelClass = cn(labelSizeVariants({ size }), LABEL_COLOR[activeVariant]);

  return (
    <TextClassContext.Provider value={labelClass}>
      <AnimatedPressable
        accessibilityRole="button"
        accessibilityState={{ disabled: disabled ?? false }}
        disabled={disabled}
        onPressIn={() => {
          progress.value = withTiming(1, {
            duration: MOTION.press,
            easing: Easing.out(Easing.quad),
          });
        }}
        onPressOut={() => {
          progress.value = withTiming(0, {
            duration: MOTION.press,
            easing: Easing.out(Easing.quad),
          });
        }}
        className={cn(
          buttonVariants({ variant: activeVariant, size }),
          disabled && 'opacity-50',
          className
        )}
        style={animatedStyle}
        {...props}>
        {typeof children === 'string' || typeof children === 'number' ? (
          <Text>{children}</Text>
        ) : (
          children
        )}
      </AnimatedPressable>
    </TextClassContext.Provider>
  );
}

export { Button, buttonVariants, labelSizeVariants };
export type { ButtonProps };
