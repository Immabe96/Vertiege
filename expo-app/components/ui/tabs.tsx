import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { Pressable, View, type ViewProps } from 'react-native';

import { Text, TextClassContext } from '@/components/ui/text';
import { cn } from '@/lib/cn';

/**
 * Ported from https://www.neobrutalism.dev/docs/tabs
 *
 * `data-active:` → the `active` prop fed from context. The `line` variant's
 * `after:` pseudo-element indicator becomes an absolutely-positioned View
 * inside the trigger.
 */
type TabsContextValue = {
  value: string;
  select: (value: string) => void;
};

const TabsContext = React.createContext<TabsContextValue | null>(null);
const TabsListContext = React.createContext<'default' | 'line'>('default');

function useTabs() {
  const ctx = React.useContext(TabsContext);
  if (!ctx) throw new Error('Tabs components must be rendered inside <Tabs>');
  return ctx;
}

type TabsProps = ViewProps & {
  className?: string;
  /** Controlled value. Omit for uncontrolled. */
  value?: string;
  defaultValue?: string;
  onValueChange?: (value: string) => void;
  children?: React.ReactNode;
};

function Tabs({
  className,
  value: controlledValue,
  defaultValue = '',
  onValueChange,
  children,
  ...props
}: TabsProps) {
  const [uncontrolled, setUncontrolled] = React.useState(defaultValue);
  const value = controlledValue ?? uncontrolled;

  const select = React.useCallback(
    (next: string) => {
      if (controlledValue === undefined) setUncontrolled(next);
      onValueChange?.(next);
    },
    [controlledValue, onValueChange]
  );

  const ctx = React.useMemo(() => ({ value, select }), [value, select]);

  return (
    <TabsContext.Provider value={ctx}>
      <View className={cn('w-full', className)} {...props}>
        {children}
      </View>
    </TabsContext.Provider>
  );
}

const tabsListVariants = cva('flex-row items-center justify-center', {
  variants: {
    variant: {
      default: 'h-12 rounded-base border-2 border-border bg-background p-1 gap-1',
      line: 'gap-1 border-b-2 border-border bg-transparent',
    },
  },
  defaultVariants: { variant: 'default' },
});

function TabsList({
  className,
  variant,
  ...props
}: ViewProps & VariantProps<typeof tabsListVariants> & { className?: string }) {
  const activeVariant = variant ?? 'default';
  return (
    <TabsListContext.Provider value={activeVariant}>
      <View className={cn(tabsListVariants({ variant: activeVariant }), className)} {...props} />
    </TabsListContext.Provider>
  );
}

type TabsTriggerProps = ViewProps & {
  className?: string;
  value: string;
  disabled?: boolean;
  children?: React.ReactNode;
};

function TabsTrigger({ className, value, disabled, children, ...props }: TabsTriggerProps) {
  const ctx = useTabs();
  const listVariant = React.useContext(TabsListContext);
  const active = ctx.value === value;
  const line = listVariant === 'line';

  const labelClass = cn(
    'font-heading text-sm',
    active ? (line ? 'text-foreground' : 'text-main-foreground') : 'text-foreground'
  );

  return (
    <Pressable
      accessibilityRole="tab"
      accessibilityState={{ selected: active, disabled: disabled ?? false }}
      disabled={disabled}
      onPress={() => ctx.select(value)}
      className={cn(
        'relative flex-1 flex-row items-center justify-center gap-1.5 rounded-base border-2 px-2 py-1',
        active
          ? line
            ? 'border-transparent bg-transparent'
            : 'border-border bg-main'
          : 'border-transparent bg-transparent',
        disabled && 'opacity-50',
        className
      )}
      {...props}>
      <TextClassContext.Provider value={labelClass}>
        {typeof children === 'string' || typeof children === 'number' ? (
          <Text>{children}</Text>
        ) : (
          children
        )}
      </TextClassContext.Provider>
      {active && line ? (
        <View pointerEvents="none" className="absolute -bottom-0.5 left-0 right-0 h-1 bg-main" />
      ) : null}
    </Pressable>
  );
}

type TabsContentProps = ViewProps & {
  className?: string;
  value: string;
  children?: React.ReactNode;
};

function TabsContent({ className, value, children, ...props }: TabsContentProps) {
  const ctx = useTabs();
  if (ctx.value !== value) return null;
  return (
    <View accessible className={cn('mt-2', className)} {...props}>
      {children}
    </View>
  );
}

export { Tabs, TabsList, TabsTrigger, TabsContent, tabsListVariants };
