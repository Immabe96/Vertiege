import * as React from 'react';
import { Pressable, View, type PressableProps } from 'react-native';
import { Check, Minus } from 'lucide-react-native';

import { cn } from '@/lib/cn';
import { HEX } from '@/lib/theme/tokens';

/**
 * Ported from https://www.neobrutalism.dev/docs/checkbox
 *
 * `data-checked:` / `data-indeterminate:` → explicit props on our API.
 * `outline-2 outline-border` → `border-2 border-border` (RN has no outline).
 * The 16px box sits inside a 44px touch target — `p-[14px] -m-[14px]` grows
 * the target without changing the layout footprint (§7.4).
 */
type CheckboxProps = Omit<PressableProps, 'onPress' | 'children'> & {
  className?: string;
  checked?: boolean;
  indeterminate?: boolean;
  disabled?: boolean;
  onCheckedChange?: (checked: boolean) => void;
};

function Checkbox({
  className,
  checked = false,
  indeterminate = false,
  disabled = false,
  onCheckedChange,
  ...props
}: CheckboxProps) {
  const selected = checked || indeterminate;

  return (
    <Pressable
      accessibilityRole="checkbox"
      accessibilityState={{ checked: indeterminate ? 'mixed' : checked, disabled }}
      disabled={disabled}
      hitSlop={8}
      onPress={() => onCheckedChange?.(!checked)}
      className={cn(
        '-m-[14px] items-center justify-center p-[14px]',
        disabled && 'opacity-50',
        className
      )}
      {...props}>
      <View
        className={cn(
          'size-4 items-center justify-center rounded-base border-2 border-border',
          selected ? 'bg-main' : 'bg-secondary-background'
        )}>
        {indeterminate ? (
          <Minus size={14} strokeWidth={3} color={HEX['main-foreground']} />
        ) : checked ? (
          <Check size={14} strokeWidth={3} color={HEX['main-foreground']} />
        ) : null}
      </View>
    </Pressable>
  );
}

export { Checkbox };
export type { CheckboxProps };
