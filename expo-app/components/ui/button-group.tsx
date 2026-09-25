import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { View, type ViewProps } from 'react-native';

import { Text } from '@/components/ui/text';
import { cn } from '@/lib/cn';

/**
 * Ported from https://www.neobrutalism.dev/docs/button-group
 *
 * Web relies on descendant selectors (`[&>[data-slot]~[data-slot]]:rounded-l-none`,
 * `*:shadow-none!`). RN has none, so the group flattens each child instead:
 * drop the shadow and radius, then overlap the borders by `-2px` (the border
 * width) so neighbouring edges read as one rule.
 *
 * Children must accept a `className` prop — our `Button` does.
 */
const buttonGroupVariants = cva('w-fit rounded-base', {
  variants: {
    orientation: {
      horizontal: 'flex-row items-stretch',
      vertical: 'flex-col items-stretch',
    },
  },
  defaultVariants: { orientation: 'horizontal' },
});

type ButtonGroupProps = ViewProps & {
  className?: string;
  children?: React.ReactNode;
} & VariantProps<typeof buttonGroupVariants>;

function ButtonGroup({
  className,
  orientation = 'horizontal',
  children,
  ...props
}: ButtonGroupProps) {
  const items = React.Children.toArray(children);
  const lastIndex = items.length - 1;

  const flattened = items.map((child, index) => {
    if (!React.isValidElement(child)) return child;

    const edge =
      orientation === 'horizontal'
        ? cn(index === 0 && 'rounded-l-base', index === lastIndex && 'rounded-r-base')
        : cn(index === 0 && 'rounded-t-base', index === lastIndex && 'rounded-b-base');

    const overlap = index === 0 ? undefined : orientation === 'horizontal' ? '-ml-0.5' : '-mt-0.5';

    const childClassName = (child.props as { className?: string }).className;
    return React.cloneElement(child as React.ReactElement<{ className?: string }>, {
      className: cn('shadow-none rounded-none', overlap, edge, childClassName),
    });
  });

  return (
    <View className={cn(buttonGroupVariants({ orientation }), className)} {...props}>
      {flattened}
    </View>
  );
}

function ButtonGroupText({ className, children, ...props }: ViewProps & { className?: string }) {
  return (
    <View
      className={cn(
        'flex-row items-center gap-2 rounded-base border-2 border-border bg-secondary-background px-2.5',
        className
      )}
      {...props}>
      <Text variant="small" className="font-heading">
        {children}
      </Text>
    </View>
  );
}

function ButtonGroupSeparator({
  className,
  orientation = 'vertical',
  ...props
}: ViewProps & { className?: string; orientation?: 'horizontal' | 'vertical' }) {
  return (
    <View
      accessibilityRole="none"
      className={cn(
        'bg-border',
        orientation === 'horizontal' ? 'h-[2px] w-full' : 'h-full w-[2px] self-stretch',
        className
      )}
      {...props}
    />
  );
}

export { ButtonGroup, ButtonGroupText, ButtonGroupSeparator, buttonGroupVariants };
