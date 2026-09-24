import { openDatabaseSync } from 'expo-sqlite';
import { drizzle } from 'drizzle-orm/expo-sqlite';

import * as schema from './schema';
import { runMigrations } from './migrate';

export { schema };

/** Local app database. Native module — requires a dev-client rebuild. */
const sqlite = openDatabaseSync('vertiege.db');

export const db = drizzle(sqlite, { schema });

/** Kick off migrations once during boot; safe to call repeatedly. */
export const ensureDbReady = (): Promise<void> => runMigrations(db);
