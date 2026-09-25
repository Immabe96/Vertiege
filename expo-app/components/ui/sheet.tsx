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
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  FadeIn,
  FadeOut,
  SlideInDown,
  SlideInLeft,
  SlideInRight,
  SlideInUp,
  runOnJS,
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';

import { Text } from '@/components/ui/text';
import { cn } from '@/lib/cn';
import { MOTION } from '@/lib/theme/tokens';

/**
 * Ported from https://www.neobrutalism.dev/docs/sheet
 *
 * Web → RN translation (rn-rewrite-plan.md §9.1 / §9.4):
 *   `SheetPortal`        → RN `Modal` (transparent, fade scrim)
 *   side slide-in/out    → Reanimated `SlideIn*` at MOTION.enter (150ms)
 *   (no drag in web)     → `Gesture.Pan` on the panel: follows the finger,
 *                           dismisses past 25% of its height or on a fast flick
 *   `bg-overlay` scrim   → `bg-overlay/80`, tap to dismiss
 */
type SheetSide = 'top' | 'bottom' | 'left' | 'right';

type SheetProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  side?: SheetSide;
  dismissOnScrimPress?: boolean;
  showCloseButton?: boolean;
  /** Drag-to-dismiss (vertical sides only, default true). */
  draggable?: boolean;
  children?: React.ReactNode;
};

const PANEL_POSITION: Record<SheetSide, object> = {
  top: { top: 0, left: 0, right: 0 },
  bottom: { bottom: 0, left: 0, right: 0 },
  left: { top: 0, bottom: 0, left: 0 },
  right: { top: 0, bottom: 0, right: 0 },
};

const PANEL_CLASS: Record<SheetSide, string> = {
  top: 'w-full border-b-2 max-h-[85%]',
  bottom: 'w-full border-t-2 max-h-[85%]',
  left: 'h-full w-3/4 max-w-[320px] border-r-2',
  right: 'h-full w-3/4 max-w-[320px] border-l-2',
};

const DRAG_DISTANCE: Record<SheetSide, string> = {
  top: 'y',
  bottom: 'y',
  left: 'x',
  right: 'x',
};

/**
 * `drag.value = …` inside a hook callback is rejected by
 * `react-hooks/immutability`, so the write happens at module scope where the
 * shared value is just a parameter. Reanimated's own docs use the inline form.
 */
function writeDrag(drag: SharedValue<number>, value: number) {
  drag.value = value;
}

/** Motion that pulls the panel away from the edge it is docked to. */
function dragAwayFromEdge(side: SheetSide, raw: number): number {
  return side === 'bottom' || side === 'right' ? Math.max(0, raw) : Math.min(0, raw);
}

type SheetContextValue = { close: () => void };

const SheetContext = React.createContext<SheetContextValue>({ close: () => {} });

function Sheet({
  open,
  onOpenChange,
  side = 'bottom',
  dismissOnScrimPress = true,
  showCloseButton = true,
  draggable = true,
  children,
}: SheetProps) {
  const reduceMotion = useReducedMotion();
  const close = React.useCallback(() => onOpenChange(false), [onOpenChange]);
  const ctx = React.useMemo(() => ({ close }), [close]);

  const drag = useSharedValue(0);
  const [height, setHeight] = React.useState(0);

  const vertical = DRAG_DISTANCE[side] === 'y';

  const dismiss = React.useCallback(() => onOpenChange(false), [onOpenChange]);

  const onDragEnd = React.useCallback(
    (distance: number, velocity: number) => {
      const threshold = height > 0 ? height * 0.25 : 120;
      if (distance > threshold || velocity > 800) {
        dismiss();
      } else {
        writeDrag(drag, withTiming(0, { duration: MOTION.press }));
      }
    },
    [dismiss, drag, height]
  );

  // Built during render rather than memoised: putting `drag` inside a hook
  // callback trips react-hooks/immutability, and the gesture only changes
  // when the sheet opens or its side changes.
  const pan = !draggable
    ? null
    : Gesture.Pan()
        .enabled(open)
        .activeOffsetX([-12, 12])
        .activeOffsetY([-12, 12])
        .onUpdate((e) => {
          const raw = vertical ? e.translationY : e.translationX;
          // Only allow motion that pulls the panel away from its edge.
          writeDrag(drag, dragAwayFromEdge(side, raw));
        })
        .onEnd((e) => {
          const distance = vertical ? e.translationY : e.translationX;
          const velocity = vertical ? e.velocityY : e.velocityX;
          runOnJS(onDragEnd)(
            side === 'bottom' || side === 'right' ? distance : -distance,
            velocity
          );
        });

  const dragStyle = useAnimatedStyle(() => ({
    transform:
      DRAG_DISTANCE[side] === 'y' ? [{ translateY: drag.value }] : [{ translateX: drag.value }],
  }));

  const entering = reduceMotion
    ? FadeIn.duration(0)
    : side === 'bottom'
      ? SlideInDown.duration(MOTION.enter)
      : side === 'top'
        ? SlideInUp.duration(MOTION.enter)
        : side === 'left'
          ? SlideInLeft.duration(MOTION.enter)
          : SlideInRight.duration(MOTION.enter);

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
        className="flex-1">
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={dismissOnScrimPress ? 'Close sheet' : undefined}
          onPress={dismissOnScrimPress ? close : undefined}
          disabled={!dismissOnScrimPress}
          className="absolute inset-0 bg-overlay/80"
        />
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          pointerEvents="box-none"
          className="flex-1">
          <Animated.View
            accessible
            accessibilityViewIsModal
            entering={entering}
            onLayout={(e) => {
              if (side === 'bottom' || side === 'top') {
                setHeight(e.nativeEvent.layout.height);
              }
            }}
            style={PANEL_POSITION[side]}
            className={cn(
              'absolute gap-4 border-border bg-background shadow-shadow',
              PANEL_CLASS[side]
            )}>
            <Animated.View style={dragStyle} className="flex-1">
              {pan ? (
                <GestureDetector gesture={pan}>
                  <View className="flex-1">
                    <SheetContext.Provider value={ctx}>
                      <SheetHandle />
                      {showCloseButton ? <SheetClose /> : null}
                      {children}
                    </SheetContext.Provider>
                  </View>
                </GestureDetector>
              ) : (
                <SheetContext.Provider value={ctx}>
                  <SheetHandle />
                  {showCloseButton ? <SheetClose /> : null}
                  {children}
                </SheetContext.Provider>
              )}
            </Animated.View>
          </Animated.View>
        </KeyboardAvoidingView>
      </Animated.View>
    </Modal>
  );
}

/** The grab bar — doubles as the affordance for drag-to-dismiss. */
function SheetHandle() {
  return (
    <View
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      className="h-1 w-10 self-center rounded-full bg-border"
    />
  );
}

function SheetClose({ className, ...props }: ViewProps & { className?: string }) {
  const { close } = React.useContext(SheetContext);
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

function SheetContent({ className, ...props }: ViewProps & { className?: string }) {
  return <View className={cn('flex-col gap-4 px-4 pb-4', className)} {...props} />;
}

function SheetHeader({ className, ...props }: ViewProps & { className?: string }) {
  return <View className={cn('flex-col gap-1.5 px-4 pt-4', className)} {...props} />;
}

function SheetFooter({ className, ...props }: ViewProps & { className?: string }) {
  return <View className={cn('mt-auto flex-col gap-3 p-4', className)} {...props} />;
}

function SheetTitle({ className, ...props }: TextProps & { className?: string }) {
  return (
    <Text
      accessibilityRole="header"
      className={cn('font-heading text-foreground', className)}
      {...props}
    />
  );
}

function SheetDescription({ className, ...props }: TextProps & { className?: string }) {
  return <Text className={cn('font-base text-sm text-foreground', className)} {...props} />;
}

export {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetFooter,
  SheetTitle,
  SheetDescription,
  SheetClose,
  SheetHandle,
};
export type { SheetProps, SheetSide };
