import * as React from 'react';
import { Pressable, ScrollView, View, type ViewProps } from 'react-native';
import { Check, ChevronDown } from 'lucide-react-native';

import { Text } from '@/components/ui/text';
import { Sheet, SheetContent } from '@/components/ui/sheet';
import { cn } from '@/lib/cn';
import { HEX } from '@/lib/theme/tokens';

/**
 * RN adaptation of https://www.neobrutalism.dev/docs/select
 *
 * There is no `<select>` on touch, and the upstream port is a Base UI listbox
 * with hover/keyboard plumbing that does not translate (rn-rewrite-plan.md
 * §9.1). The trigger keeps the input chrome (`border-2`, `rounded-base`,
 * focus → 3px) and the options open in a bottom sheet — the same shape
 * Flutter's world-switcher sheet already uses.
 */
type SelectOption = { label: string; value: string; disabled?: boolean };

type SelectProps = ViewProps & {
  className?: string;
  value?: string;
  options: SelectOption[];
  placeholder?: string;
  disabled?: boolean;
  invalid?: boolean;
  onValueChange?: (value: string) => void;
  accessibilityLabel?: string;
};

function Select({
  className,
  value,
  options,
  placeholder = 'Select…',
  disabled = false,
  invalid = false,
  onValueChange,
  accessibilityLabel,
  ...props
}: SelectProps) {
  const [open, setOpen] = React.useState(false);
  const selected = options.find((option) => option.value === value);
  const [focused, setFocused] = React.useState(false);

  return (
    <View {...props}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={accessibilityLabel ?? selected?.label ?? placeholder}
        accessibilityState={{ disabled, expanded: open }}
        disabled={disabled}
        onPress={() => setOpen(true)}
        onPressIn={() => setFocused(true)}
        onPressOut={() => setFocused(false)}
        className={cn(
          'h-10 w-full flex-row items-center justify-between gap-2 rounded-base border-2 border-border bg-secondary-background px-3 py-2',
          focused && 'border-[3px] border-ring',
          invalid && 'border-danger',
          disabled && 'opacity-50',
          className
        )}>
        <Text
          variant="small"
          numberOfLines={1}
          className={cn('flex-1 font-base', !selected && 'text-foreground/50')}>
          {selected?.label ?? placeholder}
        </Text>
        <ChevronDown size={16} strokeWidth={2.5} color={HEX.foreground} />
      </Pressable>

      <Sheet open={open} onOpenChange={setOpen} side="bottom" showCloseButton>
        <SheetContent>
          <ScrollView className="max-h-[60%]" keyboardShouldPersistTaps="handled">
            {options.map((option) => {
              const active = option.value === value;
              return (
                <Pressable
                  key={option.value}
                  disabled={option.disabled}
                  accessibilityRole="menuitem"
                  accessibilityState={{ disabled: option.disabled ?? false, selected: active }}
                  onPress={() => {
                    onValueChange?.(option.value);
                    setOpen(false);
                  }}
                  className={cn(
                    'min-h-11 flex-row items-center justify-between gap-2 rounded-base border-2 border-transparent px-3 py-2',
                    active && 'border-border bg-main',
                    option.disabled && 'opacity-50'
                  )}>
                  <Text variant="small" className="flex-1 font-base">
                    {option.label}
                  </Text>
                  {active ? <Check size={16} strokeWidth={3} color={HEX.foreground} /> : null}
                </Pressable>
              );
            })}
          </ScrollView>
        </SheetContent>
      </Sheet>
    </View>
  );
}

export { Select };
export type { SelectProps, SelectOption };
