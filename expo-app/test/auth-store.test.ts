import type { Session, User } from '@supabase/supabase-js';

import { useAuthStore } from '@/lib/auth-store';
import { supabase } from '@/lib/supabase';

jest.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: jest.fn(),
      onAuthStateChange: jest.fn(() => ({
        data: { subscription: { unsubscribe: jest.fn() } },
      })),
      signInWithPassword: jest.fn(),
      signOut: jest.fn(),
    },
  },
}));

const mockedAuth = supabase.auth as jest.Mocked<typeof supabase.auth>;

const makeUser = (id: string, email: string): User =>
  ({
    id,
    email,
    app_metadata: {},
    user_metadata: {},
    aud: 'authenticated',
    created_at: '2026-01-01T00:00:00.000Z',
  }) as unknown as User;

const makeSession = (user: User): Session =>
  ({
    access_token: 'access',
    refresh_token: 'refresh',
    expires_in: 3600,
    token_type: 'bearer',
    user,
  }) as unknown as Session;

const resetStore = () => useAuthStore.setState({ session: null, user: null, initialized: false });

describe('useAuthStore', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    resetStore();
  });

  it('finishes booting when there is no stored session', async () => {
    mockedAuth.getSession.mockResolvedValue({ data: { session: null } } as never);

    await useAuthStore.getState().init();

    const state = useAuthStore.getState();
    expect(state.initialized).toBe(true);
    expect(state.session).toBeNull();
    expect(state.user).toBeNull();
  });

  it('still boots when getSession rejects', async () => {
    mockedAuth.getSession.mockRejectedValue(new Error('corrupt session'));

    await useAuthStore.getState().init();

    const state = useAuthStore.getState();
    expect(state.initialized).toBe(true);
    expect(state.session).toBeNull();
    expect(state.user).toBeNull();
  });

  it('restores session and user from a stored session', async () => {
    const session = makeSession(makeUser('r1', 'a@b.co'));
    mockedAuth.getSession.mockResolvedValue({ data: { session } } as never);

    await useAuthStore.getState().init();

    const state = useAuthStore.getState();
    expect(state.initialized).toBe(true);
    expect(state.session).toBe(session);
    expect(state.user).toBe(session.user);
  });

  it('subscribes to auth state changes exactly once per init', async () => {
    mockedAuth.getSession.mockResolvedValue({ data: { session: null } } as never);

    await useAuthStore.getState().init();

    expect(mockedAuth.onAuthStateChange).toHaveBeenCalledTimes(1);
  });

  it('signIn stores the returned session', async () => {
    const session = makeSession(makeUser('r1', 'a@b.co'));
    mockedAuth.signInWithPassword.mockResolvedValue({
      data: { session, user: session.user },
      error: null,
    } as never);

    const { error } = await useAuthStore.getState().signIn('a@b.co', 'pw');

    expect(error).toBeNull();
    expect(useAuthStore.getState().session).toBe(session);
  });

  it('signIn surfaces the error and leaves the store signed out', async () => {
    mockedAuth.signInWithPassword.mockResolvedValue({
      data: { session: null, user: null },
      error: new Error('Invalid login credentials'),
    } as never);

    const { error } = await useAuthStore.getState().signIn('a@b.co', 'nope');

    expect(error?.message).toBe('Invalid login credentials');
    expect(useAuthStore.getState().session).toBeNull();
    expect(useAuthStore.getState().user).toBeNull();
  });

  it('signOut clears both session and user', async () => {
    const session = makeSession(makeUser('r1', 'a@b.co'));
    useAuthStore.setState({ session, user: session.user });

    await useAuthStore.getState().signOut();

    expect(mockedAuth.signOut).toHaveBeenCalledTimes(1);
    expect(useAuthStore.getState().session).toBeNull();
    expect(useAuthStore.getState().user).toBeNull();
  });
});
