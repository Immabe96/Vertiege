import { integer, sqliteTable, text } from 'drizzle-orm/sqlite-core';

/**
 * Offline cache layer (F0). Feature-specific tables arrive with F1+ as their
 * read patterns are known — this file is the single schema source of truth.
 *
 * Migration workflow: edit schema → `npm run db:generate` → commit the
 * generated SQL in `db/migrations/`. Never hand-edit generated files.
 */
export const cacheEntries = sqliteTable('cache_entries', {
  /** Namespaced cache key, e.g. `feed:nexus:<cursor>` or `world:<id>:members`. */
  key: text('key').primaryKey(),
  /** Serialized JSON payload. */
  value: text('value').notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp_ms' }).notNull(),
});

export type CacheEntry = typeof cacheEntries.$inferSelect;
export type NewCacheEntry = typeof cacheEntries.$inferInsert;
