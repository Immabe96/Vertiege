import * as React from 'react';
import { Image, View, type ImageProps, type ViewProps } from 'react-native';

import { Text } from '@/components/ui/text';
import { cn } from '@/lib/cn';

/**
 * Ported from https://www.neobrutalism.dev/docs/avatar
 *
 * `outline-2 outline-border` → `border-2 border-border` on the shell.
 * `AvatarImage` falls back to `AvatarFallback` on load error (upstream relies
 * on the Base UI fallback primitive, which RN does not have).
 */
const avatarSizes = {
  sm: 'size-8',
  default: 'size-10',
  lg: 'size-12',
} as const;

type AvatarSize = keyof typeof avatarSizes;

type AvatarProps = ViewProps & {
  className?: string;
  size?: AvatarSize;
  /** Rendered when `src` is missing or fails to load. */
  fallback?: string;
  src?: ImageProps['source'];
  children?: React.ReactNode;
};

function Avatar({ className, size = 'default', src, fallback, children, ...props }: AvatarProps) {
  const [failed, setFailed] = React.useState(false);
  const [loaded, setLoaded] = React.useState(false);

  // Reset during render when the source changes — React's documented
  // alternative to a setState-in-effect (no cascading render).
  const [prevSrc, setPrevSrc] = React.useState(src);
  if (src !== prevSrc) {
    setPrevSrc(src);
    setFailed(false);
    setLoaded(false);
  }

  const showImage = src && !failed;

  return (
    <View
      accessible
      accessibilityLabel={fallback ? `Avatar ${fallback}` : 'Avatar'}
      className={cn(
        'shrink-0 items-center justify-center overflow-hidden rounded-full border-2 border-border bg-secondary-background',
        avatarSizes[size],
        className
      )}
      {...props}>
      {showImage ? (
        <Image
          source={src}
          resizeMode="cover"
          onLoad={() => setLoaded(true)}
          onError={() => setFailed(true)}
          className={cn('size-full rounded-full', !loaded && 'opacity-0')}
        />
      ) : null}
      {!showImage ? <AvatarFallback size={size}>{fallback ?? ''}</AvatarFallback> : null}
      {children}
    </View>
  );
}

function AvatarFallback({
  className,
  size = 'default',
  children,
}: {
  className?: string;
  size?: AvatarSize;
  children?: React.ReactNode;
}) {
  return (
    <View
      className={cn(
        'size-full items-center justify-center rounded-full bg-secondary-background',
        className
      )}>
      <Text
        className={cn(
          'font-base text-foreground',
          size === 'sm' && 'text-xs',
          size === 'lg' && 'text-lg'
        )}>
        {children}
      </Text>
    </View>
  );
}

function AvatarBadge({ className, ...props }: ViewProps & { className?: string }) {
  return (
    <View
      accessibilityLabel="Online"
      className={cn(
        'absolute bottom-0 right-0 z-10 size-4 items-center justify-center rounded-full border-2 border-border bg-main',
        className
      )}
      {...props}
    />
  );
}

export { Avatar, AvatarFallback, AvatarBadge };
export type { AvatarProps, AvatarSize };
