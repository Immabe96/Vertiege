import { migrate } from 'drizzle-orm/expo-sqlite/migrator';

import migrations from './migrations.generated';

type ExpoDb = Parameters<typeof migrate>[0];

let pending: Promise<void> | null = null;

/**
 * Apply pending SQL migrations exactly once per process.
 *
 * Memoizes so a failure surfaces once and never re-runs the batch.
 */
export function runMigrations(db: ExpoDb): Promise<void> {
  pending ??= migrate(db, migrations).catch((error: unknown) => {
    pending = null;
    throw error;
  });
  return pending;
}
