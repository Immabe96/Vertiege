import * as React from 'react';
import { TextInput, type TextInputProps } from 'react-native';

import { inputVariants } from '@/components/ui/input';
import { cn } from '@/lib/cn';
import { HEX, hexToRgba } from '@/lib/theme/tokens';

/**
 * Ported from https://www.neobrutalism.dev/docs/textarea
 *
 * `min-h-[80px]` → `minHeight: 80`; `aria-invalid` → the `invalid` prop
 * (RN has no `aria-invalid` on inputs).
 */
type TextareaProps = TextInputProps & {
  className?: string;
  invalid?: boolean;
};

function Textarea({
  className,
  invalid,
  editable = true,
  onFocus,
  onBlur,
  ...props
}: TextareaProps) {
  const [focused, setFocused] = React.useState(false);

  return (
    <TextInput
      multiline
      editable={editable}
      textAlignVertical="top"
      onFocus={(event) => {
        setFocused(true);
        onFocus?.(event);
      }}
      onBlur={(event) => {
        setFocused(false);
        onBlur?.(event);
      }}
      placeholderTextColor={hexToRgba(HEX.foreground, 0.5)}
      selectionColor={HEX.main}
      className={cn(
        inputVariants({}),
        'min-h-[80px] py-2',
        focused && 'border-[3px] border-ring',
        invalid && 'border-danger',
        !editable && 'opacity-50',
        className
      )}
      {...props}
    />
  );
}

export { Textarea };
export type { TextareaProps };
