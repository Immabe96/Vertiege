import * as React from 'react';
import { Pressable, View } from 'react-native';
import Animated, { SlideInUp, SlideOutUp, useReducedMotion } from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Text } from '@/components/ui/text';
import { cn } from '@/lib/cn';
import { MOTION } from '@/lib/theme/tokens';

/**
 * Ported from https://www.neobrutalism.dev/docs/toast
 *
 * Web → RN translation (rn-rewrite-plan.md §9.1):
 *   portal + `fixed top-0`   → provider-rendered overlay pinned to the safe area
 *   `animate-in`/`duration` → Reanimated `SlideInUp`/`SlideOutUp`, 150ms in
 *   swipe/hover dismissal   → tap to dismiss + auto-dismiss timer
 *   `role="status"`         → `accessibilityLiveRegion="polite"`
 */
type ToastTone = 'default' | 'success' | 'warning' | 'danger';

type ToastOptions = {
  title: string;
  description?: string;
  tone?: ToastTone;
  /** ms before auto-dismiss. `0` keeps it until tapped. */
  duration?: number;
};

type ToastRecord = ToastOptions & { id: string };

type ToastContextValue = {
  toast: (options: ToastOptions) => string;
  dismiss: (id: string) => void;
};

const ToastContext = React.createContext<ToastContextValue | null>(null);

const TONE_CLASS: Record<ToastTone, string> = {
  default: 'bg-background',
  success: 'bg-success',
  warning: 'bg-warning',
  danger: 'bg-danger',
};

const TONE_LABEL_CLASS: Record<ToastTone, string> = {
  default: 'text-foreground',
  success: 'text-success-foreground',
  warning: 'text-warning-foreground',
  danger: 'text-danger-foreground',
};

function useToast(): ToastContextValue {
  const ctx = React.useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used inside <ToastProvider>');
  return ctx;
}

function ToastProvider({ children }: { children?: React.ReactNode }) {
  const [toasts, setToasts] = React.useState<ToastRecord[]>([]);
  const timers = React.useRef(new Map<string, ReturnType<typeof setTimeout>>());

  const dismiss = React.useCallback((id: string) => {
    const timer = timers.current.get(id);
    if (timer) clearTimeout(timer);
    timers.current.delete(id);
    setToasts((current) => current.filter((t) => t.id !== id));
  }, []);

  const toast = React.useCallback((options: ToastOptions) => {
    const id = `toast-${Date.now()}-${Math.round(Math.random() * 1e6)}`;
    setToasts((current) => [...current, { ...options, id }]);

    const duration = options.duration ?? 4000;
    if (duration > 0) {
      timers.current.set(
        id,
        setTimeout(() => {
          timers.current.delete(id);
          setToasts((current) => current.filter((t) => t.id !== id));
        }, duration)
      );
    }
    return id;
  }, []);

  React.useEffect(() => {
    const pending = timers.current;
    return () => {
      pending.forEach((timer) => clearTimeout(timer));
      pending.clear();
    };
  }, []);

  const ctx = React.useMemo(() => ({ toast, dismiss }), [dismiss, toast]);

  return (
    <ToastContext.Provider value={ctx}>
      {children}
      <ToastHost toasts={toasts} onDismiss={dismiss} />
    </ToastContext.Provider>
  );
}

function ToastHost({
  toasts,
  onDismiss,
}: {
  toasts: ToastRecord[];
  onDismiss: (id: string) => void;
}) {
  const insets = useSafeAreaInsets();

  if (toasts.length === 0) return null;

  return (
    <View
      pointerEvents="box-none"
      accessibilityLiveRegion="polite"
      className="absolute inset-x-0 top-0 z-50 gap-2 px-4"
      style={{ paddingTop: insets.top + 8 }}>
      {toasts.map((item) => (
        <ToastItem key={item.id} toast={item} onDismiss={onDismiss} />
      ))}
    </View>
  );
}

function ToastItem({ toast, onDismiss }: { toast: ToastRecord; onDismiss: (id: string) => void }) {
  const reduceMotion = useReducedMotion();
  const tone = toast.tone ?? 'default';

  return (
    <Animated.View
      entering={reduceMotion ? undefined : SlideInUp.duration(MOTION.enter)}
      exiting={reduceMotion ? undefined : SlideOutUp.duration(MOTION.enter)}
      accessibilityRole="alert"
      accessibilityLiveRegion="assertive">
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`Dismiss: ${toast.title}`}
        onPress={() => onDismiss(toast.id)}
        className={cn(
          'w-full flex-col gap-1 rounded-base border-2 border-border p-4 shadow-shadow',
          TONE_CLASS[tone]
        )}>
        <Text variant="small" className={cn('font-heading', TONE_LABEL_CLASS[tone])}>
          {toast.title}
        </Text>
        {toast.description ? (
          <Text variant="caption" className={cn('font-base', TONE_LABEL_CLASS[tone])}>
            {toast.description}
          </Text>
        ) : null}
      </Pressable>
    </Animated.View>
  );
}

export { ToastProvider, ToastHost, useToast };
export type { ToastOptions, ToastRecord, ToastTone };
