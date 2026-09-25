/**
 * Pure redirect resolution — the RN port of GoRouter's `redirect:` chain.
 *
 * Sources (Flutter, `flutter-app/lib/router/`):
 *   app_router.dart           the root `redirect:` callback (order matters)
 *   app_auth_redirect.dart    session / onboarding / gate helpers
 *   deep_link_redirects.dart  `vertiege://<host>/…` → in-app path
 *   world_route_redirects.dart reserved world segments + channel id guard
 *
 * Pure by design: no navigation, no Supabase, no React — state in, path out
 * (`null` = "let the navigation proceed"). Path vocabulary is the RN one from
 * rn-rewrite-plan.md §8 (`/worlds` for the Explore tab, `/identity` tab).
 */

/** Remote-Config gates. All default to `false`, matching `FeatureFlags`. */
export type FeatureFlags = {
  campfire?: boolean;
  worldJobs?: boolean;
  treasury?: boolean;
  academy?: boolean;
  marketplace?: boolean;
};

export type RedirectState = {
  /** Path + query being navigated to, e.g. `/explore/abc?tab=members`. */
  location: string;
  /** Full deep link (`vertiege://…`) when navigation came from an OS link. */
  url?: string;
  hasSession: boolean;
  /** Resident profile still loading — never bounce mid-load. */
  isLoadingResident: boolean;
  hasResident: boolean;
  /** Resident's gate flag (DB); the local cache is folded in by the caller. */
  gateCompleted?: boolean;
  /** Supabase `is_verifier` metadata. */
  isVerifier?: boolean;
  /** `ResidentTier.value` (1 Hustler … 5 Apex). */
  tier?: number;
  featureFlags?: FeatureFlags;
};

const MIN_TIER_CREATE_WORLD = 2;
const MIN_TIER_ASCENSION = 3;

const AUTH_PAGES = new Set(['/login', '/signup']);

/** RN-side static path aliases (rn-rewrite-plan.md §8.9). */
const PATH_ALIASES: Record<string, string> = {
  '/admin/verifications': '/verifier/review',
  '/you': '/identity',
  '/more': '/identity',
  /** Bare Explore tab is now the Worlds tab. */
  '/explore': '/worlds',
};

function splitLocation(location: string): { path: string; search: string } {
  const index = location.indexOf('?');
  if (index < 0) return { path: location || '/', search: '' };
  return { path: location.slice(0, index) || '/', search: location.slice(index + 1) };
}

function parseUrl(url: string | undefined) {
  if (!url) return null;
  try {
    const parsed = new URL(url);
    return {
      host: parsed.host,
      path: parsed.pathname || '/',
      segments: parsed.pathname.split('/').filter(Boolean),
      query: parsed.search.replace(/^\?/, ''),
    };
  } catch {
    return null;
  }
}

function withQuery(path: string, query: string): string {
  return query ? `${path}?${query}` : path;
}

function encodeSegment(value: string): string {
  return encodeURIComponent(value);
}

// ── Deep-link hosts (deep_link_redirects.dart) ──────────────────────────────

/** `vertiege://auth/callback` → host `auth`, path `/callback`. */
export function redirectAuthHostDeepLink(host: string, location: string): string | null {
  if (host !== 'auth' || location === '/auth/callback') return null;
  if (location === '/callback' || location === '' || location === '/') return '/auth/callback';
  if (!location.startsWith('/auth')) return `/auth${location}`;
  return null;
}

/** `vertiege://verifier/login` → `/verifier/…`. */
export function redirectVerifierHostDeepLink(host: string, location: string): string | null {
  if (host !== 'verifier' || location.startsWith('/verifier')) return null;
  if (location === '/login' || location === '' || location === '/') return '/verifier/login';
  return `/verifier${location}`;
}

function hostSegmentRedirect(
  host: string,
  expectedHost: string,
  location: string,
  targetBase: string
): string | null {
  if (host !== expectedHost || location.startsWith(targetBase)) return null;
  const [pathname, search = ''] = location.split('?');
  const [, id] = pathname.split('/');
  if (!id) return null;
  return withQuery(`${targetBase}/${encodeSegment(id)}`, search);
}

/** `vertiege://residents/UUID` → `/residents/UUID`. */
export function redirectResidentsHostDeepLink(host: string, location: string): string | null {
  return hostSegmentRedirect(host, 'residents', location, '/residents');
}

/** `vertiege://invite/ABC123` → `/invite/ABC123`. */
export function redirectInviteHostDeepLink(host: string, location: string): string | null {
  return hostSegmentRedirect(host, 'invite', location, '/invite');
}

/** `vertiege://post/UUID` → `/post/UUID`. */
export function redirectPostHostDeepLink(host: string, location: string): string | null {
  return hostSegmentRedirect(host, 'post', location, '/post');
}

/** `vertiege://world/UUID` → `/explore/UUID`. */
export function redirectWorldHostDeepLink(host: string, location: string): string | null {
  return hostSegmentRedirect(host, 'world', location, '/explore');
}

/** `vertiege://chat/ROOM_ID` → `/chat/ROOM_ID`. */
export function redirectChatHostDeepLink(host: string, location: string): string | null {
  return hostSegmentRedirect(host, 'chat', location, '/chat');
}

/** `vertiege://notifications/UUID` → `/notifications/UUID` (bare → index). */
export function redirectNotificationsHostDeepLink(host: string, location: string): string | null {
  if (host !== 'notifications' || location.startsWith('/notifications')) return null;
  const [pathname, search = ''] = location.split('?');
  const [, id] = pathname.split('/');
  if (!id) return '/notifications';
  return withQuery(`/notifications/${encodeSegment(id)}`, search);
}

const HOST_REDIRECTS: ((host: string, location: string) => string | null)[] = [
  redirectVerifierHostDeepLink,
  redirectAuthHostDeepLink,
  redirectInviteHostDeepLink,
  redirectResidentsHostDeepLink,
  redirectPostHostDeepLink,
  redirectWorldHostDeepLink,
  redirectChatHostDeepLink,
  redirectNotificationsHostDeepLink,
];

/**
 * First matching host-deep-link redirect, or `null`.
 *
 * Dart reads host *and* path off the same `Uri`, so the path fed to the
 * helpers is the caller's `location` (defaulting to the URL's own path).
 */
export function resolveHostDeepLink(url: string | undefined, location?: string): string | null {
  const parsed = parseUrl(url);
  if (!parsed) return null;
  const path = location === undefined ? parsed.path : location;
  for (const redirect of HOST_REDIRECTS) {
    const result = redirect(parsed.host, path);
    if (result) return result;
  }
  return null;
}

// ── Session / onboarding (app_auth_redirect.dart) ───────────────────────────

export function resolveUnauthenticatedRedirect(input: {
  hasSession: boolean;
  location: string;
  isAuthPage: boolean;
}): string | null {
  if (input.hasSession || input.isAuthPage) return null;
  return '/login';
}

export function resolveResidentOnboardingRedirect(input: {
  hasSession: boolean;
  isLoading: boolean;
  hasResident: boolean;
  gateCompleted: boolean;
  location: string;
  isAuthPage: boolean;
}): string | null {
  if (!input.hasSession || input.isLoading) return null;

  if (!input.hasResident) {
    return input.location === '/onboarding' ? null : '/onboarding';
  }

  if (!input.gateCompleted) {
    return input.location === '/onboarding' ? null : '/onboarding';
  }

  if (input.isAuthPage || input.location === '/onboarding') {
    return '/';
  }

  return null;
}

// ── World sub-routes (world_route_redirects.dart) ──────────────────────────

export const RESERVED_WORLD_SEGMENTS: ReadonlySet<string> = new Set([
  'discover',
  'members',
  'settings',
  'marketplace',
  'polls',
  'treasury',
  'challenges',
  'jobs',
  'archive',
  'academy',
  'sanctuary',
  'manage',
  'governance',
]);

/** A reserved segment that hit `:channelName` → the real sub-page. */
export function resolveWorldSegment(input: {
  worldId: string;
  segment: string;
  query?: string;
}): string | null {
  if (!RESERVED_WORLD_SEGMENTS.has(input.segment)) return null;
  return withQuery(`/explore/${encodeSegment(input.worldId)}/${input.segment}`, input.query ?? '');
}

/** Channel routes require `?id=`; without it, drop back to the world root. */
export function resolveWorldChannel(input: {
  worldId: string;
  queryParams: Record<string, string | undefined>;
}): string | null {
  const id = input.queryParams.id?.trim() ?? '';
  if (id) return null;
  return `/explore/${encodeSegment(input.worldId)}`;
}

// ── Root redirect ───────────────────────────────────────────────────────────

const BETA_WORLD_FEATURE = /^\/explore\/([^/]+)\/(jobs|treasury|academy|sanctuary|marketplace)$/;

/**
 * Runs the whole chain once and returns the destination, or `null` to proceed.
 * `state.location` may still carry a query — it is stripped and re-applied by
 * the alias helpers where Flutter read `state.uri.queryParameters`.
 */
export function resolveRedirectHop(state: RedirectState): string | null {
  const { path, search } = splitLocation(state.location);

  const deepLink = resolveHostDeepLink(state.url, path);
  if (deepLink) return deepLink;

  const query = new URLSearchParams(search);
  const location = path;

  // Never interrupt deep-link auth callbacks.
  if (location === '/auth/callback') return null;

  const alias = PATH_ALIASES[location];
  if (alias) return alias;

  // Legacy web/IPC shapes: `/?panel=discover`, `/?world=<id>`.
  if (location === '/') {
    const panel = query.get('panel');
    if (panel) return `/explore/${encodeSegment(panel)}`;
    const world = query.get('world');
    if (world) return `/explore/${encodeSegment(world)}`;
  }

  const isVerifierRoute = location.startsWith('/verifier');
  const isVerifierLogin = location === '/verifier/login';
  const isInviteRoute = location.startsWith('/invite/');
  const isAuthPage = AUTH_PAGES.has(location);

  // ── Verifier portal (staff review; same session as main app) ──
  if (isVerifierRoute) {
    if (!state.hasSession) return isVerifierLogin ? null : '/verifier/login';
    if (!state.isVerifier) return '/login';
    if (isVerifierLogin) return '/';
    return null;
  }

  const unauthenticated = resolveUnauthenticatedRedirect({
    hasSession: state.hasSession,
    location,
    isAuthPage: isAuthPage || isInviteRoute,
  });
  if (unauthenticated) return unauthenticated;

  if (!isInviteRoute) {
    const onboarding = resolveResidentOnboardingRedirect({
      hasSession: state.hasSession,
      isLoading: state.isLoadingResident,
      hasResident: state.hasResident,
      gateCompleted: state.gateCompleted ?? false,
      location,
      isAuthPage,
    });
    if (onboarding) return onboarding;
  }

  if (!state.hasResident) return null;

  const tier = state.tier ?? 1;
  if (location === '/create-world' && tier < MIN_TIER_CREATE_WORLD) return '/';

  if (
    (location === '/hall-of-ascension' || location === '/ascension-path') &&
    tier < MIN_TIER_ASCENSION
  ) {
    return '/progress';
  }

  const flags = state.featureFlags ?? {};
  if (location.startsWith('/campfire/') && !flags.campfire) {
    const worldId = query.get('worldId');
    if (worldId) return `/explore/${encodeSegment(worldId)}`;
    return '/chat';
  }

  const beta = BETA_WORLD_FEATURE.exec(location);
  if (beta) {
    const [, worldId, feature] = beta;
    const enabled =
      feature === 'jobs'
        ? Boolean(flags.worldJobs)
        : feature === 'treasury'
          ? Boolean(flags.treasury)
          : feature === 'academy' || feature === 'sanctuary'
            ? Boolean(flags.academy)
            : Boolean(flags.marketplace);
    if (!enabled) return `/explore/${encodeSegment(worldId)}`;
  }

  return null;
}

/**
 * GoRouter re-runs its redirect for every path it lands on, so one pass is
 * rarely the final answer (`/admin/verifications` → `/verifier/review` →
 * session gate → `/verifier/login`). This walks the chain until it stabilises.
 */
export function resolveRedirect(state: RedirectState, maxHops = 5): string | null {
  let current = state;
  let destination = resolveRedirectHop(current);

  for (let hop = 1; hop < maxHops && destination !== null; hop += 1) {
    current = { ...current, url: undefined, location: destination };
    const next = resolveRedirectHop(current);
    if (next === null || next === destination) return destination;
    destination = next;
  }

  return destination;
}
