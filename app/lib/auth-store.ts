import type { Session, User } from '@supabase/supabase-js';
import { create } from 'zustand';

import { supabase } from './supabase';

type AuthState = {
  session: Session | null;
  user: User | null;
  initialized: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
  init: () => Promise<void>;
};

export const useAuthStore = create<AuthState>((set) => ({
  session: null,
  user: null,
  initialized: false,

  signIn: async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (data.session) {
      set({ session: data.session, user: data.session.user });
    }
    return { error };
  },

  signOut: async () => {
    await supabase.auth.signOut();
    set({ session: null, user: null });
  },

  init: async () => {
    const { data } = await supabase.auth.getSession();
    set({ session: data.session, user: data.session.user ?? null, initialized: true });

    // Keep the store in sync with token refresh / external sign-out.
    supabase.auth.onAuthStateChange((_event, session) => {
      set({ session, user: session?.user ?? null });
    });
  },
}));
