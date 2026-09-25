import * as React from 'react';
import { type TextProps, type ViewProps } from 'react-native';

import { Button } from '@/components/ui/button';

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  type DialogProps,
} from '@/components/ui/dialog';
import { cn } from '@/lib/cn';

/**
 * Ported from https://www.neobrutalism.dev/docs/alert-dialog
 *
 * Upstream's `AlertDialog` is the dialog primitive with destructive-confirmation
 * semantics bolted on. On RN that means: same Modal, but the panel carries
 * `accessibilityRole="alert"` so screen readers interrupt — the only
 * behavioural difference (rn-rewrite-plan.md §9.1).
 */
function AlertDialog({ children, ...props }: DialogProps) {
  return <Dialog {...props}>{children}</Dialog>;
}

function AlertDialogContent({
  className,
  ...props
}: ViewProps & { className?: string; children?: React.ReactNode }) {
  return <DialogContent accessible accessibilityRole="alert" className={className} {...props} />;
}

function AlertDialogHeader({ className, ...props }: ViewProps & { className?: string }) {
  return <DialogHeader className={className} {...props} />;
}

function AlertDialogFooter({ className, ...props }: ViewProps & { className?: string }) {
  return <DialogFooter className={className} {...props} />;
}

function AlertDialogTitle({ className, ...props }: TextProps & { className?: string }) {
  return <DialogTitle className={className} {...props} />;
}

function AlertDialogDescription({ className, ...props }: TextProps & { className?: string }) {
  return <DialogDescription className={className} {...props} />;
}

/** Confirm action — defaults to the loud `main` fill. */
function AlertDialogAction({
  className,
  variant = 'default',
  ...props
}: React.ComponentProps<typeof Button> & { className?: string }) {
  return <Button variant={variant} className={cn('flex-1', className)} {...props} />;
}

/** Dismisses the dialog; pairs with `DialogClose` semantics (`Esc`/back). */
function AlertDialogCancel({ className, ...props }: React.ComponentProps<typeof Button>) {
  return <Button variant="neutral" className={cn('flex-1', className)} {...props} />;
}

export {
  AlertDialog,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogFooter,
  AlertDialogTitle,
  AlertDialogDescription,
  AlertDialogAction,
  AlertDialogCancel,
};
