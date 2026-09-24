import { QueryClient } from '@tanstack/react-query';

/**
 * Server-state cache over supabase-js. Supabase itself is not fetch-based, so
 * we drive queries through `queryFn`s that call `supabase` directly — the
 * cache/dedup/invalidation behaviour is what we're here for.
 *
 * Tuning notes for React Native: there is no `window`, so `refetchOnWindowFocus`
 * is a no-op unless a focus manager is registered; we disable it explicitly so
 * the intent is visible.
 */
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      gcTime: 5 * 60_000,
      retry: 1,
      refetchOnWindowFocus: false,
      refetchOnReconnect: true,
    },
    mutations: {
      retry: 0,
    },
  },
});
