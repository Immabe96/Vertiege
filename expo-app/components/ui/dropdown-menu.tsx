import * as React from 'react';
import { Pressable, ScrollView, View, type ViewProps } from 'react-native';

import { Text } from '@/components/ui/text';
import { Sheet, SheetContent, SheetTitle } from '@/components/ui/sheet';
import { cn } from '@/lib/cn';

/**
 * RN adaptation of https://www.neobrutalism.dev/docs/dropdown-menu
 *
 * Web's popover menu hangs off a hover target; touch has none, and the plan
 * puts `context-menu`/`hover-card` out of scope (rn-rewrite-plan.md §9.1).
 * The item list is therefore rendered in the same bottom sheet the rest of the
 * app uses, with `accessibilityRole="menu"`/`"menuitem"` preserved so the
 * semantics match the upstream primitive.
 */
type DropdownMenuItem = {
  label: string;
  value: string;
  destructive?: boolean;
  disabled?: boolean;
  onPress: () => void;
};

type DropdownMenuProps = ViewProps & {
  className?: string;
  /** Element cloned with `onPress` — pass a `Button`. */
  trigger: React.ReactNode;
  items: DropdownMenuItem[];
  title?: string;
};

function DropdownMenu({ className, trigger, items, title, ...props }: DropdownMenuProps) {
  const [open, setOpen] = React.useState(false);

  const triggerElement = React.isValidElement<{ onPress?: () => void }>(trigger)
    ? React.cloneElement(trigger, { onPress: () => setOpen(true) })
    : trigger;

  return (
    <View className={cn('flex-row', className)} {...props}>
      {triggerElement}

      <Sheet open={open} onOpenChange={setOpen} side="bottom" showCloseButton>
        <SheetContent>
          <ScrollView className="max-h-[60%]" keyboardShouldPersistTaps="handled">
            <View accessible accessibilityRole="menu" className="gap-2">
              {title ? <SheetTitle>{title}</SheetTitle> : null}
              {items.map((item) => (
                <Pressable
                  key={item.value}
                  accessibilityRole="menuitem"
                  accessibilityState={{ disabled: item.disabled ?? false }}
                  disabled={item.disabled}
                  onPress={() => {
                    setOpen(false);
                    item.onPress();
                  }}
                  className={cn(
                    'min-h-11 flex-row items-center rounded-base border-2 border-border bg-secondary-background px-3 py-2',
                    item.destructive && 'bg-danger',
                    item.disabled && 'opacity-50'
                  )}>
                  <Text
                    variant="small"
                    className={cn(
                      'flex-1 font-base',
                      item.destructive ? 'text-danger-foreground' : 'text-foreground'
                    )}>
                    {item.label}
                  </Text>
                </Pressable>
              ))}
            </View>
          </ScrollView>
        </SheetContent>
      </Sheet>
    </View>
  );
}

export { DropdownMenu };
export type { DropdownMenuProps, DropdownMenuItem };
