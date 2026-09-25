import * as React from 'react';
import {
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  View,
  type TextProps,
  type ViewProps,
} from 'react-native';
import { X } from 'lucide-react-native';
import Animated, {
  FadeIn,
  FadeOut,
  useReducedMotion,
  ZoomIn,
  ZoomOut,
} from 'react-native-reanimated';

import { Text } from '@/components/ui/text';
import { cn } from '@/lib/cn';
import { MOTION } from '@/lib/theme/tokens';

/**
 * Ported from https://www.neobrutalism.dev/docs/dialog
 *
 * Web → RN translation (rn-rewrite-plan.md §9.1 / §9.4):
 *   `DialogPortal`         → RN `Modal` (transparent, fade)
 *   `bg-overlay` backdrop  → `bg-overlay/80` scrim, tap to dismiss
 *   centred + `-translate` → flex centring (RN has no percentage translates)
 *   `animate-in` 200ms     → Reanimated `ZoomIn`/`FadeIn` at MOTION.enter (150ms)
 *   focus trap / ring      → `accessibilityViewIsModal` + modal semantics
 */
type OverlayContextValue = { close: () => void };

const OverlayContext = React.createContext<OverlayContextValue>({ close: () => {} });

type DialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Tap the scrim to dismiss (default true). */
  dismissOnScrimPress?: boolean;
  /** Show the × in the panel's top-right corner (default true). */
  showCloseButton?: boolean;
  children?: React.ReactNode;
};

function Dialog({
  open,
  onOpenChange,
  dismissOnScrimPress = true,
  showCloseButton = true,
  children,
}: DialogProps) {
  const reduceMotion = useReducedMotion();
  const close = React.useCallback(() => onOpenChange(false), [onOpenChange]);
  const ctx = React.useMemo(() => ({ close }), [close]);

  return (
    <Modal
      visible={open}
      transparent
      animationType="none"
      statusBarTranslucent
      onRequestClose={close}
      accessibilityViewIsModal>
      <Animated.View
        entering={reduceMotion ? FadeIn.duration(0) : FadeIn.duration(MOTION.enter)}
        exiting={reduceMotion ? FadeOut.duration(0) : FadeOut.duration(MOTION.enter)}
        className="flex-1 items-center justify-center px-4">
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={dismissOnScrimPress ? 'Close dialog' : undefined}
          onPress={dismissOnScrimPress ? close : undefined}
          disabled={!dismissOnScrimPress}
          className="absolute inset-0 bg-overlay/80"
        />
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          className="w-full">
          <Animated.View
            accessible
            accessibilityViewIsModal
            entering={reduceMotion ? undefined : ZoomIn.duration(MOTION.enter)}
            exiting={reduceMotion ? undefined : ZoomOut.duration(MOTION.enter)}
            className="w-full max-w-[512px] rounded-base border-2 border-border bg-background shadow-shadow">
            <OverlayContext.Provider value={ctx}>
              {showCloseButton ? <DialogClose /> : null}
              {children}
            </OverlayContext.Provider>
          </Animated.View>
        </KeyboardAvoidingView>
      </Animated.View>
    </Modal>
  );
}

function DialogClose({ className, ...props }: ViewProps & { className?: string }) {
  const { close } = React.useContext(OverlayContext);
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel="Close"
      onPress={close}
      hitSlop={8}
      className={cn(
        'absolute right-4 top-4 z-10 h-8 w-8 items-center justify-center rounded-base',
        className
      )}
      {...props}>
      <X size={16} strokeWidth={2.5} />
    </Pressable>
  );
}

/**
 * Upstream renders the × inside `DialogContent`; RN positions it against the
 * panel (the dialog's direct child) so it sits flush at `right-4 top-4`.
 * `showCloseButton` therefore lives on `Dialog`.
 */
function DialogContent({ className, children, ...props }: ViewProps & { className?: string }) {
  return (
    <View className={cn('gap-4 p-6', className)} {...props}>
      {children}
    </View>
  );
}

function DialogHeader({ className, ...props }: ViewProps & { className?: string }) {
  return <View className={cn('flex-col items-start gap-2', className)} {...props} />;
}

function DialogFooter({ className, ...props }: ViewProps & { className?: string }) {
  return <View className={cn('flex-row items-center justify-end gap-3', className)} {...props} />;
}

function DialogTitle({ className, ...props }: TextProps & { className?: string }) {
  return (
    <Text
      accessibilityRole="header"
      className={cn('font-heading text-lg leading-none tracking-tight', className)}
      {...props}
    />
  );
}

function DialogDescription({ className, ...props }: TextProps & { className?: string }) {
  return <Text className={cn('font-base text-sm text-foreground', className)} {...props} />;
}

export {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogFooter,
  DialogTitle,
  DialogDescription,
  DialogClose,
};
export type { DialogProps };
