import {
  RESERVED_WORLD_SEGMENTS,
  resolveHostDeepLink,
  resolveRedirect,
  resolveRedirectHop,
  resolveResidentOnboardingRedirect,
  resolveUnauthenticatedRedirect,
  resolveWorldChannel,
  resolveWorldSegment,
  type RedirectState,
} from '@/lib/router/resolve-redirect';

const authed: RedirectState = {
  location: '/',
  hasSession: true,
  isLoadingResident: false,
  hasResident: true,
  gateCompleted: true,
  isVerifier: false,
  tier: 1,
};

const guest: RedirectState = { ...authed, hasSession: false };

describe('deep-link hosts (deep_link_redirects.dart)', () => {
  test('resolves every registered host in the Flutter order', () => {
    expect(resolveHostDeepLink('vertiege://verifier/review')).toBe('/verifier/review');
    expect(resolveHostDeepLink('vertiege://auth/callback2')).toBe('/auth/callback2');
    expect(resolveHostDeepLink('vertiege://invite/ABC123')).toBe('/invite/ABC123');
    expect(resolveHostDeepLink('vertiege://residents/uuid-1')).toBe('/residents/uuid-1');
    expect(resolveHostDeepLink('vertiege://post/uuid-2')).toBe('/post/uuid-2');
    expect(resolveHostDeepLink('vertiege://world/uuid-3')).toBe('/explore/uuid-3');
    expect(resolveHostDeepLink('vertiege://chat/room-1')).toBe('/chat/room-1');
    expect(resolveHostDeepLink('vertiege://notifications/msg-1')).toBe('/notifications/msg-1');
  });

  test('is a no-op for unknown hosts and already-mapped paths', () => {
    expect(resolveHostDeepLink('vertiege://nexus/feed')).toBeNull();
    expect(resolveHostDeepLink('vertiege://chat/room-1')).toBe('/chat/room-1');
    expect(resolveHostDeepLink(undefined)).toBeNull();
    expect(resolveHostDeepLink('not a url')).toBeNull();
  });

  test('auth host: /callback and bare paths map to the OAuth callback', () => {
    expect(
      resolveRedirect({ ...authed, url: 'vertiege://auth/callback', location: '/callback' })
    ).toBe('/auth/callback');
    expect(resolveRedirect({ ...authed, url: 'vertiege://auth/', location: '/' })).toBe(
      '/auth/callback'
    );
    // Already at the callback → never interrupted.
    expect(
      resolveRedirect({ ...authed, url: 'vertiege://auth/callback', location: '/auth/callback' })
    ).toBeNull();
  });

  test('verifier host: bare and /login land on the verifier login', () => {
    expect(resolveRedirect({ ...guest, url: 'vertiege://verifier/', location: '/' })).toBe(
      '/verifier/login'
    );
    expect(
      resolveRedirect({ ...guest, url: 'vertiege://verifier/login', location: '/login' })
    ).toBe('/verifier/login');
  });

  test('notifications host without an id lands on the inbox', () => {
    expect(resolveRedirect({ ...authed, url: 'vertiege://notifications', location: '/' })).toBe(
      '/notifications'
    );
  });
});

describe('verifier portal', () => {
  const at = (location: string, state: Partial<RedirectState> = {}) =>
    resolveRedirect({ ...authed, location, ...state });

  test('legacy admin URL → verifier review (or login when signed out)', () => {
    expect(at('/admin/verifications', { isVerifier: true })).toBe('/verifier/review');
    expect(at('/admin/verifications', { hasSession: false })).toBe('/verifier/login');
    // Signed in but not staff → the chain keeps running, exactly like GoRouter:
    // /verifier/review → /login → / (auth page exit).
    expect(at('/admin/verifications', { isVerifier: false })).toBe('/');
  });

  test('signed-out visitors only stay on the verifier login', () => {
    expect(at('/verifier/review', { hasSession: false })).toBe('/verifier/login');
    expect(at('/verifier/login', { hasSession: false })).toBeNull();
  });

  test('non-verifier sessions are bounced off the portal, verifier logins to /', () => {
    expect(at('/verifier/review', { isVerifier: false })).toBe('/');
    expect(at('/verifier/login', { isVerifier: true })).toBe('/');
    expect(at('/verifier/review', { isVerifier: true })).toBeNull();
  });
});

describe('session and onboarding', () => {
  test('guests reach /login unless the page handles its own state', () => {
    expect(
      resolveUnauthenticatedRedirect({ hasSession: false, location: '/search', isAuthPage: false })
    ).toBe('/login');
    expect(
      resolveUnauthenticatedRedirect({ hasSession: false, location: '/login', isAuthPage: true })
    ).toBeNull();
    expect(
      resolveUnauthenticatedRedirect({ hasSession: true, location: '/search', isAuthPage: false })
    ).toBeNull();
    expect(resolveRedirect({ ...guest, location: '/search' })).toBe('/login');
    expect(resolveRedirect({ ...guest, location: '/login' })).toBeNull();
    // Invite links work signed out — the page renders its own accept flow.
    expect(resolveRedirect({ ...guest, location: '/invite/ABC' })).toBeNull();
  });

  test('missing resident or an unfinished gate routes to onboarding', () => {
    expect(
      resolveResidentOnboardingRedirect({
        hasSession: true,
        isLoading: false,
        hasResident: false,
        gateCompleted: false,
        location: '/',
        isAuthPage: false,
      })
    ).toBe('/onboarding');
    expect(resolveRedirect({ ...authed, hasResident: false })).toBe('/onboarding');
    expect(resolveRedirect({ ...authed, hasResident: false, location: '/onboarding' })).toBeNull();
    expect(resolveRedirect({ ...authed, gateCompleted: false })).toBe('/onboarding');
  });

  test('never bounces while the resident is still loading', () => {
    expect(resolveRedirect({ ...authed, isLoadingResident: true, hasResident: false })).toBeNull();
  });

  test('signed-in residents leave the auth pages for the Nexus', () => {
    expect(resolveRedirect({ ...authed, location: '/login' })).toBe('/');
    expect(resolveRedirect({ ...authed, location: '/signup' })).toBe('/');
    expect(resolveRedirect({ ...authed, location: '/onboarding' })).toBe('/');
  });
});

describe('tier gates', () => {
  test('/create-world needs tier 2+', () => {
    expect(resolveRedirect({ ...authed, location: '/create-world', tier: 1 })).toBe('/');
    expect(resolveRedirect({ ...authed, location: '/create-world', tier: 2 })).toBeNull();
  });

  test('ascension needs tier 3+', () => {
    expect(resolveRedirect({ ...authed, location: '/hall-of-ascension', tier: 2 })).toBe(
      '/progress'
    );
    expect(resolveRedirect({ ...authed, location: '/ascension-path', tier: 2 })).toBe('/progress');
    expect(resolveRedirect({ ...authed, location: '/ascension-path', tier: 3 })).toBeNull();
  });
});

describe('feature flags', () => {
  test('Campfire is off → world root (with worldId) or chat', () => {
    expect(resolveRedirect({ ...authed, location: '/campfire/chan-1' })).toBe('/chat');
    expect(resolveRedirect({ ...authed, location: '/campfire/chan-1?worldId=w%2F1' })).toBe(
      '/explore/w%2F1'
    );
    expect(
      resolveRedirect({ ...authed, location: '/campfire/chan-1', featureFlags: { campfire: true } })
    ).toBeNull();
  });

  test('beta world sub-pages fall back to the world root when disabled', () => {
    expect(resolveRedirect({ ...authed, location: '/explore/w1/jobs' })).toBe('/explore/w1');
    expect(resolveRedirect({ ...authed, location: '/explore/w1/treasury' })).toBe('/explore/w1');
    expect(resolveRedirect({ ...authed, location: '/explore/w1/academy' })).toBe('/explore/w1');
    expect(resolveRedirect({ ...authed, location: '/explore/w1/sanctuary' })).toBe('/explore/w1');
    expect(resolveRedirect({ ...authed, location: '/explore/w1/marketplace' })).toBe('/explore/w1');
    expect(
      resolveRedirect({
        ...authed,
        location: '/explore/w1/jobs',
        featureFlags: { worldJobs: true },
      })
    ).toBeNull();
  });

  test('enabled sub-pages are left alone', () => {
    expect(
      resolveRedirect({
        ...authed,
        location: '/explore/w1/marketplace',
        featureFlags: { marketplace: true },
      })
    ).toBeNull();
  });
});

describe('redirect aliases (rn-rewrite-plan.md §8.9)', () => {
  test('/you and /more collapse onto the identity tab', () => {
    expect(resolveRedirect({ ...authed, location: '/you' })).toBe('/identity');
    expect(resolveRedirect({ ...authed, location: '/more' })).toBe('/identity');
  });

  test('bare /explore is the worlds tab', () => {
    expect(resolveRedirect({ ...authed, location: '/explore' })).toBe('/worlds');
  });

  test('legacy root query shapes still resolve', () => {
    expect(resolveRedirect({ ...authed, location: '/?panel=discover' })).toBe('/explore/discover');
    expect(resolveRedirect({ ...authed, location: '/?world=abc' })).toBe('/explore/abc');
  });

  test('aliases are re-checked for auth after they resolve', () => {
    expect(resolveRedirect({ ...guest, location: '/you' })).toBe('/login');
    expect(resolveRedirect({ ...guest, location: '/explore' })).toBe('/login');
  });
});

describe('world sub-routes (world_route_redirects.dart)', () => {
  test('reserved segments map off the channel route', () => {
    expect(RESERVED_WORLD_SEGMENTS.has('members')).toBe(true);
    expect(resolveWorldSegment({ worldId: 'w1', segment: 'members', query: 'tab=1' })).toBe(
      '/explore/w1/members?tab=1'
    );
    expect(resolveWorldSegment({ worldId: 'w1', segment: 'general' })).toBeNull();
  });

  test('channel routes need ?id=', () => {
    expect(resolveWorldChannel({ worldId: 'w1', queryParams: { id: 'c1' } })).toBeNull();
    expect(resolveWorldChannel({ worldId: 'w1', queryParams: {} })).toBe('/explore/w1');
    expect(resolveWorldChannel({ worldId: 'w1', queryParams: { id: '  ' } })).toBe('/explore/w1');
  });
});

describe('hop chaining', () => {
  test('one hop stays one hop', () => {
    expect(resolveRedirectHop({ ...authed, location: '/you' })).toBe('/identity');
    expect(
      resolveRedirectHop({ ...authed, location: '/admin/verifications', isVerifier: true })
    ).toBe('/verifier/review');
  });

  test('chains until it stabilises (GoRouter re-runs redirect)', () => {
    // admin → verifier review → verifier login (guest) → stable
    expect(resolveRedirect({ ...guest, location: '/admin/verifications' })).toBe('/verifier/login');
    // onboarding is only visited once the alias has resolved
    expect(resolveRedirect({ ...authed, location: '/you', hasResident: false })).toBe(
      '/onboarding'
    );
  });

  test('a clean authenticated path is not moved', () => {
    expect(resolveRedirect({ ...authed, location: '/worlds' })).toBeNull();
    expect(resolveRedirect({ ...authed, location: '/post/uuid-9' })).toBeNull();
  });
});
