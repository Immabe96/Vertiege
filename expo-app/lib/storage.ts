import { createMMKV } from 'react-native-mmkv';

/**
 * General-purpose local key/value storage: preferences, small caches, flags.
 *
 * Auth tokens deliberately do NOT live here — they stay in expo-secure-store
 * (Keychain/Keystore). See `lib/supabase.ts`.
 *
 * Under Jest, `createMMKV` swaps itself for an in-memory mock (it checks
 * `JEST_WORKER_ID`), so tests need no extra moduleNameMapper.
 */
const mmkv = createMMKV({ id: 'vertiege' });

export const storage = {
  getString: (key: string): string | undefined => mmkv.getString(key),

  setString: (key: string, value: string): void => mmkv.set(key, value),

  getNumber: (key: string): number | undefined => mmkv.getNumber(key),

  setNumber: (key: string, value: number): void => mmkv.set(key, value),

  getBoolean: (key: string): boolean | undefined => mmkv.getBoolean(key),

  setBoolean: (key: string, value: boolean): void => mmkv.set(key, value),

  remove: (key: string): boolean => mmkv.remove(key),

  clear: (): void => mmkv.clearAll(),

  keys: (): string[] => mmkv.getAllKeys(),

  /** Parse a stored JSON value; returns `undefined` for missing/corrupt data. */
  getJSON: <T>(key: string): T | undefined => {
    const raw = mmkv.getString(key);
    if (raw == null) return undefined;
    try {
      return JSON.parse(raw) as T;
    } catch {
      mmkv.remove(key);
      return undefined;
    }
  },

  setJSON: (key: string, value: unknown): void => {
    mmkv.set(key, JSON.stringify(value));
  },
};

export type Storage = typeof storage;
